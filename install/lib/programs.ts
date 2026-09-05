import { existsSync, readdirSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import type { Runner } from './exec.ts';
import type { Source } from './managers.ts';
import { installed, type Platform } from './platform.ts';

/* Detection stays data rather than a callback so the registry is pure and the
   whole table can be asserted in tests. */
export type Detect =
   | { readonly kind: 'bin'; readonly name: string }
   | { readonly kind: 'font'; readonly match: string }
   /* GUI apps ship their CLI inside the bundle, so PATH alone misses them. */
   | { readonly kind: 'app'; readonly bin: string; readonly paths: readonly string[] };

export type Program = {
   readonly name: string;
   readonly detect: Detect;
   /* `any` is the fallback when no platform key matches. A program with no
      matching source is simply not applicable to that platform. */
   readonly sources: Partial<Record<Platform | 'any', Source>>;
};

const unix = (pkg: string, darwinPkg = pkg): Partial<Record<Platform, Source>> => ({
   darwin: { manager: 'brew', packages: [darwinPkg] },
   debian: { manager: 'apt', packages: [pkg] },
   fedora: { manager: 'dnf', packages: [pkg] },
   arch: { manager: 'pacman', packages: [pkg] },
});

/* Rust tools build from cargo on every platform, Windows included. Distro
   repos ship wildly different versions and this keeps them identical. */
const fromCargo = (crate: string): Partial<Record<'any', Source>> => ({
   any: { manager: 'cargo', packages: [crate] },
});

export const Programs = {
   ZSH: { name: 'zsh', detect: { kind: 'bin', name: 'zsh' }, sources: unix('zsh') },

   GIT: {
      name: 'git',
      detect: { kind: 'bin', name: 'git' },
      sources: { ...unix('git'), windows: { manager: 'winget', packages: ['Git.Git'] } },
   },

   CURL: { name: 'curl', detect: { kind: 'bin', name: 'curl' }, sources: unix('curl') },

   UNZIP: { name: 'unzip', detect: { kind: 'bin', name: 'unzip' }, sources: unix('unzip') },

   /* macOS gets its toolchain from xcode-select, which is a step, not a package. */
   BUILD_TOOLS: {
      name: 'C toolchain',
      detect: { kind: 'bin', name: 'cc' },
      sources: {
         debian: { manager: 'apt', packages: ['build-essential'] },
         fedora: { manager: 'dnf', packages: ['gcc', 'gcc-c++', 'make'] },
         arch: { manager: 'pacman', packages: ['base-devel'] },
      },
   },

   FZF: {
      name: 'fzf',
      detect: { kind: 'bin', name: 'fzf' },
      sources: { ...unix('fzf'), windows: { manager: 'winget', packages: ['junegunn.fzf'] } },
   },

   RUSTUP: {
      name: 'rustup',
      detect: { kind: 'bin', name: 'cargo' },
      sources: { windows: { manager: 'winget', packages: ['Rustlang.Rustup'] } },
   },

   EZA: { name: 'eza', detect: { kind: 'bin', name: 'eza' }, sources: fromCargo('eza') },
   FD: { name: 'fd', detect: { kind: 'bin', name: 'fd' }, sources: fromCargo('fd-find') },
   RIPGREP: { name: 'ripgrep', detect: { kind: 'bin', name: 'rg' }, sources: fromCargo('ripgrep') },
   STARSHIP: { name: 'starship', detect: { kind: 'bin', name: 'starship' }, sources: fromCargo('starship') },
   ZOXIDE: { name: 'zoxide', detect: { kind: 'bin', name: 'zoxide' }, sources: fromCargo('zoxide') },

   /* No linux package source on purpose: apt ships 0.6-0.9 and dnf lagged until
      Fedora 41, so linux goes through the official tarball in steps.ts. */
   NEOVIM: {
      name: 'neovim',
      detect: { kind: 'bin', name: 'nvim' },
      sources: {
         darwin: { manager: 'brew', packages: ['neovim'] },
         windows: { manager: 'winget', packages: ['Neovim.Neovim'] },
      },
   },

   CLANGD: {
      name: 'clangd',
      detect: { kind: 'bin', name: 'clangd' },
      sources: {
         darwin: { manager: 'brew', packages: ['llvm'] },
         debian: { manager: 'apt', packages: ['clangd'] },
         fedora: { manager: 'dnf', packages: ['clang-tools-extra'] },
         arch: { manager: 'pacman', packages: ['clang'] },
         windows: { manager: 'winget', packages: ['LLVM.LLVM'] },
      },
   },

   CMAKE: {
      name: 'cmake',
      detect: { kind: 'bin', name: 'cmake' },
      sources: { ...unix('cmake'), windows: { manager: 'winget', packages: ['Kitware.CMake'] } },
   },

   /* Only Windows needs this: it's the C compiler nvim-treesitter shells out to
      when compiling parsers, and unix already has one from BUILD_TOOLS. */
   ZIG: {
      name: 'zig',
      detect: { kind: 'bin', name: 'zig' },
      sources: { windows: { manager: 'winget', packages: ['zig.zig'] } },
   },

   NUSHELL: {
      name: 'nushell',
      detect: { kind: 'bin', name: 'nu' },
      sources: { windows: { manager: 'winget', packages: ['Nushell.Nushell'] } },
   },

   WEZTERM: {
      name: 'wezterm',
      detect: {
         kind: 'app',
         bin: 'wezterm',
         paths: [
            '/Applications/WezTerm.app',
            '~/Applications/WezTerm.app',
            '~/AppData/Local/Programs/WezTerm/wezterm-gui.exe',
         ],
      },
      sources: {
         darwin: { manager: 'brew', packages: ['wezterm'], args: ['--cask'] },
         windows: { manager: 'winget', packages: ['wez.wezterm'] },
      },
   },

   NERD_FONT: {
      name: 'JetBrainsMono Nerd Font',
      detect: { kind: 'font', match: 'jetbrainsmono' },
      sources: {
         darwin: { manager: 'brew', packages: ['font-jetbrains-mono-nerd-font'], args: ['--cask'] },
         windows: { manager: 'winget', packages: ['DEVCOM.JetBrainsMonoNerdFont'] },
      },
   },
} as const satisfies Record<string, Program>;

export const resolve = (program: Program, platform: Platform): Source | undefined =>
   program.sources[platform] ?? program.sources.any;

const FONT_DIRS: Partial<Record<Platform, readonly string[]>> = {
   darwin: [join(homedir(), 'Library/Fonts'), '/Library/Fonts'],
   windows: [
      join(process.env.LOCALAPPDATA ?? '', 'Microsoft/Windows/Fonts'),
      join(process.env.WINDIR ?? 'C:/Windows', 'Fonts'),
   ],
};

const fontInstalled = (match: string, platform: Platform, runner: Runner): boolean => {
   const dirs = FONT_DIRS[platform];

   if (dirs === undefined) {
      const listed = runner.probe({ bin: 'fc-list', args: [] });
      return listed.tag === 'ok' && listed.value.toLowerCase().includes(match);
   }

   return dirs
      .filter((dir) => dir !== '' && existsSync(dir))
      .flatMap((dir) => readdirSync(dir))
      .some((file) => file.toLowerCase().includes(match));
};

const expand = (path: string): string =>
   path.startsWith('~/') ? join(homedir(), path.slice(2)) : path;

export const isInstalled = (program: Program, platform: Platform, runner: Runner): boolean => {
   const { detect } = program;

   if (detect.kind === 'bin') return installed(detect.name);
   if (detect.kind === 'font') return fontInstalled(detect.match, platform, runner);

   return installed(detect.bin) || detect.paths.map(expand).some((path) => existsSync(path));
};
