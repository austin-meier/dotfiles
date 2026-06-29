# dotfiles

doom-one themed environment. WezTerm + Zsh + Starship + Neovim + Emacs, tuned to feel consistent across the stack.

## Quick install

```sh
git clone <your-dotfiles-repo> ~/.config
cd ~/.config
bash install.sh
exec zsh
```

`install.sh` detects the OS and installs all required tools. See [Platform notes](#platform-notes) for caveats.

---

## What's in here

| Path | Purpose |
|------|---------|
| `wezterm/` | Terminal emulator config — doom-one colors, powerline tabs, vi copy mode |
| `zsh/` | Shell config via `ZDOTDIR` — eza, fd, fzf, zoxide, starship |
| `starship.toml` | Prompt — doom-one palette, directory + git + language versions |
| `nvim/` | Neovim config |
| `emacs/` | DOOM Emacs config |
| `ripgrep/config` | rg defaults — smart-case, hidden files, ignores .git/node_modules |
| `git/ignore` | Global gitignore |
| `claude/` | Claude Code config — symlinked into `~/.claude`; settings, skills, MCP servers (see `claude/README.md`) |

---

## Requirements

### Fonts

A [Nerd Font](https://www.nerdfonts.com/font-downloads) is required for icons in eza, starship, and WezTerm tab bar glyphs. **JetBrainsMono Nerd Font** is recommended — it's what the WezTerm config expects.

```sh
# macOS
brew install --cask font-jetbrains-mono-nerd-font

# Linux — download from https://www.nerdfonts.com and install to ~/.local/share/fonts
fc-cache -fv
```

### Shell tools

All installed by `install.sh`. Listed here for reference:

All Rust-based tools are built from source with cargo on every platform for consistent versions; only fzf (Go) comes from the system package manager.

| Tool | Source | Used for |
|------|--------|---------|
| [eza](https://github.com/eza-community/eza) | cargo | `ls` replacement with icons and git status |
| [fd](https://github.com/sharkdp/fd) | cargo (`fd-find`) | Fast `find` replacement; fzf file source |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | cargo | Fast grep |
| [fzf](https://github.com/junegunn/fzf) | brew / apt / dnf / pacman | Fuzzy finder — `Ctrl-R` history, `Ctrl-T` files, `Alt-C` dirs |
| [starship](https://starship.rs) | cargo | Cross-shell prompt |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | cargo | Smart `cd` that learns frequent dirs |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | brew / git | Fish-style inline history suggestions |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | brew / git | Command syntax coloring |

---

## Shell layout

```
~/.zshenv                     ← sets ZDOTDIR, sources cargo env
~/.config/zsh/
  .zshrc                      ← main shell config
  secrets.zsh                 ← credentials (NOT committed — see below)
  .zsh_history                ← history file
~/.config/starship.toml       ← prompt config
~/.config/ripgrep/config      ← rg defaults
```

### Key bindings (fzf)

| Key | Action |
|-----|--------|
| `Ctrl-R` | Fuzzy search shell history |
| `Ctrl-T` | Fuzzy insert file path at cursor |
| `Alt-C` | Fuzzy `cd` into directory |
| `Ctrl-/` | Toggle preview pane |

### eza aliases

| Alias | Expands to |
|-------|-----------|
| `ls` | Icons, directories first |
| `lsa` | `ls` + hidden files |
| `ll` | Long format, human sizes, git status |
| `lt` | Tree view, 2 levels |
| `lta` | Tree view, 3 levels, all files |

---

## Platform notes

### macOS (primary)

Uses Homebrew for zsh plugins and fzf, plus the Xcode Command Line Tools for the C toolchain cargo needs. All Rust tools (ripgrep, fd, eza, starship, zoxide) are built with cargo. The zsh plugin sources resolve to `/opt/homebrew/share/`.

### Linux (Debian/Ubuntu, Fedora, Arch)

The system package manager installs only the non-Rust base (zsh, git, curl, archive tools, fzf) plus a C build toolchain (`build-essential` / `gcc` / `base-devel`). All Rust tools are then built with cargo, so the same versions land on every distro regardless of how stale the repos are. Zsh plugins are git-cloned to `~/.local/share/zsh/plugins/` on all Linux distros for a consistent, up-to-date source.

### Windows

WezTerm runs on Windows and the `wezterm/` config works there (it already branches on `is_windows`). The zsh config is **not** applicable on Windows — WezTerm defaults to `pwsh`.

---

## Secrets

`zsh/secrets.zsh` is sourced at shell startup but **must not be committed**. It holds credentials that can't live in the environment another way.

Add to your dotfiles `.gitignore`:

```
zsh/secrets.zsh
```

Rotate any credentials that were previously committed in plaintext before treating this repo as safe to push.

---

## Updating tools

```sh
# Rust tools (eza, fd, starship, zoxide, rg)
cargo install-update -a          # requires: cargo install cargo-update

# Homebrew (macOS)
brew upgrade

# Zsh plugins (Linux git-clone install)
bash install.sh                  # re-running is safe, it git-pulls each plugin
```
