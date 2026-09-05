import assert from 'node:assert/strict';
import { Ok } from './lib/result.ts';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { mcpArgs } from './lib/claude.ts';
import { createRunner, render, type Command, type Spawn } from './lib/exec.ts';
import { installCommands, type Manager } from './lib/managers.ts';
import { PLATFORMS, type Platform } from './lib/platform.ts';
import { Programs, resolve, type Program } from './lib/programs.ts';
import { parseDistros, version2 } from './lib/wsl.ts';

const programs = Object.entries(Programs) as readonly [string, Program][];

test('every program resolves on at least one platform', () => {
   programs.forEach(([key, program]) => {
      const reachable = PLATFORMS.filter((platform) => resolve(program, platform) !== undefined);
      assert.ok(reachable.length > 0, `${key} is unreachable on every platform`);
   });
});

test('every source has at least one non-empty package', () => {
   programs.forEach(([key, program]) => {
      PLATFORMS.forEach((platform) => {
         const source = resolve(program, platform);
         if (source === undefined) return;
         assert.ok(source.packages.length > 0, `${key}/${platform} has no packages`);
         source.packages.forEach((pkg) => assert.notEqual(pkg, '', `${key}/${platform} empty package`));
      });
   });
});

test('cargo programs resolve identically on every platform', () => {
   const cargoPrograms = programs.filter(([, p]) => p.sources.any?.manager === 'cargo');
   assert.ok(cargoPrograms.length > 0);

   cargoPrograms.forEach(([key, program]) => {
      const rendered = PLATFORMS.map((platform) =>
         installCommands(resolve(program, platform)!).map(render).join(' && ')
      );
      assert.equal(new Set(rendered).size, 1, `${key} differs across platforms`);
   });
});

test('winget sources install one id per invocation', () => {
   programs.forEach(([key, program]) => {
      const source = resolve(program, 'windows');
      if (source?.manager !== 'winget') return;

      const commands = installCommands(source);
      assert.equal(commands.length, source.packages.length, `${key} did not split winget ids`);
      commands.forEach((command) => {
         assert.equal(command.args.filter((arg) => arg === '--id').length, 1);
         assert.notEqual(command.sudo, true, 'windows has no sudo');
      });
   });
});

test('only linux package managers elevate', () => {
   const elevating: readonly Manager[] = ['apt', 'dnf', 'pacman'];

   programs.forEach(([key, program]) => {
      PLATFORMS.forEach((platform) => {
         const source = resolve(program, platform);
         if (source === undefined) return;

         installCommands(source).forEach((command) => {
            assert.equal(
               command.sudo === true,
               elevating.includes(source.manager),
               `${key}/${platform} sudo mismatch for ${source.manager}`
            );
         });
      });
   });
});

test('platform-specific managers are never used on the wrong platform', () => {
   const owner: Partial<Record<Manager, Platform>> = { brew: 'darwin', winget: 'windows' };

   programs.forEach(([key, program]) => {
      PLATFORMS.forEach((platform) => {
         const manager = resolve(program, platform)?.manager;
         if (manager === undefined) return;
         const required = owner[manager];
         if (required !== undefined) {
            assert.equal(platform, required, `${key} uses ${manager} on ${platform}`);
         }
      });
   });
});

test('shell tooling is unix only, and windows still gets a terminal', () => {
   assert.equal(resolve(Programs.ZSH, 'windows'), undefined);
   assert.equal(resolve(Programs.BUILD_TOOLS, 'windows'), undefined);
   assert.notEqual(resolve(Programs.WEZTERM, 'windows'), undefined);
   assert.notEqual(resolve(Programs.NERD_FONT, 'windows'), undefined);
   /* zig is the treesitter parser compiler; unix gets one from BUILD_TOOLS. */
   assert.notEqual(resolve(Programs.ZIG, 'windows'), undefined);
   assert.equal(resolve(Programs.ZIG, 'debian'), undefined);
});

test('neovim never comes from a linux package manager', () => {
   (['debian', 'fedora', 'arch'] as const).forEach((platform) => {
      assert.equal(resolve(Programs.NEOVIM, platform), undefined, `${platform} must use the tarball`);
   });
});

test('mcpArgs matches the flag form both old linkers emitted', () => {
   assert.deepEqual(mcpArgs('atlassian', { type: 'http', url: 'https://mcp.example/mcp' }), [
      '--scope', 'user', '--transport', 'http', 'atlassian', 'https://mcp.example/mcp',
   ]);

   assert.deepEqual(
      mcpArgs('withHeaders', { type: 'http', url: 'https://x', headers: { Authorization: 'Bearer t' } }),
      ['--scope', 'user', '--transport', 'http', '--header', 'Authorization: Bearer t', 'withHeaders', 'https://x']
   );

   assert.deepEqual(mcpArgs('local', { command: 'node', args: ['server.js'], env: { KEY: 'v' } }), [
      '--scope', 'user', '--transport', 'stdio', '-e', 'KEY=v', 'local', '--', 'node', 'server.js',
   ]);
});

test('render round-trips sudo into the printed command', () => {
   assert.equal(render({ bin: 'apt-get', args: ['install', '-y', 'zsh'], sudo: true }), 'sudo apt-get install -y zsh');
   assert.equal(render({ bin: 'brew', args: ['install', 'zsh'] }), 'brew install zsh');
});

test('wsl --list --verbose parses, including the UTF-16LE null bytes', () => {
   const utf8 = [
      '  NAME      STATE           VERSION',
      '* Ubuntu    Running         2',
      '  Debian    Stopped         1',
      '',
   ].join('\n');

   assert.deepEqual(parseDistros(utf8), [
      { default: true, name: 'Ubuntu', state: 'Running', version: 2 },
      { default: false, name: 'Debian', state: 'Stopped', version: 1 },
   ]);

   /* Byte-for-byte what WSL emits without WSL_UTF8=1. */
   const utf16 = utf8.split('').join('\u0000');
   assert.deepEqual(parseDistros(utf16), parseDistros(utf8));

   assert.deepEqual(version2(parseDistros(utf8)).map((distro) => distro.name), ['Ubuntu']);
});

test('no WSL2 distro is an empty list, not a crash', () => {
   assert.deepEqual(parseDistros(''), []);
   assert.deepEqual(parseDistros('Windows Subsystem for Linux has no installed distributions.'), []);
   assert.deepEqual(version2(parseDistros('  NAME  STATE  VERSION\n  Ubuntu  Stopped  1')), []);
});

/* install.ps1 carries these two ids inline so the Windows host bootstrap needs no
   Node runtime. This keeps that copy honest. */
test('install.ps1 winget ids match the registry', () => {
   const script = readFileSync(new URL('../install.ps1', import.meta.url), 'utf8');

   const hostPrograms = [Programs.WEZTERM, Programs.NERD_FONT];

   hostPrograms.forEach((program) => {
      const source = resolve(program, 'windows');
      assert.equal(source?.manager, 'winget', `${program.name} should come from winget`);

      source?.packages.forEach((id) => {
         assert.ok(script.includes(id), `install.ps1 is missing winget id ${id}`);
      });
   });

   /* And nothing beyond the host pair sneaked in. */
   const idsInScript = [...script.matchAll(/Id\s*=\s*'([^']+)'/g)].map((match) => match[1]);
   const expected = hostPrograms.flatMap((program) => [...(resolve(program, 'windows')?.packages ?? [])]);
   assert.deepEqual(idsInScript.sort(), expected.sort());
});

/* The bug this pins: `probe` runs for real under --dry-run so the printed plan is
   accurate, and a mutating `claude mcp remove` was being sent through it. A dry
   run really deleted the MCP servers and only pretended to re-add them. */
test('--dry-run executes nothing that mutates', () => {
   const executed: Command[] = [];
   const fake: Spawn = (command) => {
      executed.push(command);
      return Ok('');
   };

   const runner = createRunner(true, fake);

   runner.run({ bin: 'winget', args: ['install', '--id', 'x'] });
   runner.tryRun({ bin: 'claude', args: ['mcp', 'remove', 'atlassian', '--scope', 'user'] });

   assert.equal(executed.length, 0, 'dry run must not execute run or tryRun');

   /* Read-only probes are the deliberate exception. */
   runner.probe({ bin: 'nvim', args: ['--version'] });
   assert.equal(executed.length, 1);
   assert.equal(executed[0]?.bin, 'nvim');
});

test('a real run executes all three', () => {
   const executed: Command[] = [];
   const fake: Spawn = (command) => {
      executed.push(command);
      return Ok('');
   };

   const runner = createRunner(false, fake);

   runner.run({ bin: 'brew', args: ['install', 'zsh'] });
   runner.tryRun({ bin: 'claude', args: ['mcp', 'remove', 'x'] });
   runner.probe({ bin: 'nvim', args: ['--version'] });

   assert.deepEqual(executed.map((command) => command.bin), ['brew', 'claude', 'nvim']);
});

test('winget accepts its already-installed exit code', () => {
   const source = resolve(Programs.WEZTERM, 'windows');
   installCommands(source!).forEach((command) => {
      assert.ok(
         command.okExitCodes?.includes(-1978335189),
         'winget commands must treat 0x8A15002B as success'
      );
   });
});

/* WezTerm on macOS is a cask; its CLI lives inside WezTerm.app, so a PATH-only
   check reports it missing and brew then fails trying to reinstall over it. */
test('GUI apps are not detected by PATH alone', () => {
   assert.equal(Programs.WEZTERM.detect.kind, 'app');
   assert.ok(
      Programs.WEZTERM.detect.kind === 'app' &&
         Programs.WEZTERM.detect.paths.some((path) => path.endsWith('WezTerm.app'))
   );
});
