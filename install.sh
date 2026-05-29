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

# ─── Rust / Cargo ─────────────────────────────────────────────────────────────
ensure_cargo() {
  if command -v cargo &>/dev/null; then
    success "cargo already installed"
    return
  fi
  info "Installing Rust toolchain..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  source "$HOME/.cargo/env"
  success "Rust installed"
}

cargo_install() {
  local crate="$1" bin="${2:-$1}"
  if command -v "$bin" &>/dev/null; then
    success "$bin already installed"
  else
    info "Installing $crate via cargo..."
    cargo install "$crate" --locked 2>/dev/null || cargo install "$crate"
    success "$bin installed"
  fi
}

# ─── Zsh plugins (portable — git clone to XDG data dir) ──────────────────────
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

# ─── macOS ────────────────────────────────────────────────────────────────────
install_macos() {
  header "macOS — Homebrew"
  command -v brew &>/dev/null || die "Homebrew not found. Install from https://brew.sh"

  info "Installing brew packages..."
  brew install eza ripgrep fzf \
    zsh-autosuggestions zsh-syntax-highlighting
  success "Brew packages installed"

  header "Cargo tools"
  ensure_cargo
  cargo_install fd-find fd
  cargo_install starship starship
  cargo_install zoxide zoxide
}

# ─── Debian / Ubuntu ──────────────────────────────────────────────────────────
install_debian() {
  header "Debian/Ubuntu — apt"
  sudo apt-get update -q
  sudo apt-get install -y -q \
    zsh git curl \
    ripgrep fd-find fzf
  success "apt packages installed"

  # Debian names the binary fdfind — create a local shim
  if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    success "fd → fdfind shim created at ~/.local/bin/fd"
  fi

  header "Zsh plugins"
  install_zsh_plugins_git

  header "Cargo tools"
  ensure_cargo
  cargo_install eza eza
  cargo_install starship starship
  cargo_install zoxide zoxide
}

# ─── Fedora / RHEL ────────────────────────────────────────────────────────────
install_fedora() {
  header "Fedora/RHEL — dnf"
  sudo dnf install -y -q \
    zsh git curl \
    ripgrep fd-find fzf
  success "dnf packages installed"

  header "Zsh plugins"
  install_zsh_plugins_git

  header "Cargo tools"
  ensure_cargo
  cargo_install eza eza
  cargo_install starship starship
  cargo_install zoxide zoxide
}

# ─── Arch ─────────────────────────────────────────────────────────────────────
install_arch() {
  header "Arch — pacman"
  sudo pacman -Sy --noconfirm --needed \
    zsh git curl \
    ripgrep fd fzf eza starship zoxide \
    zsh-autosuggestions zsh-syntax-highlighting
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

  if [[ "$SHELL" != */zsh ]]; then
    warn "Default shell is $SHELL — switch to zsh with: chsh -s \$(which zsh)"
  else
    success "Default shell is already zsh"
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

  setup_zdotdir
  check_fonts
  secrets_reminder

  printf "\n${GREEN}${BOLD}Done.${RESET} Open a new shell or: ${DIM}exec zsh${RESET}\n"
}

main "$@"
