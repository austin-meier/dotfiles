#!/usr/bin/env bash
# Link this repo's Claude Code config into ~/.claude and register user-scope MCP servers.
#
# Creates symlinks from ~/.claude/<item> to ~/.config/claude/<item> for the authored config
# items only; all machine state under ~/.claude is left untouched. Then registers each server
# in mcp-servers.json at user scope via the claude CLI. Idempotent: correct links are skipped,
# and any real file/dir at a target is moved to <name>.backup-<timestamp> first.
#
# Runs standalone (`bash link.sh`) or is sourced by ../install.sh, which calls setup_claude.

# ─── Logging helpers (only define if not already provided by a sourcing script) ──
if ! declare -f info >/dev/null 2>&1; then
  GREEN='\033[38;2;152;190;101m'; BLUE='\033[38;2;81;175;239m'
  YELLOW='\033[38;2;236;190;123m'; RED='\033[38;2;255;108;107m'
  BOLD='\033[1m'; RESET='\033[0m'
  info()    { printf "${BLUE}  ${RESET} %s\n" "$*"; }
  success() { printf "${GREEN}  ${RESET} %s\n" "$*"; }
  warn()    { printf "${YELLOW}  ${RESET} %s\n" "$*"; }
  die()     { printf "${RED}  ${RESET} %s\n" "$*" >&2; exit 1; }
  header()  { printf "\n${BOLD}%s${RESET}\n" "$*"; }
fi

# Resolve this script's own directory (the repo's claude/ dir), even when sourced.
_claude_repo_dir() {
  local src="${BASH_SOURCE[0]}"
  while [[ -h "$src" ]]; do
    local dir; dir="$(cd -P "$(dirname "$src")" && pwd)"
    src="$(readlink "$src")"; [[ "$src" != /* ]] && src="$dir/$src"
  done
  cd -P "$(dirname "$src")" && pwd
}

# ─── Items linked from the repo into ~/.claude ────────────────────────────────
CLAUDE_LINKS=(
  settings.json
  CLAUDE.md
  skills
  commands
  agents
  output-styles
  libs
)

claude_link_item() {
  local name="$1" repo="$2" home="$3" stamp="$4"
  local source="$repo/$name" target="$home/$name"

  [[ -e "$source" ]] || { warn "skip $name (no source in repo)"; return; }

  if [[ -L "$target" ]]; then
    if [[ "$(readlink "$target")" == "$source" ]]; then
      success "$name already linked"; return
    fi
    info "Replacing stale link $name"
    rm -f "$target"
  elif [[ -e "$target" ]]; then
    local kind="file"; [[ -d "$target" ]] && kind="dir"
    warn "$name exists as a real $kind — moving to $name.backup-$stamp"
    mv "$target" "$target.backup-$stamp"
  fi

  ln -s "$source" "$target"
  success "linked $name"
}

claude_register_mcp() {
  local repo="$1"
  header "MCP servers (user scope)"
  if ! command -v claude >/dev/null 2>&1; then
    warn "claude CLI not on PATH — skipping MCP registration"; return
  fi
  local manifest="$repo/mcp-servers.json"
  [[ -f "$manifest" ]] || { warn "no mcp-servers.json — skipping MCP registration"; return; }
  if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
    warn "python not found — cannot parse mcp-servers.json; register servers manually"; return
  fi
  local py; py="$(command -v python3 || command -v python)"

  # Python emits one tab-separated record per server: <name> then the full argument
  # vector for `claude mcp add` (flag form, same as link.ps1 — avoids passing a quoted
  # JSON blob, so both linkers register servers identically). Supports http/sse (url +
  # optional headers) and stdio (command + optional args/env).
  while IFS=$'\t' read -r -a fields; do
    [[ ${#fields[@]} -gt 0 && -n "${fields[0]}" ]] || continue
    local name="${fields[0]}"
    local add_args=("${fields[@]:1}")
    info "registering '$name'"
    # Remove first so the manifest is the source of truth (ignore "not found").
    claude mcp remove "$name" --scope user >/dev/null 2>&1 || true
    if claude mcp add "${add_args[@]}" >/dev/null 2>&1; then
      success "registered '$name'"
    else
      warn "could not register '$name'"
    fi
  done < <("$py" -c '
import json, sys
d = json.load(open(sys.argv[1]))
for name, cfg in d.get("mcpServers", {}).items():
    t = cfg.get("type", "stdio")
    args = ["--scope", "user", "--transport", t]
    if t in ("http", "sse"):
        for hk, hv in (cfg.get("headers") or {}).items():
            args += ["--header", "%s: %s" % (hk, hv)]
        args += [name, cfg["url"]]
    else:
        for ek, ev in (cfg.get("env") or {}).items():
            args += ["-e", "%s=%s" % (ek, ev)]
        args += [name, "--", cfg["command"]] + list(cfg.get("args", []))
    print("\t".join([name] + args))
' "$manifest")
}

# ─── Entry point (called by install.sh, or directly when run standalone) ──────
setup_claude() {
  header "Claude config"
  local repo home stamp
  repo="$(_claude_repo_dir)"
  home="$HOME/.claude"
  stamp="$(date +%Y%m%d-%H%M%S)"

  [[ -d "$home" ]] || { info "Creating $home"; mkdir -p "$home"; }

  info "Linking $repo -> $home"
  local name
  for name in "${CLAUDE_LINKS[@]}"; do
    claude_link_item "$name" "$repo" "$home" "$stamp"
  done

  claude_register_mcp "$repo"
  success "Claude config linked — authenticate HTTP/OAuth MCP servers in Claude with /mcp"
}

# Run only when executed directly, not when sourced.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  setup_claude
fi
