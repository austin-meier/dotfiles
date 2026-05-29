# ─── XDG ─────────────────────────────────────────────────────────────────────
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# ─── PATH ─────────────────────────────────────────────────────────────────────
eval "$(/opt/homebrew/bin/brew shellenv)"
path=(
  "$HOME/.cargo/bin"
  "$HOME/.local/bin"
  "$HOME/.bun/bin"
  "$HOME/.composer/vendor/bin"
  "$HOME/coding/clojure/tw"
  "/opt/homebrew/opt/postgresql@16/bin"
  "/opt/homebrew/opt/mysql-client/bin"
  $path
)
export PATH

# ─── Environment ──────────────────────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL='nvim'
export LANG='en_US.UTF-8'
export BUN_INSTALL="$HOME/.bun"
export OPENSSL_DIR="/opt/homebrew/Cellar/openssl@3/3.3.0"

# ─── History ──────────────────────────────────────────────────────────────────
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY SHARE_HISTORY HIST_VERIFY

# ─── Options ──────────────────────────────────────────────────────────────────
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt EXTENDED_GLOB GLOB_DOTS
setopt CORRECT NO_BEEP
setopt INTERACTIVE_COMMENTS

# ─── Completion ───────────────────────────────────────────────────────────────
autoload -Uz compinit
[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh"
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*:*:*:*:descriptions' format '%F{blue}  %d%f'
zstyle ':completion:*:warnings' format '%F{red}  no matches%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' squeeze-slashes true

# ─── Plugins ──────────────────────────────────────────────────────────────────
# Checks brew path (macOS) then XDG data path (Linux git-clone install)
_zsh_plugin_dirs=(
  "/opt/homebrew/share"
  "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
)
for _plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  for _dir in "${_zsh_plugin_dirs[@]}"; do
    [[ -r "$_dir/$_plugin/$_plugin.zsh" ]] && { source "$_dir/$_plugin/$_plugin.zsh"; break }
  done
done
unset _zsh_plugin_dirs _plugin _dir

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=1

# ─── eza ──────────────────────────────────────────────────────────────────────
alias ls='eza --icons=always --group-directories-first'
alias la='eza --icons=always --group-directories-first -a'
alias ll='eza --icons=always --group-directories-first -lah --git'
alias lt='eza --icons=always --tree --level=2 --group-directories-first'
alias lta='eza --icons=always --tree --level=3 -a --group-directories-first'

# ─── fd + fzf ─────────────────────────────────────────────────────────────────
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Doom-one palette — matches WezTerm color scheme
export FZF_DEFAULT_OPTS="
  --color=bg+:#282c34,bg:#1c1f24,border:#3f444a
  --color=fg:#bbc2cf,fg+:#bbc2cf,hl:#51afef,hl+:#46d9ff
  --color=prompt:#51afef,pointer:#46d9ff,marker:#98be65
  --color=spinner:#46d9ff,header:#5b6268,info:#98be65
  --border=rounded
  --prompt='  '
  --pointer='▶ '
  --marker='✓ '
  --height=45%
  --layout=reverse
  --info=inline
  --bind='ctrl-/:toggle-preview'
"

command -v fzf &>/dev/null && source <(fzf --zsh)

# ─── zoxide ───────────────────────────────────────────────────────────────────
command -v zoxide &>/dev/null && eval "$(zoxide init --cmd cd zsh)"

# ─── ripgrep ──────────────────────────────────────────────────────────────────
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"

# ─── Aliases ──────────────────────────────────────────────────────────────────
alias vim='nvim'
alias vi='nvim'
alias s='ssh'
alias obs='/Applications/Obsidian.app/Contents/MacOS/Obsidian'
alias pulldocs='git -C ~/Documents/lampblack pull'
alias docs='cd ~/Documents/lampblack'
alias nukecss='rm -rf ~/jam/var/cache/ ~/jam/var/generation/ ~/jam/var/page_cache/ ~/jam/var/view_preprocessed/ ~/jam/generated'
alias printid='node /Users/austin/coding/js/PrintQuest/bun/scripts/fix-order.js'
alias syncjar='rsync -azvh ~/coding/java/pdf/target/jam.jar www-data@austin:~/repos/jam/java/jam.jar --progress'
alias products='/opt/homebrew/bin/python3.11 /Users/austin/coding/jam/sql/get-products.py'

# ─── bun completions ──────────────────────────────────────────────────────────
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# ─── Secrets ──────────────────────────────────────────────────────────────────
[[ -f "$ZDOTDIR/secrets.zsh" ]] && source "$ZDOTDIR/secrets.zsh"

# ─── Prompt ───────────────────────────────────────────────────────────────────
command -v starship &>/dev/null && eval "$(starship init zsh)"
