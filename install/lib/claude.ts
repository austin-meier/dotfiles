import { existsSync, lstatSync, mkdirSync, readFileSync, readlinkSync, renameSync, rmSync, symlinkSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import type { Runner } from './exec.ts';
import { installed, type Platform } from './platform.ts';
import { Err, Ok, type Result, tryCatch } from './result.ts';
import * as ui from './ui.ts';

/* Authored config only. Everything else under ~/.claude is machine state
   (history, sessions, credentials) and is deliberately left alone. */
const LINKS = ['settings.json', 'CLAUDE.md', 'skills', 'commands', 'agents', 'output-styles', 'libs'] as const;

export type McpServer = {
   readonly type?: 'http' | 'sse' | 'stdio';
   readonly url?: string;
   readonly command?: string;
   readonly args?: readonly string[];
   readonly env?: Readonly<Record<string, string>>;
   readonly headers?: Readonly<Record<string, string>>;
};

/* Flag form rather than add-json: it survives every shell's quoting rules
   identically, which is why both old linkers used it. */
export const mcpArgs = (name: string, server: McpServer): readonly string[] => {
   const transport = server.type ?? 'stdio';
   const base = ['--scope', 'user', '--transport', transport];

   if (transport === 'http' || transport === 'sse') {
      const headers = Object.entries(server.headers ?? {}).flatMap(([key, value]) => [
         '--header',
         `${key}: ${value}`,
      ]);
      return [...base, ...headers, name, server.url ?? ''];
   }

   const env = Object.entries(server.env ?? {}).flatMap(([key, value]) => ['-e', `${key}=${value}`]);
   return [...base, ...env, name, '--', server.command ?? '', ...(server.args ?? [])];
};

const stamp = (): string => new Date().toISOString().replace(/[-:T]/g, '').slice(0, 15);

/* Windows directory junctions need no elevation; file symlinks still require
   Developer Mode or an admin shell. */
const linkType = (source: string, platform: Platform): 'junction' | 'file' | 'dir' => {
   const directory = lstatSync(source).isDirectory();
   if (platform === 'windows') return directory ? 'junction' : 'file';
   return directory ? 'dir' : 'file';
};

const linkOne = (
   name: string,
   repo: string,
   home: string,
   platform: Platform,
   runner: Runner
): Result<void, string> => {
   const source = join(repo, name);
   const target = join(home, name);

   if (!existsSync(source)) {
      ui.skip(`${name} (no source in repo)`);
      return Ok(undefined);
   }

   const existing = tryCatch(() => lstatSync(target));

   if (existing.tag === 'ok' && existing.value.isSymbolicLink()) {
      if (readlinkSync(target).replace(/[\\/]+$/, '') === source) {
         ui.success(`${name} already linked`);
         return Ok(undefined);
      }
      ui.info(`replacing stale link ${name}`);
      if (!runner.dryRun) rmSync(target, { force: true });
   } else if (existing.tag === 'ok') {
      const backup = `${target}.backup-${stamp()}`;
      ui.warn(`${name} exists as a real ${existing.value.isDirectory() ? 'dir' : 'file'}, moving to ${backup}`);
      if (!runner.dryRun) renameSync(target, backup);
   }

   if (runner.dryRun) {
      ui.plan(`link ${target} -> ${source}`);
      return Ok(undefined);
   }

   const created = tryCatch(() => symlinkSync(source, target, linkType(source, platform)));

   if (created.tag === 'err') {
      return Err(
         platform === 'windows'
            ? `could not link ${name}: ${created.value}. Enable Developer Mode (Settings > System > For developers) or run from an elevated shell.`
            : `could not link ${name}: ${created.value}`
      );
   }

   ui.success(`linked ${name}`);
   return Ok(undefined);
};

const registerMcp = (repo: string, runner: Runner): readonly string[] => {
   const failed: string[] = [];

   ui.header('MCP servers (user scope)');

   if (!installed('claude')) {
      ui.skip('claude CLI not on PATH, skipping MCP registration');
      return failed;
   }

   const manifest = join(repo, 'mcp-servers.json');
   if (!existsSync(manifest)) {
      ui.skip('no mcp-servers.json, skipping MCP registration');
      return failed;
   }

   const parsed = tryCatch(
      () => JSON.parse(readFileSync(manifest, 'utf8')) as { mcpServers?: Record<string, McpServer> }
   );

   if (parsed.tag === 'err') {
      ui.warn(`could not parse mcp-servers.json: ${parsed.value}`);
      return failed;
   }

   Object.entries(parsed.value.mcpServers ?? {}).forEach(([name, server]) => {
      /* Re-registering drops the server's OAuth token, so only touch it when the
         registration is actually missing or pointing somewhere else. */
      const target = server.url ?? server.command ?? '';
      const existing = runner.probe({ bin: 'claude', args: ['mcp', 'get', name] });

      if (existing.tag === 'ok' && target !== '' && existing.value.includes(target)) {
         ui.success(`${name} already registered`);
         return;
      }

      /* Remove first so the manifest stays the source of truth. tryRun, not
         probe: this mutates, and it must not fire under --dry-run. */
      runner.tryRun({ bin: 'claude', args: ['mcp', 'remove', name, '--scope', 'user'] });

      const added = runner.run({ bin: 'claude', args: ['mcp', 'add', ...mcpArgs(name, server)] });

      if (added.tag === 'ok') {
         ui.success(`registered ${name}`);
      } else {
         /* The remove already happened, so the server is now unregistered. Say
            so loudly: re-running fixes it, ignoring it silently does not. */
         ui.fail(`could not register ${name}, it is now UNREGISTERED. Re-run to restore it.`);
         failed.push(name);
      }
   });

   return failed;
};

export const link = (repo: string, platform: Platform, runner: Runner): Result<void, string> => {
   ui.header('Claude config');

   const claudeRepo = join(repo, 'claude');
   const home = join(homedir(), '.claude');

   if (!existsSync(home)) {
      ui.info(`creating ${home}`);
      if (!runner.dryRun) mkdirSync(home, { recursive: true });
   }

   ui.info(`linking ${claudeRepo} -> ${home}`);

   const failures = LINKS.map((name) => linkOne(name, claudeRepo, home, platform, runner)).filter(
      (result) => result.tag === 'err'
   );

   const mcpFailures = registerMcp(claudeRepo, runner);

   if (failures.length > 0 || mcpFailures.length > 0) {
      return Err(
         [
            ...failures.map((failure) => failure.value),
            ...mcpFailures.map((name) => `MCP server ${name} is unregistered`),
         ].join('; ')
      );
   }

   ui.success('Claude config linked. Authenticate HTTP/OAuth MCP servers in Claude with /mcp');
   return Ok(undefined);
};
