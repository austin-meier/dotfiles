# dotfiles

This repo **is** `~/.config`. Not a folder that gets symlinked into place, the XDG config
directory itself, tracked with a whitelist `.gitignore` so the state every app on the system
dumps in here stays invisible.

One doom-one themed environment across WezTerm, Zsh, Starship, Neovim, Emacs, and Claude Code,
running on macOS, Linux, and Windows via WSL2. The editors deliberately share a keybinding
vocabulary: the `SPC` leader trees in Emacs and Neovim mirror each other, and WezTerm's pane and
copy-mode bindings mirror both.

## Install

```sh
git clone git@github.com:austin-meier/dotfiles.git ~/.config
cd ~/.config
bash install.sh        # macOS / Linux, and inside WSL2 on Windows
exec zsh
```

Windows hosts WezTerm and its font; the dotfiles themselves run in WSL2:

```powershell
pwsh install.ps1                      # WezTerm + font + WSL2 check
wsl -- bash ~/.config/install.sh      # the actual dotfiles
```

The installer is TypeScript run through Node's type stripping, so **Node >= 22.18 is the only
prerequisite** and there's no build step. Run it as often as you like: it checks before it acts,
repairs what's missing, and no-ops when everything's fine. `--dry-run` prints the plan without
touching anything.

## Documentation

Start at **[CLAUDE.md](CLAUDE.md)** for the index, or jump straight in:

| Doc | Covers |
|-----|--------|
| [Install and bootstrap](docs/install.md) | The program registry, per-platform dispatch, idempotency, new machines |
| [Windows migration](WINDOWS-MIGRATION.md) | One-time runbook for moving a Windows box to WSL2 |
| [Repo layout](docs/repo-layout.md) | The whitelist gitignore, adding a config, what stays out of git |
| [Zsh](docs/zsh.md) | `ZDOTDIR`, vi mode, fzf, eza, zoxide, machine-local overrides |
| [Starship](docs/starship.md) | Prompt format, and what's disabled on purpose |
| [WezTerm](docs/wezterm.md) | Keybinds, copy mode, theming, the WSL2 domain |
| [Neovim](docs/nvim.md) | The `SPC` tree, plugins, LSP, the startup budget |
| [Emacs](docs/emacs.md) | The literate `config.org`, native-comp fix, source build |
| [Claude Code](docs/claude.md) | Symlink bridge, settings, hooks, skills, MCP servers |
| [Git](docs/git.md) · [ripgrep](docs/ripgrep.md) · [Clojure](docs/clojure.md) | The small ones |

## Requirements

A [Nerd Font](https://www.nerdfonts.com/font-downloads) for icons in eza, starship, and the
WezTerm tab bar. **JetBrainsMono Nerd Font** is what the WezTerm config asks for by name, and the
installer handles it on macOS and Windows. On Linux you install it yourself; the installer tells
you so.

Everything else is [handled by the installer](docs/install.md).
