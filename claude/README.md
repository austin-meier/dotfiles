# claude

Version-controlled [Claude Code](https://code.claude.com) config, symlinked into `~/.claude`.

**Full documentation: [`docs/claude.md`](../docs/claude.md)**, covering the symlink bridge, settings,
the code-style hook, skills, libs, and MCP servers.

## Quick reference

| Path | Purpose |
|------|---------|
| `settings.json` | Model, permissions, hooks, plugins, effort level |
| `CLAUDE.md` | Global machine-agnostic instructions |
| `mcp-servers.json` | Tracked manifest of user-scope MCP servers |
| `skills/` | Personal skills |
| `commands/` | Slash commands (`/name` from `name.md`) |
| `agents/` | Subagent definitions |
| `output-styles/` | Custom output styles |
| `libs/` | Reference utility source Claude reads but never imports |
| `hooks/` | Hook scripts, referenced at their repo path, not symlinked |

## Linking

There's no separate linker any more. `install/lib/claude.ts` does it as part of the main
installer, on every platform:

```sh
bash ~/.config/install.sh        # unix, and inside WSL2 on Windows
```

Re-running is safe: correct links are skipped, missing ones are re-created, and MCP servers
already registered at the right URL are left alone so their OAuth tokens survive.
