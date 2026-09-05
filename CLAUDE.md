# dotfiles

This repo **is** `~/.config`. It's not a separate folder that gets symlinked into place, it's the
XDG config directory itself, tracked with a whitelist `.gitignore` so the state every app on the
system dumps in here stays invisible.

One doom-one themed environment across WezTerm, Zsh, Starship, Neovim, Emacs, and Claude Code,
running on macOS (primary), Linux, and partially Windows. The editors deliberately share a
keybinding vocabulary: the `SPC` leader tree in Emacs and Neovim mirror each other, and the WezTerm
pane and copy-mode bindings mirror both.

```sh
git clone git@github.com:austin-meier/dotfiles.git ~/.config
cd ~/.config
bash install.sh        # macOS / Linux, and inside WSL2 on Windows
pwsh install.ps1       # Windows host: WezTerm + font only
exec zsh
```

On Windows the dotfiles run in **WSL2**; the Windows side only hosts WezTerm and its font. See
[WINDOWS-MIGRATION.md](WINDOWS-MIGRATION.md).

The installer is TypeScript run through Node's type stripping (`install/`), so Node >= 22.18 is the
only prerequisite and there's no build step.

## Documentation

| Doc | Covers |
|-----|--------|
| [Install and bootstrap](docs/install.md) | `install/`, the program registry, per-platform dispatch, setting up a new machine |
| [Windows migration](WINDOWS-MIGRATION.md) | One-time runbook: moving a Windows box to WSL2, including `~/coding` |
| [Repo layout](docs/repo-layout.md) | The whitelist gitignore, adding a new config, what stays out of git |
| [Zsh](docs/zsh.md) | `zsh/.zshrc`, `ZDOTDIR`, vi mode, fzf, eza, zoxide, local overrides |
| [Starship](docs/starship.md) | `starship.toml`, prompt format, what's disabled and why |
| [WezTerm](docs/wezterm.md) | `wezterm/`, keybinds, copy mode, theming, platform branches |
| [Neovim](docs/nvim.md) | `nvim/`, the `SPC` tree, plugins, LSP servers |
| [Emacs](docs/emacs.md) | `emacs/`, the literate `config.org`, `SPC` tree, native-comp fix, source build |
| [Claude Code](docs/claude.md) | `claude/`, the symlink bridge, settings, hooks, skills, MCP servers |
| [Git](docs/git.md) | `git/config` and `git/ignore` |
| [ripgrep](docs/ripgrep.md) | `ripgrep/config` |
| [Clojure](docs/clojure.md) | `clojure/deps.edn`, tools.tools pin |

## Working in this repo

- **Adding a config?** It won't be tracked until you whitelist it in `.gitignore`. See
  [Repo layout](docs/repo-layout.md).
- **Editing a config?** Changes are live immediately. There's no build, no tangle step, no relink.
  The one exception is `emacs/config.org`, which is the source of truth, so edit that and not
  anything tangled out of it.
- **Anything machine-specific** goes in `zsh/local.zsh` or `claude/settings.local.json`, both
  gitignored. Keep the tracked files portable.
- **Adding a tool to the installer?** Add it to `Programs` in `install/lib/programs.ts` and to
  `ORDER` in `install/install.ts`, then run `cd install && npm test`. Never add an `if (windows)` to
  the install path; a program with no source for a platform is already skipped there.
- **`install.ps1` is the one script that isn't a shim** around the TypeScript installer. It stays
  Node-free on purpose so the Windows host never needs a Node install. Its two winget ids are
  pinned to the registry by a test.
- **Secrets** go in `zsh/secrets.zsh`, gitignored. If one ever lands in a commit, rotate it,
  because deleting it later doesn't remove it from history.
- **Changing the theme** means changing it in three places: `wezterm/wezterm.lua`, `starship.toml`,
  and the `FZF_DEFAULT_OPTS` block in `zsh/.zshrc`. They each hardcode the same doom-one palette.
- **Keybindings** in Emacs and Neovim are intentionally parallel. If you add one to a leader tree,
  add the matching one to the other editor, or the muscle memory breaks.

The docs under `docs/` are written with the `writing-docs` skill. Keep new ones in that voice.
