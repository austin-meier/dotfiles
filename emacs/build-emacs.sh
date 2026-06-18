#!/usr/bin/env bash
#
# Portable Emacs source build — downloads, configures, compiles, and installs
# Emacs with native-compilation, tree-sitter, JSON, dynamic modules, and the
# full image stack (rsvg/png/jpeg/tiff/gif/webp).
#
#   Linux : pgtk (Wayland) on Fedora, X11/GTK3 on Debian/Ubuntu/Arch;
#           installs to /usr/local  (sudo make install)
#   macOS : Cocoa (NS) toolkit, produces Emacs.app → /Applications
#
# Supports: macOS (Homebrew), Debian/Ubuntu (apt), Fedora/RHEL (dnf), Arch (pacman).
#
# Usage:
#   bash build-emacs.sh [--version 30.2] [--src DIR] [--native aot|yes|no]
#                       [--gui ns|pgtk|x11] [--yes]
#
# Env overrides: EMACS_VER, SRC_ROOT, NATIVE_COMP, EMACS_GUI
# Time: ~20–40 min (AOT native-compilation recompiles all bundled elisp).
#
set -euo pipefail

# ─── Config (override via env or flags) ────────────────────────────────────────
EMACS_VER="${EMACS_VER:-30.2}"
SRC_ROOT="${SRC_ROOT:-$HOME/src}"
NATIVE_COMP="${NATIVE_COMP:-aot}"   # aot | yes | no
EMACS_GUI="${EMACS_GUI:-}"          # ns | pgtk | x11 (auto-selected per platform if empty)
ASSUME_YES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) EMACS_VER="$2"; shift 2 ;;
    --src)     SRC_ROOT="$2"; shift 2 ;;
    --native)  NATIVE_COMP="$2"; shift 2 ;;
    --gui)     EMACS_GUI="$2"; shift 2 ;;
    --yes|-y)  ASSUME_YES=1; shift ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'Unknown option: %s (try --help)\n' "$1" >&2; exit 1 ;;
  esac
done

SRC="$SRC_ROOT/emacs-$EMACS_VER"
OS=$(uname -s)

# ─── Logging ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'; DIM='\033[2m'
GREEN='\033[38;2;152;190;101m'; BLUE='\033[38;2;81;175;239m'
YELLOW='\033[38;2;236;190;123m'; RED='\033[38;2;255;108;107m'; RESET='\033[0m'
info()    { printf "${BLUE}  ${RESET} %s\n" "$*"; }
success() { printf "${GREEN}  ${RESET} %s\n" "$*"; }
warn()    { printf "${YELLOW}  ${RESET} %s\n" "$*"; }
die()     { printf "${RED}  ${RESET} %s\n" "$*" >&2; exit 1; }
header()  { printf "\n${BOLD}%s${RESET}\n" "$*"; }

confirm() {
  (( ASSUME_YES )) && return 0
  [[ -t 0 ]] || return 0   # non-interactive (piped/CI): proceed without prompting
  local _
  read -r -p ">>> $1 [Enter to continue, Ctrl-C to abort] " _
}

# ─── Build dependencies ─────────────────────────────────────────────────────────
install_deps_macos() {
  header "Build dependencies — Homebrew"
  command -v brew &>/dev/null || die "Homebrew not found. Install from https://brew.sh"
  info "Installing brew packages..."
  brew install autoconf automake texinfo pkg-config gnutls \
    libgccjit tree-sitter librsvg jansson \
    libxml2 jpeg-turbo libtiff giflib webp libpng \
    harfbuzz cairo gmp
  success "Dependencies installed"
}

install_deps_debian() {
  header "Build dependencies — apt  [sudo, network]"
  # build-dep needs source repos; enable deb-src on the modern (deb822) layout.
  if ! grep -rqs 'deb-src' /etc/apt/sources.list.d/ /etc/apt/sources.list; then
    if [[ -f /etc/apt/sources.list.d/ubuntu.sources ]]; then
      info "Enabling deb-src in ubuntu.sources..."
      sudo sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
    fi
  fi
  sudo apt-get update
  local gccv; gccv="$(gcc -dumpversion | cut -d. -f1)"
  if ! sudo apt-get build-dep -y emacs; then
    warn "build-dep unavailable; installing an explicit dependency list..."
    sudo apt-get install -y \
      build-essential autoconf automake texinfo pkg-config wget git xz-utils \
      libgtk-3-dev libgnutls28-dev libxml2-dev libjansson-dev libncurses-dev \
      "libgccjit-${gccv}-dev" \
      librsvg2-dev libpng-dev libjpeg-dev libtiff-dev libgif-dev libwebp-dev \
      libxpm-dev libharfbuzz-dev libcairo2-dev libx11-dev libxft-dev \
      libsqlite3-dev libgmp-dev libtree-sitter-dev
  fi
  # native-comp needs libgccjit even when build-dep omits it.
  sudo apt-get install -y "libgccjit-${gccv}-dev" librsvg2-dev libtree-sitter-dev \
    || sudo apt-get install -y libgccjit-14-dev libgccjit-13-dev librsvg2-dev libtree-sitter-dev
  success "Dependencies installed"
}

install_deps_fedora() {
  header "Build dependencies — dnf  [sudo, network]"
  sudo dnf install -y dnf-plugins-core
  if ! sudo dnf builddep -y emacs; then
    warn "builddep unavailable; installing an explicit dependency list..."
    sudo dnf install -y \
      @development-tools autoconf automake texinfo pkgconf-pkg-config wget git xz \
      gtk3-devel gnutls-devel libxml2-devel jansson-devel ncurses-devel \
      libgccjit-devel \
      librsvg2-devel libpng-devel libjpeg-turbo-devel libtiff-devel giflib-devel libwebp-devel \
      libXpm-devel harfbuzz-devel cairo-devel libX11-devel libXft-devel \
      sqlite-devel gmp-devel libtree-sitter-devel
  fi
  # native-comp + svg are easy to miss via builddep — ensure them.
  sudo dnf install -y libgccjit-devel librsvg2-devel libtree-sitter-devel || true
  success "Dependencies installed"
}

install_deps_arch() {
  header "Build dependencies — pacman  [sudo, network]"
  sudo pacman -Sy --noconfirm --needed \
    base-devel autoconf texinfo wget git xz \
    gtk3 gnutls libxml2 jansson ncurses \
    libgccjit \
    librsvg libpng libjpeg-turbo libtiff giflib libwebp \
    libxpm harfbuzz cairo libx11 libxft \
    sqlite gmp tree-sitter
  success "Dependencies installed"
}

# ─── Source ─────────────────────────────────────────────────────────────────────
fetch_source() {
  header "Source — emacs-$EMACS_VER"
  if [[ -d "$SRC" && -f "$SRC/configure" ]]; then
    success "Source already present at $SRC"
    return
  fi
  mkdir -p "$SRC_ROOT"
  local tarball="$SRC_ROOT/emacs-$EMACS_VER.tar.xz"
  if [[ ! -f "$tarball" ]]; then
    info "Downloading emacs-$EMACS_VER.tar.xz from a GNU mirror..."
    curl -fL "https://ftpmirror.gnu.org/gnu/emacs/emacs-$EMACS_VER.tar.xz" -o "$tarball"
  fi
  info "Extracting..."
  tar -C "$SRC_ROOT" -xf "$tarball"
  [[ -d "$SRC" ]] || die "Extraction did not produce $SRC"
  success "Source ready at $SRC"
}

# ─── Configure / build ────────────────────────────────────────────────────────
configure_emacs() {
  header "Configure (clean slate)"
  cd "$SRC"
  make distclean 2>/dev/null || true   # toolkit/flag changes → reconfigure from scratch

  local -a flags=(
    --with-tree-sitter
    "--with-native-compilation=$NATIVE_COMP"
    --with-json
    --with-modules
  )

  # Honor a hand-built /usr/local tree-sitter (or other local libs) if present.
  local pkgpath="${PKG_CONFIG_PATH:-}"
  [[ -d /usr/local/lib/pkgconfig ]] && pkgpath="/usr/local/lib/pkgconfig${pkgpath:+:$pkgpath}"

  case "$EMACS_GUI" in
    ns)
      flags+=( --with-ns )
      local brewp; brewp="$(brew --prefix)"
      pkgpath="$brewp/lib/pkgconfig${pkgpath:+:$pkgpath}"
      # keg-only deps Emacs must find at configure time
      local keg
      for keg in libgccjit gnutls libxml2; do
        [[ -d "$brewp/opt/$keg/lib/pkgconfig" ]] && pkgpath="$brewp/opt/$keg/lib/pkgconfig:$pkgpath"
      done
      ;;
    pgtk)  flags+=( --with-pgtk ) ;;                    # pure GTK — native Wayland
    x11)   flags+=( --with-x --with-x-toolkit=gtk3 ) ;; # GTK3 under X11
    *)     die "Unknown GUI toolkit '$EMACS_GUI' (expected ns|pgtk|x11)" ;;
  esac

  info "configure ${flags[*]}"
  PKG_CONFIG_PATH="$pkgpath" ./configure "${flags[@]}"

  echo
  echo ">>> Confirm in the summary above: the window system/toolkit and rsvg/png/jpeg = yes"
  confirm "Press Enter to build"
}

build_emacs() {
  header "Build + install  (this can take 20–40 min)"
  cd "$SRC"
  if [[ "$EMACS_GUI" == "ns" ]]; then
    make -j"$(sysctl -n hw.ncpu)"
    info "Placing Emacs.app in /Applications..."
    rm -rf /Applications/Emacs.app
    cp -R nextstep/Emacs.app /Applications/Emacs.app
    success "Installed /Applications/Emacs.app"
  else
    make -j"$(nproc)"
    sudo make install
    success "Installed to /usr/local"
  fi
}

# ─── Verify ─────────────────────────────────────────────────────────────────────
verify() {
  header "Verify"
  local emacs_bin
  if [[ "$EMACS_GUI" == "ns" ]]; then
    emacs_bin="/Applications/Emacs.app/Contents/MacOS/Emacs"
  else
    emacs_bin="/usr/local/bin/emacs"
  fi
  "$emacs_bin" -Q --batch --eval \
    '(progn (princ (format "version = %s\n" emacs-version))
            (princ (format "treesit = %s\n" (and (fboundp (quote treesit-available-p)) (treesit-available-p))))
            (princ (format "svg     = %s\n" (image-type-available-p (quote svg))))
            (princ (format "png     = %s\n" (image-type-available-p (quote png))))
            (princ (format "native  = %s\n" (and (fboundp (quote native-comp-available-p)) (native-comp-available-p))))
            (princ "features: ") (princ system-configuration-features) (terpri))'
  echo
  echo "Look for TREE_SITTER, NATIVE_COMP, RSVG, PNG, JPEG, GIF, TIFF, WEBP above."
  [[ "$EMACS_GUI" == "pgtk" ]] && echo "(PGTK build — renders natively on Wayland.)"
  [[ "$EMACS_GUI" != "ns" ]] && echo "Then run 'hash -r' (or open a new shell) and relaunch emacs."
}

# ─── Dispatch ────────────────────────────────────────────────────────────────────
main() {
  printf "${BOLD}build emacs${RESET}  ${DIM}v$EMACS_VER → $SRC${RESET}\n"
  # Default toolkit per platform (Fedora ships Wayland → pgtk). --gui overrides.
  case "$OS" in
    Darwin) install_deps_macos;  : "${EMACS_GUI:=ns}" ;;
    Linux)
      if   command -v apt-get &>/dev/null; then install_deps_debian; : "${EMACS_GUI:=x11}"
      elif command -v dnf     &>/dev/null; then install_deps_fedora; : "${EMACS_GUI:=pgtk}"
      elif command -v pacman  &>/dev/null; then install_deps_arch;   : "${EMACS_GUI:=x11}"
      else die "Unsupported Linux distro — install Emacs build deps manually."
      fi
      ;;
    *) die "Unsupported OS: $OS" ;;
  esac
  info "Toolkit: $EMACS_GUI"

  fetch_source
  configure_emacs
  build_emacs
  verify

  printf "\n${GREEN}${BOLD}Done.${RESET}\n"
}

main
