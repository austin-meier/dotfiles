#!/usr/bin/env node
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { link } from './lib/claude.ts';
import { createRunner, type Runner } from './lib/exec.ts';
import { installCommands } from './lib/managers.ts';
import { detect, isPlatform, isWsl, PLATFORMS, type Platform } from './lib/platform.ts';
import { isInstalled, Programs, type Program, resolve } from './lib/programs.ts';
import { Err, Ok, type Result } from './lib/result.ts';
import { appliesTo, type Context, STEPS } from './lib/steps.ts';
import * as ui from './lib/ui.ts';

const REPO = join(dirname(fileURLToPath(import.meta.url)), '..');

const ORDER = [
   Programs.GIT,
   Programs.CURL,
   Programs.UNZIP,
   Programs.ZSH,
   Programs.BUILD_TOOLS,
   Programs.ZIG,
   Programs.RUSTUP,
   Programs.FZF,
   Programs.EZA,
   Programs.FD,
   Programs.RIPGREP,
   Programs.STARSHIP,
   Programs.ZOXIDE,
   Programs.NEOVIM,
   Programs.CLANGD,
   Programs.CMAKE,
   Programs.NUSHELL,
   Programs.WEZTERM,
   Programs.NERD_FONT,
] as const satisfies readonly Program[];

/* Windows is a WezTerm + font host; the dotfiles themselves are unix and live in
   WSL2. --native installs the degraded windows-side stack instead, for a box
   where WSL2 isn't an option. */
const WINDOWS_HOST: readonly string[] = [Programs.WEZTERM.name, Programs.NERD_FONT.name];

export const programsFor = (platform: Platform, native: boolean): readonly Program[] =>
   platform === 'windows' && !native
      ? ORDER.filter((program) => WINDOWS_HOST.includes(program.name))
      : ORDER;

const install = (program: Program, platform: Platform, runner: Runner): Result<void, string> => {
   const source = resolve(program, platform);

   if (source === undefined) {
      ui.skip(`${program.name} (not applicable on ${platform})`);
      return Ok(undefined);
   }

   if (isInstalled(program, platform, runner)) {
      ui.success(`${program.name} already installed`);
      return Ok(undefined);
   }

   ui.info(`installing ${program.name} via ${source.manager}`);

   const failed = installCommands(source)
      .map((command) => runner.run(command))
      .filter((result) => result.tag === 'err');

   return failed.length > 0 ? Err(`${program.name}: ${failed.map((f) => f.value).join('; ')}`) : Ok(undefined);
};

type Options = {
   readonly dryRun: boolean;
   readonly native: boolean;
   readonly platform: Platform | undefined;
};

const parseArgs = (argv: readonly string[]): Result<Options, string> => {
   const override = argv.find((arg) => arg.startsWith('--platform='))?.split('=')[1];

   if (override !== undefined && !isPlatform(override)) {
      return Err(`unknown platform ${override}. One of: ${PLATFORMS.join(', ')}`);
   }

   return Ok({
      dryRun: argv.includes('--dry-run'),
      native: argv.includes('--native'),
      platform: override,
   });
};

const main = (): number => {
   const options = parseArgs(process.argv.slice(2));
   if (options.tag === 'err') {
      ui.fail(options.value);
      return 1;
   }

   const detected = options.value.platform !== undefined ? Ok(options.value.platform) : detect();
   if (detected.tag === 'err') {
      ui.fail(detected.value);
      return 1;
   }

   const platform = detected.value;
   const { dryRun, native } = options.value;
   const runner = createRunner(dryRun);
   const context: Context = { platform, runner, repo: REPO };

   /* On Windows the dotfiles proper are installed inside WSL2, so the host run
      stops after the terminal and its font. */
   const windowsHost = platform === 'windows' && !native;
   const label = isWsl() ? `${platform} (WSL2)` : platform;

   console.log(
      `\ndotfiles install  ${REPO}  [${label}]${dryRun ? '  (dry run)' : ''}${
         windowsHost ? '  windows host only' : ''
      }`
   );

   ui.header('Packages');
   const programFailures = programsFor(platform, native).map((program) =>
      install(program, platform, runner)
   );

   const stepFailures = STEPS.filter((step) => appliesTo(step, platform)).map((step) => {
      ui.header(step.name);
      return step.run(context);
   });

   const linkResult = windowsHost ? Ok(undefined) : link(REPO, platform, runner);

   const failures = [...programFailures, ...stepFailures, linkResult].filter(
      (result) => result.tag === 'err'
   );

   if (failures.length > 0) {
      ui.header('Finished with errors');
      failures.forEach((failure) => ui.fail(failure.value));
      return 1;
   }

   ui.header('Done.');

   if (windowsHost) {
      ui.info('Host side is ready. The dotfiles themselves install inside WSL2:');
      ui.info('  wsl -- bash ~/.config/install.sh');
      ui.info('See WINDOWS-MIGRATION.md for the full move.');
   } else {
      ui.info('Open a new shell, or: exec zsh');
   }
   return 0;
};

process.exit(main());
