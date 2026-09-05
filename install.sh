#!/usr/bin/env bash
# Bootstrap shim. All installer logic lives in install/install.ts, which Node runs
# directly via type stripping (no build step, no dependencies). This file exists so
# `bash install.sh` keeps working and so there's something to run before anything
# is set up.
#
#   bash install.sh                      install everything for this platform
#   bash install.sh --dry-run            print the plan, touch nothing
#   bash install.sh --platform=fedora    force a platform (testing)
set -euo pipefail

RED='\033[38;2;255;108;107m'; RESET='\033[0m'
die() { printf "${RED}  ${RESET} %s\n" "$*" >&2; exit 1; }

root="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Type stripping runs without a flag from 22.18 on.
node_version_ok() {
  local version major minor
  version="$(node --version 2>/dev/null)" || return 1
  version="${version#v}"
  major="${version%%.*}"
  minor="${version#*.}"; minor="${minor%%.*}"
  (( major > 22 )) || { (( major == 22 )) && (( minor >= 18 )); }
}

command -v node >/dev/null 2>&1 || die "node is required. Install Node >= 22.18, then re-run: bash install.sh"
node_version_ok || die "node $(node --version) is too old for TypeScript type stripping. Need >= 22.18."

exec node "$root/install/install.ts" "$@"
