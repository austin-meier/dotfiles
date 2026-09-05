# Install and bootstrap

[← Back to the index](../CLAUDE.md)

One installer, five platforms: macOS, Debian/Ubuntu, Fedora, Arch, and Windows. Clone the repo to
`~/.config`, run it, open a new shell, and the whole environment should be standing.

```sh
git clone git@github.com:austin-meier/dotfiles.git ~/.config
cd ~/.config
bash install.sh        # macOS / Linux
pwsh install.ps1       # Windows
exec zsh
```

Re-running it is safe. Every step checks before it acts, so a second run is basically a repair
pass.

**Node >= 22.18 is the only prerequisite**, and only on unix. The logic lives in
`install/install.ts` and runs on Node's TypeScript type stripping, so there's no build step and no
dependencies to install first. `install.sh` is a short shim that checks for Node and hands off.

`install.ps1` is the exception: it needs nothing but winget. The Windows host side is two packages
and a WSL2 check, and requiring a Windows Node runtime to do that would contradict the whole
point (see [the migration runbook](../WINDOWS-MIGRATION.md)). Its two winget ids are asserted
against the registry by the test suite so the small duplication can't drift.

## Useful flags

| Flag | Does |
|------|------|
| `--dry-run` | Print every command it would run, touch nothing |
| `--platform=<name>` | Force a platform. `darwin`, `debian`, `fedora`, `arch`, `windows` |

`--platform` is for checking the plan for a machine you're not sitting at. Detection of what's
*already installed* still runs against the real machine, so the output is a plan, not a simulation.

## How it's put together

The whole thing is one registry plus a dispatcher. A program declares where it comes from on each
platform, and the installer picks the right source:

```ts
FZF: {
   name: 'fzf',
   detect: { kind: 'bin', name: 'fzf' },
   sources: {
      darwin:  { manager: 'brew',   packages: ['fzf'] },
      debian:  { manager: 'apt',    packages: ['fzf'] },
      fedora:  { manager: 'dnf',    packages: ['fzf'] },
      arch:    { manager: 'pacman', packages: ['fzf'] },
      windows: { manager: 'winget', packages: ['junegunn.fzf'] },
   },
},
```

**A program with no source for a platform simply isn't applicable there.** That's how zsh, the C
toolchain, and the zsh plugins vanish on Windows without a single `if (windows)` in the install
path. It falls out of the data.

| File | Job |
|------|-----|
| `install/install.ts` | Entry point. Parses flags, picks the platform, runs the list, reports |
| `install/lib/programs.ts` | The registry. Every program and where it comes from per platform |
| `install/lib/managers.ts` | Manager to command. `brew install x`, `sudo apt-get install -y x`, ... |
| `install/lib/steps.ts` | Everything that isn't a package: `ZDOTDIR`, chsh, git config, tarballs |
| `install/lib/claude.ts` | The `~/.claude` linker and MCP registration |
| `install/lib/platform.ts` | OS and distro detection, WSL detection, a portable `which` |
| `install/lib/wsl.ts` | Parses `wsl --list --verbose`, UTF-16LE null bytes and all |
| `install/lib/exec.ts` | Command running. The `run`/`tryRun`/`probe` dry-run seam lives here |
| `install/lib/result.ts` | `Ok` / `Err`. Steps return failures instead of throwing |
| `install/lib/ui.ts` | The doom-one coloured output helpers |

The registry and the command builders are pure functions, so they're covered by tests rather than
by hoping. `node --test` from `install/` asserts things like "no program is unreachable on every
platform", "only apt/dnf/pacman ever use sudo", "brew never appears outside darwin", and "neovim
never comes from a Linux package manager".

## Idempotency

**Run it as often as you like.** Every program and every step checks before it acts, so a second
run is a repair pass and a third is a no-op. This is the intended entry point on every machine,
including ones that are already set up.

| Behavior | How |
|----------|-----|
| Already installed | Detected per program: a binary on PATH, a font file, or a `.app` bundle |
| Half-installed | Only the missing pieces get installed |
| Drifted symlink | A link pointing somewhere else is replaced; a real file is backed up to `<name>.backup-<timestamp>` |
| Missing symlink | Re-created. This is the self-heal path |
| MCP servers | Skipped when already registered at the same URL, so re-running never drops their OAuth tokens |
| `~/.zshenv`, `~/.gitconfig` | Content-checked, never appended twice |

Two things to know:

- **`--dry-run` never mutates.** The runner exposes `run` and `tryRun` (both no-op under dry-run)
  and `probe`, which executes for real so the printed plan reflects the actual machine. `probe`
  must only ever be handed read-only commands. There's a test pinning that contract, because
  getting it wrong once meant a dry run really deleted MCP servers and only pretended to re-add
  them.
- **Failures are collected, not thrown.** Steps return `Ok`/`Err`, the run finishes, and the
  failures print together at the end with a non-zero exit. One broken package doesn't stop the
  other twenty.

## Steps that aren't packages

| Step | Platforms | What happens |
|------|-----------|--------------|
| Xcode Command Line Tools | macOS | Triggers the GUI installer if `xcode-select -p` fails |
| Rust toolchain | Unix | rustup via the official script. Windows gets it from winget instead |
| Zsh plugins | Unix | brew on macOS, git clone to `~/.local/share/zsh/plugins` on Linux |
| Neovim (tarball) | Linux | Official prebuilt tarball when the installed nvim is older than 0.10 |
| Shell bootstrap | Unix | Writes `ZDOTDIR` into `~/.zshenv` |
| Default shell | Unix | Registers zsh in `/etc/shells`, then `chsh` |
| Git config | All | Removes a stray `~/.gitconfig` so `git/config` wins (see [Git](git.md)) |
| Emacs | Unix | Points you at `emacs/build-emacs.sh` (see [Emacs](emacs.md)) |
| Fonts | Linux | Warns when no Nerd Font is present. brew and winget install it directly |
| Secrets | All | Nags you about `zsh/secrets.zsh` |
| Claude config | All | Symlinks into `~/.claude` and registers MCP servers (see [Claude Code](claude.md)) |

## Why everything Rust gets built from source

Distro repos ship wildly different versions of eza, fd, ripgrep, starship, and zoxide, and some
of them are years stale. Building with cargo takes longer once and then every machine has the
same versions and the same flags. The only exception is fzf, which is Go, so it comes from the
system package manager.

Those five use `sources: { any: { manager: 'cargo', ... } }`, which means Windows builds them from
source too. winget has native packages for all of them, but taking those would reintroduce exactly
the version drift this rule exists to prevent. There's a test asserting the cargo programs resolve
identically on all five platforms.

The tradeoff is that a fresh machine needs a C toolchain and a few minutes of compile time. Worth
it, in my opinion, for not debugging "why does `eza --git` not work on this box."

## Fonts

Nothing installs a font for you, because font installation is different on every platform and I'd
rather warn than guess. You want **JetBrainsMono Nerd Font**, which is what WezTerm asks for by
name.

```sh
# macOS
brew install --cask font-jetbrains-mono-nerd-font

# Linux: download from https://www.nerdfonts.com, drop into ~/.local/share/fonts
fc-cache -fv
```

Without a Nerd Font you lose icons in eza, the starship prompt symbols, and the powerline
separators in the WezTerm tab bar. It still works, it just looks like a ransom note.

## Adding a new machine

1. Install git and a browser, get your SSH key onto the box.
2. Clone to `~/.config`.
3. `bash install.sh`, or `pwsh install.ps1` on Windows. Run it with `--dry-run` first if you want
   to see the plan.
4. Install a Nerd Font and select it in the terminal.
5. Create `zsh/local.zsh` for anything machine-specific (see [Zsh](zsh.md)). Windows skips this.
6. Create `zsh/secrets.zsh` if this machine needs credentials. It's gitignored. Keep it that way.
7. Run `/verify-settings` inside Claude Code to confirm the symlinks and MCP servers landed.

## Platform notes

**macOS** is the primary target. Homebrew handles zsh plugins and fzf, Xcode Command Line Tools
provide the C toolchain cargo needs, and the zsh plugin sources resolve under
`/opt/homebrew/share/`.

**Linux** (Debian/Ubuntu, Fedora, Arch) gets the non-Rust base from the package manager plus
`build-essential` / `gcc` / `base-devel`. Zsh plugins are git-cloned on every distro rather than
packaged, so the source is consistent and current.

**Windows** is a host for WezTerm and its font. Everything else lives in WSL2.

These dotfiles are about 90% unix, so a native-Windows install is a degraded subset with no zsh,
no starship, no eza, and no Emacs. Running them in WSL2 gets all of it, plus cargo builds that
don't need MSVC and a C compiler that stops nvim-treesitter failing on parser installs.

```powershell
pwsh install.ps1                      # WezTerm + font + WSL2 check
wsl -- bash ~/.config/install.sh      # the actual dotfiles
```

Inside WSL the distro detects as `debian` (or `fedora`/`arch`) and takes the normal Linux path.
There is no special WSL branch in the installer, because there doesn't need to be.

- **The full move is documented in [WINDOWS-MIGRATION.md](../WINDOWS-MIGRATION.md)**, including
  getting `~/coding` across without losing uncommitted work.
- **Don't install Node on Windows.** A Windows `node.exe` leaking into WSL through PATH interop
  makes `os.homedir()` return `C:\Users\...`, which breaks the Claude code-style hook on every
  edit. The installer's WSL2 health step checks for this.
- **Directory symlinks use junctions**, which need no elevation. File symlinks (`settings.json`,
  `CLAUDE.md`) still need Developer Mode (Settings → System → For developers) or an elevated shell.
  You get a message saying exactly that if it fails.
- **`--native` / `-Native`** installs the old degraded Windows stack if WSL2 ever isn't an option.
  That path does need Node on Windows.

## Updating tools later

```sh
# Rust tools. Needs: cargo install cargo-update
cargo install-update -a

# macOS
brew upgrade

# Windows
winget upgrade --all

# Zsh plugins on Linux. Re-running install.sh git-pulls each plugin.
bash install.sh
```

## Adding a program

1. Add an entry to `Programs` in `install/lib/programs.ts` with a source per platform it applies to.
1. Add it to `ORDER` in `install/install.ts` so it actually runs.
1. `cd install && npm test`. The registry tests catch an empty package list, a manager on the wrong
   platform, or a program that's unreachable everywhere.
1. `node install/install.ts --dry-run --platform=<each>` and read the plan.

Typechecking (`cd install && npm run typecheck`) needs `npm install` once for `typescript` and
`@types/node`. That's dev-only tooling. **The installer itself never needs `node_modules`,** which
matters because it has to run on a machine where nothing is set up yet.

`tsconfig.json` sets `erasableSyntaxOnly`, so the compiler rejects any syntax Node can't strip. You
physically cannot add an `enum` or a parameter property without the typecheck failing, which is why
`Programs` is a `const` object rather than the enum it looks like it wants to be.
