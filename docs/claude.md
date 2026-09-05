# Claude Code

[← Back to the index](../CLAUDE.md)

Version-controlled [Claude Code](https://code.claude.com) config, living at `claude/`.

This is the one directory in the repo that can't just sit where it is. Claude Code reads
`~/.claude`, not `~/.config/claude`, and `~/.claude` is also where it dumps every bit of runtime
state it has. So instead of tracking the whole directory and fighting the noise, this one bridges
the gap with **granular symlinks**: only the authored files get linked into `~/.claude`, and all
the state (history, sessions, caches, credentials) stays put and stays out of git.

## What's here

| Path | Purpose |
|------|---------|
| `settings.json` | Model, permissions, hooks, plugins, effort level |
| `CLAUDE.md` | Global machine-agnostic instructions, points at the style skills |
| `mcp-servers.json` | Tracked manifest of user-scope MCP servers (registered, not symlinked) |
| `skills/` | Personal skills |
| `commands/` | Personal slash commands (`/name` from `name.md`) |
| `agents/` | Personal subagent definitions |
| `output-styles/` | Custom output styles |
| `libs/` | Reference utility source Claude can read but not import |
| `hooks/` | Hook scripts + their tests, referenced at their repo path, **not** symlinked |
| (linking) | Handled by `install/lib/claude.ts`, shared with the installer |

## Bootstrap

Part of the main installer on every platform, so `bash install.sh` (or `pwsh install.ps1`) is all
it takes. There used to be a `link.sh` and a `link.ps1` implementing the same algorithm twice;
they're now one TypeScript module at `install/lib/claude.ts`.

On Windows, directory links are created as **junctions**, which need no elevation. File symlinks
(`settings.json`, `CLAUDE.md`) still need **Developer Mode** (Settings → System → For developers)
or an elevated shell, and you get a message saying so if it fails.

The linker does two things:

1. Symlink `settings.json`, `CLAUDE.md`, `skills/`, `commands/`, `agents/`, `output-styles/`, and
   `libs/` into `~/.claude`. Any existing real file is moved to `<name>.backup-<timestamp>` first.
   Re-running is safe, correct links get skipped.
1. Register every server in `mcp-servers.json` at user scope via
   `claude mcp add --scope user --transport <type> ...`. The flag form is deliberate: it survives
   every shell's quoting rules identically. It writes to `~/.claude.json`, which is never committed.

After bootstrapping, run `/mcp` inside Claude to authenticate any OAuth MCP servers.

Edits to symlinked files are live immediately. No re-link needed, it's the same file.

## Settings

`model` is whatever `/model` last saved. I flip between Fable and Opus 4.8 constantly, and every
flip writes to the symlinked `settings.json`, so git sees a diff. There is no clean fix for that
(Claude Code only writes the default to user settings), so just don't commit the model line unless
you mean it. `effortLevel` is `high`, `tui` is fullscreen, updates track `latest`, and
`switchModelsOnFlag` is on.

`permissions.allow` pre-approves read-only MCP calls (Atlassian reads, Matrixify exports and job
lookups) plus reads of the skills and libs directories, so routine work doesn't generate a prompt
every thirty seconds.

Enabled plugins: `typescript-lsp`, `rust-analyzer-lsp`, `clangd-lsp` (all official), and
`frontend-design`.

## The hooks

Four of them, all wired in `settings.json`, all living in `hooks/`.

| Hook | When | What it does |
|------|------|--------------|
| `code-style-guard.cjs` | PreToolUse on `Write\|Edit\|MultiEdit` | Blocks the **first** edit to each tracked language per session (exit 2) and tells Claude to invoke the `writing-code` skill with the Skill tool, then read the matching `languages/<lang>.md`. Prose files (md, txt, org, rst) count as a language of their own and get pointed at `writing-docs` instead. Every later edit in that language passes straight through |
| `comment-guard.cjs` | PostToolUse on `Write\|Edit\|MultiEdit` | Scans the text Claude just wrote for comments and rejects the edit (exit 2) if it finds any. Fires on **every** edit, not once per session |
| `prose-guard.cjs` | PostToolUse on `Write\|Edit\|MultiEdit` | Same idea for prose files: rejects the edit if the new text contains an em dash. The `writing-docs` rule is the rule, this is the backstop |
| `style-guard-reset.cjs` | PostCompact, SessionEnd | Forgets which languages the style guard already reminded about, so it fires again after compaction. On SessionEnd it just cleans up the temp-dir markers |

**Why the guard says Skill, not Read:** a skill loaded through the Skill tool gets re-attached
after auto-compaction (the first 5,000 tokens of it, anyway). A plain Read of the same file does
not. The `languages/<lang>.md` read is a separate file and doesn't get that treatment, which is
the whole reason the reset hook exists: after compaction the guard fires once more per language
and Claude re-reads it.

**Why `writing-code` has no `paths` frontmatter:** for skills, `paths` *hides* the description
until Claude reads a matching file. It doesn't widen anything. A hidden skill can't be invoked
(`Unknown skill: writing-code`), which is exactly the wrong behavior for a skill that is supposed
to be mandatory everywhere. So it's always listed, and the hook does the enforcing.

Tracked languages are ts/js, clojure, rust, c/c++, java, python, go, elixir, and c#. That map lives
once, in `hooks/lib/comment-scan.cjs`, and both code guards import it so they can't drift apart.
The prose extensions live in `hooks/lib/prose-scan.cjs` the same way. The per-session marker files
live in `hooks/lib/style-markers.cjs`, shared by the guard and the reset. Config,
shell, and lua are deliberately excluded, so editing most of the dotfiles in this repo trips
nothing. Markdown does trip the prose side, which is the point.

**Why the comment guard exists:** the `writing-code` skill says to write zero comments, and models
are trained hard in the other direction. The skill is the rule and the hook is the backstop. It
only ever scans the *new* text (`Write.content`, `Edit.new_string`, `MultiEdit.edits[]`), never the
surrounding file, so comments I wrote myself are invisible to it and can't be flagged. Real
directives (`eslint-disable`, `@ts-expect-error`, `//go:`, shebangs, `# noqa`) are allowlisted,
and string contents are tracked properly so a URL or a `#` inside a string is never a false hit.

The scanner is a pure function with a test suite, because a heuristic that blocks edits had better
not be guessing:

```sh
node --test claude/hooks/
```

All four are invoked the same way:

```
node -e "require(require('os').homedir()+'/.config/claude/hooks/<name>.cjs')"
```

The path gets resolved inside Node via `os.homedir()`, so there's no shell variable, no `~`, and
no symlink involved, and it behaves identically under sh, Git Bash, and PowerShell. That's exactly
why `hooks/` isn't in the symlink table, it's referenced at its repo path directly.

> New or changed hooks need approval. After a fresh clone, run `/hooks` in Claude once to review
> and trust them. On Windows they run under Git Bash if it's installed, otherwise PowerShell.
> Both are verified working.

## Skills

| Skill | What it does |
|-------|--------------|
| `writing-code` | The personal code style: functional, zero comments, Node for scripts, verify before saying done. Mandatory before writing code in any language, enforced by the hooks. Has per-language files under `languages/` |
| `writing-docs` | The personal documentation voice, including the no-em-dash rule and commit message shape. This doc was written with it |
| `jam-plus` | Map of the JAM+ codebases, domain model, schema pipeline, and app architecture |
| `improve-codebase` | Scans a codebase for deepening opportunities and produces an HTML report |
| `resolve-merge-conflicts` | Procedure for working through an in-progress merge or rebase conflict |

## Libs

`libs/typescript/utils/` holds real utility source (arrays, strings, objects, numbers, fetch, jwt,
cookies, pricing, zod helpers, a `Result` type, discriminated-union helpers, dimensions). Claude
reads these for reference so generated code matches the shapes I actually use. They're reference
material, not a package to import.

## Commands

`/verify-settings` runs a read-only health check of the whole setup on this machine: symlinks,
user-scope MCP servers, skills, the global `CLAUDE.md`, and a functional test of both hooks,
then reports pass/fail with remediation. Run it after setting up a new machine.

## What never gets tracked

`~/.claude.json`, `.credentials.json`, `history.jsonl`, `projects/`, `sessions/`, `cache/`,
`file-history/`, `backups/`, `shell-snapshots/`, `plugins/`, `ide/`, and `settings.local.json`.
The gitignore has defensive rules for most of these even though the granular symlinks mean they
shouldn't be able to land here in the first place.

## Adding things

| Thing | How |
|-------|-----|
| MCP server | Add an entry under `mcpServers` in `mcp-servers.json`, re-run the installer |
| Skill | Create `skills/<name>/SKILL.md` with `name` and `description` frontmatter |
| Command | Drop `commands/<name>.md`, it becomes `/<name>` |
| Agent | Drop `agents/<name>.md` with `name` and `model` frontmatter |
