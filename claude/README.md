# claude

Version-controlled [Claude Code](https://code.claude.com) configuration.

Claude Code reads its config from `~/.claude`, not from `~/.config`. The rest of this dotfiles
repo uses the XDG pattern (tools read straight from `~/.config`), so this directory bridges the
gap with **symlinks**: only the authored config items are linked into `~/.claude`, while all
machine state (history, sessions, caches, credentials) stays put and out of git.

## What's here

| Path | Purpose |
|------|---------|
| `settings.json` | Model, enabled plugins, effort level, update channel |
| `CLAUDE.md` | Global, machine-agnostic instructions (points at the style skills) |
| `mcp-servers.json` | Tracked manifest of user-scope MCP servers (registered, not symlinked) |
| `skills/` | Personal skills — `writing-docs`, `writing-code`, `jam-plus` |
| `commands/` | Personal slash commands (`/name` from `name.md`) |
| `agents/` | Personal subagent definitions |
| `output-styles/` | Custom output styles |
| `hooks/` | Hook scripts referenced by `settings.json` (run via Node; **not** symlinked) |
| `link.ps1` | Windows bootstrapper |
| `link.sh` | macOS/Linux bootstrapper (also invoked by `../install.sh`) |

## Bootstrap

### Windows

Symlink creation needs **Developer Mode** (Settings → System → For developers) or an elevated
shell. Then:

```powershell
pwsh ~/.config/claude/link.ps1   # or: powershell -File ~/.config/claude/link.ps1
```

### macOS / Linux

Handled automatically by the repo's `install.sh`, or run directly:

```sh
bash ~/.config/claude/link.sh
```

Both linkers:

1. Symlink `settings.json`, `CLAUDE.md`, `skills/`, `commands/`, `agents/`, `output-styles/`
   into `~/.claude`. Existing real files are moved to `<name>.backup-<timestamp>` first.
   Re-running is safe (correct links are skipped).
2. Register each server in `mcp-servers.json` at **user scope** via
   `claude mcp add-json <name> '<json>' --scope user` (written to `~/.claude.json`, which is
   never committed).

After bootstrapping, authenticate any HTTP/OAuth MCP servers inside Claude with `/mcp`.

## Hooks

`settings.json` registers a `PreToolUse` hook (`hooks/code-style-guard.cjs`) that enforces the
`writing-code` skill: the first time per session that Claude tries to `Write`/`Edit`/`MultiEdit`
a file in a tracked programming language (ts/js, clojure, rust, c/c++, java, python, go, elixir,
c#), it blocks the call (exit 2) and reminds Claude to read the skill + the matching
`languages/<lang>.md`. Subsequent edits of that language in the session pass through.

The hook is invoked as:

```
node -e "require(require('os').homedir()+'/.config/claude/hooks/code-style-guard.cjs')"
```

The script path is resolved inside Node via `os.homedir()`, so it needs no shell variable, `~`,
or symlink and behaves identically under sh, Git Bash, and PowerShell. That's why `hooks/` is
**not** in the symlink table — it's referenced at its repo path (`~/.config/claude/`) directly.

New/changed hooks require approval: after a fresh clone (or when this changes), run `/hooks` in
Claude once to review and trust it. Windows note: the hook runs under Git Bash if installed,
otherwise PowerShell (both verified working).

## What is NOT tracked

State lives in `~/.claude` and never enters this repo: `~/.claude.json`, `.credentials.json`,
`history.jsonl`, `projects/`, `sessions/`, `cache/`, `file-history/`, `backups/`,
`shell-snapshots/`, `plugins/`, `ide/`. `settings.local.json` (per-machine overrides) is also
ignored.

## Adding things

- **MCP server:** add an entry under `mcpServers` in `mcp-servers.json`, re-run the linker.
- **Skill:** create `skills/<name>/SKILL.md` with `name` + `description` frontmatter.
- **Command:** drop a `commands/<name>.md` file → becomes `/<name>`.
- **Agent:** drop an `agents/<name>.md` file with `name` + `model` frontmatter.

Edits to any symlinked file are live immediately (no re-link needed) — they're the same file
Claude reads.
