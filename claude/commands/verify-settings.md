---
name: verify-settings
description: Verify the portable Claude config on this machine - symlinks into ~/.claude, user-scope MCP servers, skills, the four style hooks (functionally tested), and the global CLAUDE.md - then report pass/fail with remediation.
allowed-tools: Bash, Read, Glob
disable-model-invocation: true
---

# Verify portable Claude config

Run a full health check of the version-controlled Claude config (repo at `~/.config/claude`,
symlinked into `~/.claude`). Work through every section, then print the **Report** at the end.

Pick the shell for this OS: on Windows prefer Git Bash (the hook also runs there); the snippets
below are bash, with PowerShell equivalents noted. Use absolute `~`/`$HOME` expansion that the
shell resolves. Don't edit anything, this is read-only diagnosis. For each check, record
PASS / FAIL (+ the actual value) and, on FAIL, the remediation.

## 1. Repo + symlinks

Confirm the repo exists at `~/.config/claude`. Then confirm each of these in `~/.claude` is a
**symlink** resolving into `~/.config/claude/<name>`:
`settings.json`, `CLAUDE.md`, `skills`, `commands`, `agents`, `output-styles`, `libs`.

- bash: `for n in settings.json CLAUDE.md skills commands agents output-styles libs; do printf '%s -> %s\n' "$n" "$(readlink "$HOME/.claude/$n" 2>/dev/null || echo NOT-A-LINK)"; done`
- PowerShell: ``'settings.json','CLAUDE.md','skills','commands','agents','output-styles','libs' | % { $i=Get-Item "$HOME\.claude\$_" -Force -EA SilentlyContinue; "{0} -> {1}" -f $_, ($i.Target -join ',') }``

Each target must point inside `~/.config/claude`. FAIL remediation: re-run the installer, which
re-creates any missing link (`bash ~/.config/install.sh` on unix and inside WSL2; on a native
Windows box, `pwsh ~/.config/install.ps1 -Native` and Developer Mode for the file symlinks).

## 2. User-scope MCP servers

Run `claude mcp list`. Compare against the manifest `~/.config/claude/mcp-servers.json` (currently
expect **atlassian** and **Matrixify**, both HTTP). "Needs authentication" is OK (auth with
`/mcp`); what matters is both are registered. FAIL remediation: re-run the installer, which
re-registers anything missing from the manifest. It leaves correctly-registered servers alone, so
it won't drop their tokens.

## 3. Skills present + discoverable

Confirm these files exist (through the symlink is fine):
- `skills/writing-code/SKILL.md` (must contain the **zero comments** section),
  `skills/writing-code/languages/typescript.md`
- `skills/writing-docs/SKILL.md`
- `skills/jam-plus/SKILL.md` + `skills/jam-plus/references/{systems,packages,schema-pipeline,schema-index}.md`
- `libs/typescript/utils/`: the TS toolset the `writing-code` skill points to. It must be
  linked into `~/.claude/libs/` (the linker handles this) so the skill's relative paths resolve.

Also confirm `writing-code`, `writing-docs`, and `jam-plus` appear in **your own available-skills
list** for this session (proves discovery, not just files on disk). FAIL remediation: ensure the
`skills` symlink is correct (section 1) and the session was started after linking.

## 4. The hooks (the important ones)

Four hooks: a pre-write guard and two post-write guards on `Write|Edit|MultiEdit`, and a reset on
`PostCompact` + `SessionEnd`.

a. **Wired:** read `~/.claude/settings.json` and confirm

   - `hooks.PreToolUse` has a matcher `Write|Edit|MultiEdit` running
     `node -e "require(require('os').homedir()+'/.config/claude/hooks/code-style-guard.cjs')"`
   - `hooks.PostToolUse` has a matcher `Write|Edit|MultiEdit` running both
     `node -e "require(require('os').homedir()+'/.config/claude/hooks/comment-guard.cjs')"` and
     `node -e "require(require('os').homedir()+'/.config/claude/hooks/prose-guard.cjs')"`
   - `hooks.PostCompact` and `hooks.SessionEnd` each run
     `node -e "require(require('os').homedir()+'/.config/claude/hooks/style-guard-reset.cjs')"`

b. **Scripts present:** `~/.config/claude/hooks/code-style-guard.cjs`,
   `~/.config/claude/hooks/comment-guard.cjs`, `~/.config/claude/hooks/prose-guard.cjs`,
   `~/.config/claude/hooks/style-guard-reset.cjs`, and under `lib/`: `comment-scan.cjs`,
   `prose-scan.cjs`, `style-markers.cjs`.

c. **Scanner tests pass:** `node --test ~/.config/claude/hooks/` should report 0 failures.

d. **Functionally test the pre-write guard** (use a UNIQUE session id so the once-per-session gate
   fires):
   - Code file should BLOCK (exit 2) with the reminder. bash:
     ```
     printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"/tmp/x.ts"},"session_id":"verify-'"$RANDOM$RANDOM"'"}' \
       | node -e "require(require('os').homedir()+'/.config/claude/hooks/code-style-guard.cjs')"; echo "exit=$?"
     ```
     Expect the `[code-style-guard]` message and `exit=2`.
   - Non-code file should PASS silently. bash: same command but `file_path":"/tmp/x.md"` -> expect no output and `exit=0`.

e. **Functionally test the comment guard:**
   - Commented code should BLOCK (exit 2). bash:
     ```
     printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"/tmp/x.ts","content":"const a = 1; // set a"}}' \
       | node -e "require(require('os').homedir()+'/.config/claude/hooks/comment-guard.cjs')"; echo "exit=$?"
     ```
     Expect the `[comment-guard]` message and `exit=2`.
   - Clean code should PASS silently: same command with `"content":"const a = 1;"` -> no output, `exit=0`.

f. **Functionally test the prose guard:** same shape as (e) with `file_path":"/tmp/x.md"` and
   `"content":"a \u2014 b"` -> expect the `[prose-guard]` message and `exit=2`; with
   `"content":"a, b"` -> no output, `exit=0`.

g. **Functionally test the reset:** run the pre-write guard test from (d) twice with the SAME
   session id (second run should `exit=0`), then pipe `{"session_id":"<same id>"}` into the
   `style-guard-reset.cjs` command, then run the guard a third time. Expect `exit=2` again.

   PowerShell equivalent for both: pipe the JSON string to the same `node -e "..."` and check
   `$LASTEXITCODE`.

   FAIL remediation: if (a) is missing the hook isn't wired (check the settings.json symlink); if a
   functional test errors, run the script directly with `< /dev/null` to surface the error. Note:
   new/changed hooks must be approved once via `/hooks` before Claude executes them.

## 5. Global CLAUDE.md

Read `~/.claude/CLAUDE.md` and confirm it contains: the `~/coding/{language}/{project}` layout
rule, the **no Claude co-author** git rule, and the **MANDATORY `writing-code`** directive.

## Report

Print a table: Check | Result (PASS/FAIL) | Detail. End with an overall verdict. If anything
failed, list the specific remediation steps. If all pass, state that the portable config is fully
installed and the enforcement hook is active on this machine.
