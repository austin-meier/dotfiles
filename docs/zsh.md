# Zsh

[← Back to the index](../CLAUDE.md)

The shell config lives at `zsh/.zshrc` and gets found via `ZDOTDIR`, not via a symlink in `$HOME`.
`install.sh` writes a tiny `~/.zshenv` that sets `ZDOTDIR="$HOME/.config/zsh"` and sources the
cargo env, and that's the only file this repo puts in your home directory.

```
~/.zshenv               sets ZDOTDIR, sources cargo env
~/.config/zsh/
  .zshrc                everything below
  secrets.zsh           credentials, gitignored
  local.zsh             per-machine overrides, gitignored
  .zsh_history          history, gitignored
```

## Vi mode

The shell is modal, because bouncing between evil-mode in Emacs, vim motions in Neovim, and then
emacs keybinds in the shell is a good way to lose your mind.

`bindkey -v` with `KEYTIMEOUT=1`, so `<Esc>` into normal mode is instant instead of the default
0.4 second lag. A few insert-mode keys get restored because vi insert mode drops them by default:

| Key | Does |
|-----|------|
| `Backspace` / `C-h` | Delete past the insert point (vi normally refuses) |
| `C-a` / `C-e` | Start / end of line |
| `C-k` | Kill to end of line |
| `k` / `j` (normal mode) | History search by the prefix already typed |

The cursor shape follows the mode: steady block in normal, beam in insert, and a `preexec` hook
resets it to a beam before any command runs so programs don't inherit a block cursor. Starship
flips the prompt symbol from `❯` to `❮` on its own.

## fzf

Three key bindings do most of the work:

| Key | Action |
|-----|--------|
| `C-r` | Fuzzy search shell history |
| `C-t` | Fuzzy insert a file path at the cursor |
| `Alt-c` | Fuzzy `cd` |
| `C-/` | Toggle the preview pane |

fd is the file source for all of it (`--type f --hidden --follow --exclude .git`), so fzf sees
dotfiles but not `.git` internals. The colors are the doom-one palette hardcoded into
`FZF_DEFAULT_OPTS` so the picker matches WezTerm and the prompt.

The fzf shell integration is version-gated. Modern fzf (>= 0.48) supports `fzf --zsh`, older
distro builds don't, so the config falls back to sourcing whatever key-binding files the distro
scattered around `/usr/share`.

## eza aliases

| Alias | What it is |
|-------|-----------|
| `ls` | Icons, directories first |
| `lsa` | Same plus hidden files |
| `ll` | Long format, human sizes, git status |
| `lt` | Tree, 2 levels |
| `lta` | Tree, 3 levels, all files |

## Other bits

- **zoxide** is initialized with `--cmd cd`, so `cd` itself is the smart one. `cd proj` jumps to
  the project you actually use.
- **zsh-autosuggestions** with the `(history completion)` strategy and async on.
- **zsh-syntax-highlighting**, sourced last of the two, which is the order it wants.
- History is 100k entries, shared across sessions, with dupes squashed and `HIST_VERIFY` on so a
  `!!` expansion shows you the command before running it.
- `AUTO_CD`, `AUTO_PUSHD`, `EXTENDED_GLOB`, `GLOB_DOTS`, `CORRECT`, `NO_BEEP`.
- `EDITOR` and `VISUAL` are both `nvim`, and `vim` / `vi` are aliased to it.
- `RIPGREP_CONFIG_PATH` points at [the ripgrep config](ripgrep.md).

## Plugin lookup

Plugins get sourced from the first path that has them:

1. `/opt/homebrew/share` (macOS)
1. `$XDG_DATA_HOME/zsh/plugins` (Linux git-clone install)

Both are checked on every machine, so the same `.zshrc` works either way without an OS branch.

## Machine-specific config

Two files at the end of `.zshrc`, both gitignored, both optional:

- **`secrets.zsh`** for credentials that have to be in the environment.
- **`local.zsh`** for per-computer PATH entries, app paths, project scripts, aliases.

If you find yourself wanting to add a machine-specific line to `.zshrc`, that's what `local.zsh`
is for. Keep `.zshrc` portable.
