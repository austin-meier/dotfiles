#!/usr/bin/env bash
# Bootstrap script for dotfiles in ~/.config
# Supports: macOS (Homebrew), Debian/Ubuntu, Fedora/RHEL, Arch
set -euo pipefail

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[38;2;152;190;101m'
BLUE='\033[38;2;81;175;239m'
YELLOW='\033[38;2;236;190;123m'
RED='\033[38;2;255;108;107m'
RESET='\033[0m'

info()    { printf "${BLUE}  ${RESET} %s\n" "$*"; }
success() { printf "${GREEN}  ${RESET} %s\n" "$*"; }
warn()    { printf "${YELLOW}  ${RESET} %s\n" "$*"; }
die()     { printf "${RED}  ${RESET} %s\n" "$*" >&2; exit 1; }
header()  { printf "\n${BOLD}%s${RESET}\n" "$*"; }

OS=$(uname -s)

# ─── Rust tooling ─────────────────────────────────────────────────────────────
# All Rust-based CLI tools are built from source with cargo so the same binaries
# (and versions) are reproduced on every platform, independent of how stale a
# given distro's packages are. Format: "crate:binary".
RUST_TOOLS=(
  "ripgrep:rg"
  "fd-find:fd"
  "eza:eza"
  "starship:starship"
  "zoxide:zoxide"
)

ensure_cargo() {
  if command -v cargo &>/dev/null; then
    success "cargo already installed"
    return
  fi
  info "Installing Rust toolchain via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
  success "Rust installed"
}

# A C compiler + linker are required to build crates from source. rustup does not
# provide them, so they must come from the system package manager first.
ensure_build_toolchain() {
  if command -v cc &>/dev/null || command -v gcc &>/dev/null || command -v clang &>/dev/null; then
    success "C toolchain present"
    return
  fi
  warn "No C compiler found — cargo builds will fail until one is installed."
}

cargo_install() {
  local crate="$1" bin="${2:-$1}"
  if command -v "$bin" &>/dev/null; then
    success "$bin already installed"
    return
  fi
  info "Building $crate via cargo (this can take a few minutes)..."
  # Prefer the locked dependency set; fall back to a normal resolve if the
  # crate ships no Cargo.lock or it conflicts with the installed toolchain.
  cargo install "$crate" --locked || cargo install "$crate"
  success "$bin installed"
}

install_rust_tools() {
  header "Rust tools (cargo)"
  ensure_build_toolchain
  ensure_cargo
  local entry crate bin
  for entry in "${RUST_TOOLS[@]}"; do
    crate="${entry%%:*}"; bin="${entry##*:}"
    cargo_install "$crate" "$bin"
  done
}

# ─── Zsh plugins (portable — git clone to XDG data dir) ──────────────────────
# Used on every Linux distro: apt/dnf packages are often stale and Arch installs
# plugins to a path .zshrc doesn't search, so a git clone is the portable choice.
install_zsh_plugins_git() {
  local plugin_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
  mkdir -p "$plugin_dir"
  for repo in \
    "zsh-users/zsh-autosuggestions" \
    "zsh-users/zsh-syntax-highlighting"
  do
    local name="${repo##*/}"
    if [[ -d "$plugin_dir/$name" ]]; then
      info "Updating $name..."
      git -C "$plugin_dir/$name" pull --ff-only -q
    else
      info "Cloning $name..."
      git clone --depth=1 "https://github.com/$repo" "$plugin_dir/$name"
    fi
    success "$name ready at $plugin_dir/$name"
  done
}

install_zsh_plugins() {
  header "Zsh plugins"
  if [[ "$OS" == "Darwin" ]]; then
    success "Installed via brew (zsh-autosuggestions, zsh-syntax-highlighting)"
    return
  fi
  install_zsh_plugins_git
}

# ─── Neovim (>= 0.10) ─────────────────────────────────────────────────────────
# apt ships 0.6–0.9 and dnf lagged until Fedora 41, so distro packages can't be
# trusted for >= 0.10. Use the official prebuilt tarball on Linux (same route for
# Ubuntu, Fedora, Arch) and brew on macOS. Skip if a new-enough nvim is present.
nvim_version_ok() {
  command -v nvim &>/dev/null || return 1
  local v major minor
  v=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
  major=${v%%.*}; minor=${v##*.}
  (( major > 0 )) || (( minor >= 10 ))
}

install_neovim_tarball() {
  local arch asset tmp
  case "$(uname -m)" in
    x86_64)        arch="x86_64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) warn "No Neovim tarball for $(uname -m) — install manually from neovim.io"; return 1 ;;
  esac
  asset="nvim-linux-${arch}.tar.gz"
  info "Downloading latest Neovim ($asset)..."
  tmp=$(mktemp -d)
  curl -fL "https://github.com/neovim/neovim/releases/latest/download/$asset" -o "$tmp/$asset"
  sudo rm -rf "/opt/nvim-linux-${arch}"
  sudo tar -C /opt -xzf "$tmp/$asset"
  sudo ln -sf "/opt/nvim-linux-${arch}/bin/nvim" /usr/local/bin/nvim
  rm -rf "$tmp"
  success "Neovim installed to /opt/nvim-linux-${arch} → /usr/local/bin/nvim"
}

install_neovim() {
  header "Neovim"
  if nvim_version_ok; then
    success "neovim $(nvim --version | head -1 | awk '{print $2}') already installed (>= 0.10)"
    return
  fi
  if [[ "$OS" == "Darwin" ]]; then
    info "Installing neovim via brew..."
    brew install neovim
    success "neovim installed"
  else
    install_neovim_tarball
  fi
}

# ─── Base packages (non-Rust) ─────────────────────────────────────────────────
# Each platform installs only what cargo cannot provide: the shell, git/curl,
# archive tools, fzf (Go, not Rust), and the C toolchain needed to build crates.
install_macos() {
  header "macOS — Homebrew"
  command -v brew &>/dev/null || die "Homebrew not found. Install from https://brew.sh"
  xcode-select -p &>/dev/null || warn "Xcode Command Line Tools missing — run: xcode-select --install"

  info "Installing brew packages..."
  brew install fzf zsh-autosuggestions zsh-syntax-highlighting
  success "Brew packages installed"
}

install_debian() {
  header "Debian/Ubuntu — apt"
  sudo apt-get update -q
  sudo apt-get install -y -q \
    zsh git curl \
    unzip tar gzip \
    fzf \
    build-essential pkg-config
  success "apt packages installed"
}

install_fedora() {
  header "Fedora/RHEL — dnf"
  sudo dnf install -y -q \
    zsh git curl \
    unzip tar gzip \
    fzf \
    gcc gcc-c++ make pkg-config
  success "dnf packages installed"
}

install_arch() {
  header "Arch — pacman"
  sudo pacman -Sy --noconfirm --needed \
    zsh git curl \
    unzip tar gzip \
    fzf \
    base-devel
  success "pacman packages installed"
}

# ─── zshenv ───────────────────────────────────────────────────────────────────
setup_zdotdir() {
  header "Shell bootstrap"
  local zshenv="$HOME/.zshenv"
  if grep -q 'ZDOTDIR' "$zshenv" 2>/dev/null; then
    success "ZDOTDIR already set in $zshenv"
  else
    info "Writing ZDOTDIR to $zshenv..."
    {
      echo 'export ZDOTDIR="$HOME/.config/zsh"'
      [[ -f "$HOME/.cargo/env" ]] && echo '[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"'
    } >> "$zshenv"
    success "ZDOTDIR set"
  fi

  set_default_shell
}

# Switch the login shell to zsh when it isn't already. chsh refuses any shell not
# listed in /etc/shells, so register it there first (needs sudo on Linux; macOS
# ships zsh pre-listed). Never fatal — fall back to a manual hint on failure.
set_default_shell() {
  local zsh_path
  zsh_path=$(command -v zsh) || { warn "zsh not found on PATH — cannot set default shell"; return; }

  if [[ "$SHELL" == */zsh ]]; then
    success "Default shell is already zsh"
    return
  fi

  if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
    info "Registering $zsh_path in /etc/shells..."
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  info "Setting default shell to zsh (you may be prompted for your password)..."
  if chsh -s "$zsh_path"; then
    success "Default shell set to zsh — restart your session to apply"
  else
    warn "Could not change shell automatically. Run manually: chsh -s $zsh_path"
  fi
}

# ─── Fonts ────────────────────────────────────────────────────────────────────
check_fonts() {
  header "Fonts"
  warn "Nerd Font required for icons in eza, starship, and WezTerm tabs."
  warn "Recommended: JetBrainsMono Nerd Font — https://www.nerdfonts.com/font-downloads"
  if [[ "$OS" == "Darwin" ]]; then
    info "Install via brew: brew install --cask font-jetbrains-mono-nerd-font"
  fi
}

# ─── Secrets reminder ────────────────────────────────────────────────────────
secrets_reminder() {
  header "Secrets"
  if [[ -f "$HOME/.config/zsh/secrets.zsh" ]]; then
    warn "~/.config/zsh/secrets.zsh exists — ensure it is excluded from any git repo."
    warn "Add it to your dotfiles .gitignore: echo 'zsh/secrets.zsh' >> ~/.config/.gitignore"
  fi
}

# ─── Dispatch ────────────────────────────────────────────────────────────────
main() {
  printf "${BOLD}dotfiles install${RESET}  ${DIM}~/.config${RESET}\n"

  case "$OS" in
    Darwin) install_macos ;;
    Linux)
      if   command -v apt-get &>/dev/null; then install_debian
      elif command -v dnf     &>/dev/null; then install_fedora
      elif command -v pacman  &>/dev/null; then install_arch
      else die "Unsupported Linux distro — install tools manually (see README.md)"
      fi
      ;;
    *) die "Unsupported OS: $OS" ;;
  esac

  install_rust_tools
  install_zsh_plugins
  install_neovim
  setup_zdotdir
  check_fonts
  secrets_reminder

  printf "\n${GREEN}${BOLD}Done.${RESET} Open a new shell or: ${DIM}exec zsh${RESET}\n"
}

main "$@"
