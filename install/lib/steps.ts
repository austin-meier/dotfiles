import { existsSync, mkdirSync, appendFileSync, copyFileSync, readFileSync, rmSync } from 'node:fs';
import { homedir, arch } from 'node:os';
import { join } from 'node:path';
import type { Runner } from './exec.ts';
import { addToPath, installed, isWsl, onWindowsDrive, type Platform, which } from './platform.ts';
import { Err, Ok, type Result } from './result.ts';
import * as ui from './ui.ts';
import { detect as detectDistros, version2 } from './wsl.ts';

export type Context = {
   readonly platform: Platform;
   readonly runner: Runner;
   readonly repo: string;
};

export type Step = {
   readonly name: string;
   /* undefined means every platform. */
   readonly platforms?: readonly Platform[];
   readonly run: (context: Context) => Result<void, string>;
};

const UNIX = ['darwin', 'debian', 'fedora', 'arch'] as const satisfies readonly Platform[];
const LINUX = ['debian', 'fedora', 'arch'] as const satisfies readonly Platform[];

const xcodeTools: Step = {
   name: 'Xcode Command Line Tools',
   platforms: ['darwin'],
   run: ({ runner }) => {
      if (runner.probe({ bin: 'xcode-select', args: ['-p'] }).tag === 'ok') {
         ui.success('Command Line Tools present');
         return Ok(undefined);
      }
      ui.info('installing Command Line Tools (a GUI prompt will open)');
      return runner.run({ bin: 'xcode-select', args: ['--install'] });
   },
};

/* Windows gets rustup from winget (see Programs.RUSTUP); unix uses the official
   installer script, which is the only supported route there. */
const rustup: Step = {
   name: 'Rust toolchain',
   platforms: UNIX,
   run: ({ runner }) => {
      addToPath(join(homedir(), '.cargo/bin'));

      if (installed('cargo')) {
         ui.success('cargo already installed');
         return Ok(undefined);
      }

      ui.info('installing rustup');
      const result = runner.run({
         bin: 'sh',
         args: ['-c', 'curl --proto =https --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'],
      });

      addToPath(join(homedir(), '.cargo/bin'));
      return result;
   },
};

const PLUGINS = ['zsh-users/zsh-autosuggestions', 'zsh-users/zsh-syntax-highlighting'] as const;

/* Cloned rather than packaged on every distro: apt/dnf builds are stale and Arch
   installs to a path .zshrc doesn't search. */
const zshPlugins: Step = {
   name: 'Zsh plugins',
   platforms: UNIX,
   run: ({ platform, runner }) => {
      if (platform === 'darwin') {
         const formulae = ['zsh-autosuggestions', 'zsh-syntax-highlighting'];
         const present = runner.probe({ bin: 'brew', args: ['list', '--formula'] });
         const missing = formulae.filter(
            (formula) => !(present.tag === 'ok' && present.value.split(/\s+/).includes(formula))
         );

         if (missing.length === 0) {
            ui.success('zsh plugins already installed');
            return Ok(undefined);
         }
         return runner.run({ bin: 'brew', args: ['install', ...missing] });
      }

      const root = join(process.env.XDG_DATA_HOME ?? join(homedir(), '.local/share'), 'zsh/plugins');
      if (!runner.dryRun) mkdirSync(root, { recursive: true });

      const results = PLUGINS.map((repo) => {
         const name = repo.split('/').pop() ?? repo;
         const target = join(root, name);

         return existsSync(target)
            ? runner.run({ bin: 'git', args: ['-C', target, 'pull', '--ff-only', '-q'] })
            : runner.run({
                 bin: 'git',
                 args: ['clone', '--depth=1', `https://github.com/${repo}`, target],
              });
      });

      const failed = results.filter((result) => result.tag === 'err');
      return failed.length > 0 ? Err(failed.map((f) => f.value).join('; ')) : Ok(undefined);
   },
};

const ARCH_ASSETS: Readonly<Record<string, string>> = { x64: 'x86_64', arm64: 'arm64' };

const neovimLinux: Step = {
   name: 'Neovim (tarball)',
   platforms: LINUX,
   run: ({ runner }) => {
      const version = runner.probe({ bin: 'nvim', args: ['--version'] });
      const parsed = version.tag === 'ok' ? /v(\d+)\.(\d+)/.exec(version.value) : undefined;
      const major = Number(parsed?.[1] ?? -1);
      const minor = Number(parsed?.[2] ?? -1);

      if (major > 0 || minor >= 10) {
         ui.success(`neovim ${major}.${minor} already installed`);
         return Ok(undefined);
      }

      const asset = ARCH_ASSETS[arch()];
      if (asset === undefined) {
         return Err(`no Neovim tarball for ${arch()}, install manually from neovim.io`);
      }

      const tarball = `nvim-linux-${asset}.tar.gz`;
      const url = `https://github.com/neovim/neovim/releases/latest/download/${tarball}`;
      const temp = join('/tmp', tarball);

      const steps = [
         { bin: 'curl', args: ['-fL', url, '-o', temp] },
         { bin: 'rm', args: ['-rf', `/opt/nvim-linux-${asset}`], sudo: true },
         { bin: 'tar', args: ['-C', '/opt', '-xzf', temp], sudo: true },
         {
            bin: 'ln',
            args: ['-sf', `/opt/nvim-linux-${asset}/bin/nvim`, '/usr/local/bin/nvim'],
            sudo: true,
         },
      ];

      const failed = steps.map((step) => runner.run(step)).filter((result) => result.tag === 'err');
      return failed.length > 0 ? Err(failed.map((f) => f.value).join('; ')) : Ok(undefined);
   },
};

const zdotdir: Step = {
   name: 'Shell bootstrap',
   platforms: UNIX,
   run: ({ runner }) => {
      const zshenv = join(homedir(), '.zshenv');
      const current = existsSync(zshenv) ? readFileSync(zshenv, 'utf8') : '';

      if (current.includes('ZDOTDIR')) {
         ui.success(`ZDOTDIR already set in ${zshenv}`);
         return Ok(undefined);
      }

      const lines = [
         'export ZDOTDIR="$HOME/.config/zsh"',
         '[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"',
         '',
      ].join('\n');

      if (runner.dryRun) {
         ui.plan(`append ZDOTDIR to ${zshenv}`);
         return Ok(undefined);
      }

      appendFileSync(zshenv, `\n${lines}`);
      ui.success('ZDOTDIR set');
      return Ok(undefined);
   },
};

const defaultShell: Step = {
   name: 'Default shell',
   platforms: UNIX,
   run: ({ runner }) => {
      if ((process.env.SHELL ?? '').endsWith('/zsh')) {
         ui.success('default shell is already zsh');
         return Ok(undefined);
      }

      const zsh = runner.probe({ bin: 'sh', args: ['-c', 'command -v zsh'] });
      if (zsh.tag === 'err') {
         ui.warn('zsh not on PATH, cannot set default shell');
         return Ok(undefined);
      }

      /* chsh refuses any shell missing from /etc/shells. */
      const shells = existsSync('/etc/shells') ? readFileSync('/etc/shells', 'utf8') : '';
      if (!shells.split('\n').includes(zsh.value)) {
         runner.run({ bin: 'sh', args: ['-c', `echo ${zsh.value} | sudo tee -a /etc/shells`] });
      }

      const changed = runner.run({ bin: 'chsh', args: ['-s', zsh.value] });
      if (changed.tag === 'err') {
         ui.warn(`could not change shell automatically. Run: chsh -s ${zsh.value}`);
         return Ok(undefined);
      }

      ui.success('default shell set to zsh, restart your session to apply');
      return Ok(undefined);
   },
};

/* git reads ~/.gitconfig after ~/.config/git/config, so a stray one silently
   overrides every tracked setting. Back it up once, then keep it deleted. */
const gitConfig: Step = {
   name: 'Git config',
   run: ({ runner }) => {
      const tracked = join(homedir(), '.config/git/config');
      if (!existsSync(tracked)) {
         ui.warn(`git/config missing at ${tracked}, skipping`);
         return Ok(undefined);
      }

      const legacy = join(homedir(), '.gitconfig');
      if (!existsSync(legacy)) {
         ui.success('no ~/.gitconfig present, git/config already wins');
         return Ok(undefined);
      }

      if (runner.dryRun) {
         ui.plan(`back up and remove ${legacy}`);
         return Ok(undefined);
      }

      const backup = `${legacy}.pre-dotfiles.bak`;
      if (!existsSync(backup)) {
         copyFileSync(legacy, backup);
         ui.info(`backed up ~/.gitconfig -> ${backup}`);
      }
      rmSync(legacy, { force: true });
      ui.success('removed ~/.gitconfig so git/config takes precedence');
      return Ok(undefined);
   },
};

/* A 20-40 minute native-comp source build stays opt-in. */
const emacs: Step = {
   name: 'Emacs',
   platforms: UNIX,
   run: ({ repo }) => {
      if (installed('emacs')) {
         ui.success('emacs already installed');
         return Ok(undefined);
      }
      ui.warn("emacs not found, the config at ~/.config/emacs won't run until it's installed");
      ui.info(`build the tuned native-comp Emacs with: bash ${join(repo, 'emacs/build-emacs.sh')}`);
      return Ok(undefined);
   },
};

/* brew and winget install the font directly (see Programs.NERD_FONT); linux has
   no equivalent package, so the best we can do is say what's missing. */
const fonts: Step = {
   name: 'Fonts',
   platforms: LINUX,
   run: ({ runner }) => {
      const listed = runner.probe({ bin: 'fc-list', args: [] });
      if (listed.tag === 'ok' && listed.value.toLowerCase().includes('jetbrainsmono')) {
         ui.success('JetBrainsMono Nerd Font installed');
         return Ok(undefined);
      }
      ui.warn('No Nerd Font found. Icons in eza, starship, and the WezTerm tab bar need one.');
      ui.info('Download JetBrainsMono Nerd Font from https://www.nerdfonts.com/font-downloads');
      ui.info('Unpack into ~/.local/share/fonts, then run: fc-cache -fv');
      return Ok(undefined);
   },
};

/* Windows only hosts WezTerm and its font; the dotfiles install inside WSL2.
   Fail loudly with the exact command rather than half-installing. */
const wsl2Required: Step = {
   name: 'WSL2',
   platforms: ['windows'],
   run: ({ runner }) => {
      const distros = version2(detectDistros(runner));

      if (distros.length > 0) {
         ui.success(`WSL2 distro(s): ${distros.map((distro) => distro.name).join(', ')}`);
         return Ok(undefined);
      }

      ui.warn('no WSL2 distro found');
      ui.info('install one, reboot if prompted, then re-run:');
      ui.info('    wsl --install -d Ubuntu');
      ui.info('already on WSL1?  wsl --set-version <distro> 2');
      ui.info('no WSL at all?    pwsh install.ps1 -Native  (degraded: no zsh, starship, or emacs)');

      return Err('WSL2 is required. See WINDOWS-MIGRATION.md');
   },
};

const WSL_BROWSERS = ['wslview', 'xdg-open'] as const;

/* Advisory only. These are the WSL2 misconfigurations that break Claude Code in
   ways that look like Claude Code being flaky rather than the environment. */
const wslHealth: Step = {
   name: 'WSL2 health',
   platforms: LINUX,
   run: () => {
      if (!isWsl()) {
         ui.skip('not running under WSL');
         return Ok(undefined);
      }

      ui.success(`running under WSL2 (${process.env.WSL_DISTRO_NAME ?? 'unknown distro'})`);

      /* The code-style hook resolves its path via os.homedir(). Windows node
         returns C:\Users\..., so the require fails on every Write/Edit. */
      const interop = (['node', 'claude', 'npm'] as const)
         .map((bin) => ({ bin, path: which(bin) }))
         .filter(({ path }) => path !== undefined && onWindowsDrive(path));

      interop.forEach(({ bin, path }) => {
         ui.warn(`${bin} resolves to ${path}, which is the Windows build`);
      });

      if (interop.length > 0) {
         ui.info('Install these inside WSL. Windows node breaks the Claude code-style hook.');
      }

      const config = join(homedir(), '.config');
      if (onWindowsDrive(config)) {
         ui.warn(`${config} is on the Windows drive. Move it to the WSL filesystem.`);
      }

      const coding = join(homedir(), 'coding');
      if (existsSync(coding) && onWindowsDrive(coding)) {
         ui.warn(`${coding} is on the Windows drive, expect 9p slowness and broken file watching`);
      }

      if (!WSL_BROWSERS.some((bin) => installed(bin))) {
         ui.warn('no wslview or xdg-open, the Claude /login browser flow will not open');
         ui.info('install wslu, or set BROWSER to a Windows browser path');
      }

      return Ok(undefined);
   },
};

const secrets: Step = {
   name: 'Secrets',
   run: () => {
      if (existsSync(join(homedir(), '.config/zsh/secrets.zsh'))) {
         ui.warn('~/.config/zsh/secrets.zsh exists, it is gitignored. Keep it that way.');
      } else {
         ui.success('no secrets.zsh on this machine');
      }
      return Ok(undefined);
   },
};

export const STEPS = [
   wsl2Required,
   xcodeTools,
   rustup,
   zshPlugins,
   neovimLinux,
   zdotdir,
   defaultShell,
   gitConfig,
   emacs,
   fonts,
   wslHealth,
   secrets,
] as const satisfies readonly Step[];

export const appliesTo = (step: Step, platform: Platform): boolean =>
   step.platforms === undefined || step.platforms.includes(platform);
