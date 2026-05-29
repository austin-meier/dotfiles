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

| Tool | Source | Used for |
|------|--------|---------|
| [eza](https://github.com/eza-community/eza) | cargo / brew | `ls` replacement with icons and git status |
| [fd](https://github.com/sharkdp/fd) | cargo | Fast `find` replacement; fzf file source |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | cargo / brew | Fast grep |
| [fzf](https://github.com/junegunn/fzf) | brew / apt | Fuzzy finder — `Ctrl-R` history, `Ctrl-T` files, `Alt-C` dirs |
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
| `la` | `ls` + hidden files |
| `ll` | Long format, human sizes, git status |
| `lt` | Tree view, 2 levels |
| `lta` | Tree view, 3 levels, all files |

---

## Platform notes

### macOS (primary)

Uses Homebrew for zsh plugins and fzf; cargo for eza, fd, starship, and zoxide. The zsh plugin sources resolve to `/opt/homebrew/share/`.

### Linux (Debian/Ubuntu)

`fd` is packaged as `fd-find` — the install script creates a `~/.local/bin/fd` shim automatically. Zsh plugins are git-cloned to `~/.local/share/zsh/plugins/` since they're often absent or outdated in apt. Rust-based tools (eza, starship, zoxide) are installed via cargo.

### Linux (Fedora, Arch)

Arch has all tools in the official repos — `install.sh` uses pacman only, no cargo step needed. Fedora uses dnf for base tools + cargo for eza/starship/zoxide.

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
