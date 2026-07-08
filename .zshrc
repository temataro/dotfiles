# ============================================================================
# zsh — antidote (plugins) + starship (prompt). Migrated off oh-my-zsh.
# Plugin list: ~/.zsh_plugins.txt   Prompt: ~/.config/starship.toml
# ============================================================================

# ----- History -----
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000                 # without this, zsh does NOT persist history
setopt EXTENDED_HISTORY        # record timestamps
setopt SHARE_HISTORY           # share history across running shells
setopt HIST_IGNORE_DUPS        # drop consecutive duplicates
setopt HIST_IGNORE_SPACE       # ignore commands that start with a space
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY

# ----- Shell behavior -----
bindkey -e                     # emacs keymap. REQUIRED: EDITOR=vim otherwise
                               # makes zsh auto-select vi-mode and breaks ^l/^x^e
setopt AUTO_CD                 # `foo/` == `cd foo/`
setopt INTERACTIVE_COMMENTS    # allow `# comments` at the interactive prompt
setopt NO_BEEP
CASE_SENSITIVE=true            # (informational; default zsh completion is case-sensitive)

# ============================================================================
# Toolchain paths
# ============================================================================
export QUARTUS_ROOT="$HOME/intelFPGA_lite/20.1/quartus"   # Quartus Prime Lite 20.1
export CUDA_ROOT="/usr/local/cuda"                         # CUDA toolkit
export PATH="$QUARTUS_ROOT/bin:$CUDA_ROOT/bin:$PATH"
export PATH="$PATH:/home/Code/fpga_playground/icesugar/tools"   # iCESugar-nano FPGA
export PATH="/home/tem/.opencode/bin:$PATH"                    # opencode
export PATH="$HOME/.local/bin:$PATH"                           # uv tools, starship, claude
export ARCHFLAGS="-arch x86_64"

# ============================================================================
# Locale & editor
# ============================================================================
export LANG=en_US.UTF-8
export EDITOR='vim'

# ============================================================================
# Custom ZLE widgets & keybindings
# (defined before plugins so syntax-highlighting, loaded last, wraps them)
# ============================================================================
# Scroll a full screen before clearing so scrollback history stays visible
scroll-and-clear-screen() {
  printf '\n%.0s' {1..$LINES}
  zle clear-screen
}
zle -N scroll-and-clear-screen
bindkey '^l' scroll-and-clear-screen

# Edit the current command line in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

# ============================================================================
# Plugins (antidote)
# ============================================================================
if [[ ! -e $HOME/.antidote ]]; then        # bootstrap on a fresh machine
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
fi
source "$HOME/.antidote/antidote.zsh"
antidote load                              # reads ~/.zsh_plugins.txt

# ============================================================================
# Completion (after antidote has extended $fpath)
# ============================================================================
autoload -Uz compinit
() {
  local dump="$HOME/.zcompdump"
  local -a fresh=( ${dump}(Nmh-20) )       # dump modified < 20h ago?
  if (( $#fresh )); then
    compinit -C -d "$dump"                 # fast path: skip the security audit
  else
    compinit -d "$dump"                    # rebuild (also handles first run)
  fi
}
# compile the dump in the background so the next startup is faster
{ zcd="$HOME/.zcompdump"; [[ -s $zcd && ( ! -s $zcd.zwc || $zcd -nt $zcd.zwc ) ]] && zcompile "$zcd" } &!

zstyle ':completion:*' menu select         # arrow-key completion menu

# ============================================================================
# Prompt (starship)
# ============================================================================
eval "$(starship init zsh)"

# ============================================================================
# zoxide (better cd)
# ============================================================================
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# ============================================================================
# Auto-attach to tmux for interactive shells
# ============================================================================
if command -v tmux >/dev/null 2>&1 && [[ -z "$TMUX" ]] && [[ -t 0 ]]; then
  tmux
fi

# ============================================================================
# Git aliases (ported from the oh-my-zsh `git` plugin — common subset)
# ============================================================================
alias g='git'
alias gst='git status'
alias gss='git status -s'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gcmsg='git commit -m'
alias gca='git commit -v -a'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'
alias gf='git fetch'
alias gd='git diff'
alias gds='git diff --staged'
alias glog='git log --oneline --decorate --graph'
alias grhh='git reset --hard'
alias gsta='git stash push'
alias gstp='git stash pop'

# ============================================================================
# Git helpers
# ============================================================================
gitwip() { git commit -m "WIP: $*"; }
gitgreet() {  # pretty repo summary via onefetch (run manually)
  if command -v onefetch >/dev/null 2>&1; then onefetch; else echo "onefetch not installed"; fi
}

# ============================================================================
# Python virtualenv helper — walk up from $PWD to find and activate .venv
# ============================================================================
src() {
  local d=$PWD
  while :; do
    if [[ -f "$d/.venv/bin/activate" ]]; then
      . "$d/.venv/bin/activate"
      if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "Activated: $VIRTUAL_ENV"
      else
        echo "Activated virtualenv in: $d/.venv"
      fi
      return 0
    fi
    [[ "$d" = "$HOME" || "$d" = "/" ]] && break
    d=${d:h}
  done
  echo "No .venv found from $PWD up to ~"
  return 1
}

# ============================================================================
# Directory helper
# ============================================================================
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

# ============================================================================
# Aliases
# ============================================================================
# Listing
alias ls='ls -lhat --color'
alias ll='ls -alF --color'
alias la='ls -lha --color'
alias l='ls -CF --color'
alias sl='ls --color'
alias hh='ls -lhat | head -n 6'
alias gls="git ls-files | xargs ls -lhat --color=auto"
alias hat="exa --group-directories-first -al --sort newest"   # fancy ls (if exa installed)

# Common typos / quality-of-life
alias c='clear'
alias clera='clear'
alias celar='clear'
alias sduo='sudo'
alias szsh='source ~/.zshrc'

# Tools
alias yt-dlp='yt-dlp --list-formats'
alias lgg='lazygit'
alias vim='nvim'
alias vi='/usr/bin/vim'
alias brf='bladeRF-cli'
alias grc='gnuradio-companion'
alias tmd='tmux detach'
alias tma='tmux attach'
alias open='xdg-open'
alias quarto=/opt/quarto/bin/quarto
alias docker=podman
alias zpool='sudo zpool'
alias zfs='sudo zfs'
alias gits='git status --column=always,nodense,auto'
alias grep='rg'
alias cat='batcat'
alias rm='rm -i'
alias claude="/home/tem/code/github.com/temataro/dotfiles/claude-jail/claude-sbx"


# Little helpers
alias wf='watch -n 0.1 -d'
alias wfls='watch -n 0.1 -d ls -lhat'
alias dt="date +'%Y-%m-%d_%H-%M-%S'"

# ============================================================================
# Programming quote-of-the-day
# ============================================================================
progq() { "$HOME/code/github.com/temataro/dotfiles/extra/lews-therin/humming.py"; }
progq
