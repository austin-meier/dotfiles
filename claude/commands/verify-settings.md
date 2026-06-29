---
name: verify-settings
description: Verify the portable Claude config on this machine - symlinks into ~/.claude, user-scope MCP servers, skills, the code-style PreToolUse hook (functionally tested), and the global CLAUDE.md - then report pass/fail with remediation.
allowed-tools: Bash, Read, Glob
disable-model-invocation: true
---

# Verify portable Claude config

Run a full health check of the version-controlled Claude config (repo at `~/.config/claude`,
symlinked into `~/.claude`). Work through every section, then print the **Report** at the end.

Pick the shell for this OS: on Windows prefer Git Bash (the hook also runs there); the snippets
below are bash, with PowerShell equivalents noted. Use absolute `~`/`$HOME` expansion that the
shell resolves. Don't edit anything — this is read-only diagnosis. For each check, record
PASS / FAIL (+ the actual value) and, on FAIL, the remediation.

## 1. Repo + symlinks

Confirm the repo exists at `~/.config/claude`. Then confirm each of these in `~/.claude` is a
**symlink** resolving into `~/.config/claude/<name>`:
`settings.json`, `CLAUDE.md`, `skills`, `commands`, `agents`, `output-styles`.

- bash: `for n in settings.json CLAUDE.md skills commands agents output-styles; do printf '%s -> %s\n' "$n" "$(readlink "$HOME/.claude/$n" 2>/dev/null || echo NOT-A-LINK)"; done`
- PowerShell: ``'settings.json','CLAUDE.md','skills','commands','agents','output-styles' | % { $i=Get-Item "$HOME\.claude\$_" -Force -EA SilentlyContinue; "{0} -> {1}" -f $_, ($i.Target -join ',') }``

Each target must point inside `~/.config/claude`. FAIL remediation: re-run the linker
(`claude/link.ps1` elevated/Developer Mode on Windows, or `bash claude/link.sh` on Unix).

## 2. User-scope MCP servers

Run `claude mcp list`. Compare against the manifest `~/.config/claude/mcp-servers.json` (currently
expect **atlassian** and **Matrixify**, both HTTP). "Needs authentication" is OK (auth with
`/mcp`); what matters is both are registered. FAIL remediation: re-run the linker, which
re-registers from the manifest.

## 3. Skills present + discoverable

Confirm these files exist (through the symlink is fine):
- `skills/writing-code/SKILL.md`, `skills/writing-code/languages/typescript.md`, `skills/writing-code/references/typescript-utils.md`
- `skills/writing-docs/SKILL.md`
- `skills/jam-plus/SKILL.md` + `skills/jam-plus/references/{systems,packages,schema-pipeline,schema-index}.md`

Also confirm `writing-code`, `writing-docs`, and `jam-plus` appear in **your own available-skills
list** for this session (proves discovery, not just files on disk). FAIL remediation: ensure the
`skills` symlink is correct (section 1) and the session was started after linking.

## 4. Code-style hook (the important one)

a. **Wired:** read `~/.claude/settings.json` and confirm `hooks.PreToolUse` has a matcher
   `Write|Edit|MultiEdit` whose command is
   `node -e "require(require('os').homedir()+'/.config/claude/hooks/code-style-guard.cjs')"`.

b. **Script present:** confirm `~/.config/claude/hooks/code-style-guard.cjs` exists.

c. **Functionally test it** (use a UNIQUE session id so the once-per-session gate fires):
   - Code file should BLOCK (exit 2) with the reminder. bash:
     ```
     printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"/tmp/x.ts"},"session_id":"verify-'"$RANDOM$RANDOM"'"}' \
       | node -e "require(require('os').homedir()+'/.config/claude/hooks/code-style-guard.cjs')"; echo "exit=$?"
     ```
     Expect the `[code-style-guard]` message and `exit=2`.
   - Non-code file should PASS silently. bash: same command but `file_path":"/tmp/x.md"` → expect no output and `exit=0`.
   - PowerShell equivalent: pipe the JSON string to the same `node -e "..."` and check `$LASTEXITCODE`.

   FAIL remediation: if (a) is missing the hook isn't wired (check the settings.json symlink); if
   (c) errors, run `node ~/.config/claude/hooks/code-style-guard.cjs < /dev/null` to surface the
   error. Note: new/changed hooks must be approved once via `/hooks` before Claude executes them.

## 5. Global CLAUDE.md

Read `~/.claude/CLAUDE.md` and confirm it contains: the `~/coding/{language}/{project}` layout
rule, the **no Claude co-author** git rule, and the **MANDATORY `writing-code`** directive.

## Report

Print a table: Check | Result (PASS/FAIL) | Detail. End with an overall verdict. If anything
failed, list the specific remediation steps. If all pass, state that the portable config is fully
installed and the enforcement hook is active on this machine.
