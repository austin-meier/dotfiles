# Repo layout and the whitelist gitignore

[← Back to the index](../CLAUDE.md)

This repo is `~/.config` itself, not a separate folder that gets symlinked into place. Every tool
in here reads its config straight out of `~/.config` because they all follow the XDG spec. No
stow, no link farm, no `~/.config` full of dangling symlinks.

The one exception is Claude Code, which insists on `~/.claude`. That gets its own linker, see
[Claude Code](claude.md).

## The gitignore is a whitelist

`~/.config` is where every app on the system dumps its state. If this repo used a normal
blacklist gitignore, `git status` would be a firehose of Slack caches and GTK settings forever.

So `.gitignore` ignores everything at the top level and un-ignores only what I actually want:

```gitignore
# Ignore every top-level entry.
/*

!/.gitignore
!/README.md
!/install.sh
!/install.ps1
!/starship.toml

!/claude/
!/clojure/
!/install/
!/emacs/
!/git/
!/nvim/
!/ripgrep/
!/wezterm/
!/zsh/
```

Whitelisting a directory tracks its whole contents, so the per-directory junk gets re-excluded
further down the file (`.DS_Store`, `zsh/secrets.zsh`, `zsh/.zsh_history`, lazy.nvim state, Claude
credentials, `.cpcache`, and friends).

`emacs/` carries its own nested whitelist `.gitignore`, because an Emacs directory generates an
absurd amount of state and only five files in there are actually mine.

## Adding a new config to the repo

1. Add a `!` line for it in `.gitignore` under **Tracked config directories**.
1. If the directory generates state (caches, history, lockfiles), add re-ignore lines for that
   state under **Per-directory exclusions**.
1. `git add` the config and check `git status` is quiet afterwards. If it isn't, you missed some
   state, go back to step 2.
1. Write a doc for it in `docs/` and add a row to the index table in `CLAUDE.md`.

## Things that stay out of git, permanently

| Path | Why |
|------|-----|
| `zsh/secrets.zsh` | Credentials. Sourced at shell startup, never committed |
| `zsh/local.zsh` | Per-machine PATH entries, aliases, env |
| `zsh/.zsh_history` and friends | Machine state |
| `claude/settings.local.json` | Per-machine Claude overrides |
| `~/.claude.json`, `.credentials.json` | Claude auth and MCP registration |

If a credential ever lands in a commit, rotate it. Deleting it in a later commit does nothing,
it's still in the history.
