# ============================================================================
# Oh My Zsh core
# ============================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="alanpeabody"

# Completions & history
CASE_SENSITIVE="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="dd/mm/yyyy"

# Behavior tweaks
zstyle ':omz:update' mode auto      # auto-update Oh My Zsh
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_LS_COLORS="true"

# Plugins
plugins=(git)

source "$ZSH/oh-my-zsh.sh"

# ============================================================================
# Toolchain paths
# ============================================================================

# Quartus Prime Lite 20.1
export QUARTUS_ROOT="$HOME/intelFPGA_lite/20.1/quartus"

# CUDA toolkit
export CUDA_ROOT="/usr/local/cuda"

# FPGA and other tooling
export PATH="$QUARTUS_ROOT/bin:$CUDA_ROOT/bin:$PATH"
export PATH="$PATH:/home/Code/fpga_playground/icesugar/tools"   # iCESugar-nano FPGA
export PATH="/home/tem/.opencode/bin:$PATH"                    # opencode

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# ============================================================================
# Shell behavior & locale
# ============================================================================

export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='mvim'
fi

# Auto-attach to tmux for interactive shells
if command -v tmux >/dev/null 2>&1 && [[ -z "$TMUX" ]] && [[ -t 0 ]]; then
  tmux
fi

# ============================================================================
# Keybindings
# ============================================================================

# Scroll full screen before clearing so history stays visible
scroll-and-clear-screen() {
  printf '\n%.0s' {1..$LINES}
  zle clear-screen
}
zle -N scroll-and-clear-screen
bindkey '^l' scroll-and-clear-screen

# ============================================================================
# Git helpers
# ============================================================================

gitwip() {
  git commit -m "WIP: $*"
}

# Pretty repo summary via onefetch (run manually as `gitgreet`)
gitgreet() {
  if command -v onefetch >/dev/null 2>&1; then
    onefetch
  else
    echo "onefetch not installed"
  fi
}

# ============================================================================
# Python virtualenv helper
# ============================================================================

src() {
   local d=$PWD

  while :; do
    if [[ -f "$d/.venv/bin/activate" ]]; then
      . "$d/.venv/bin/activate"
      # If VIRTUAL_ENV is set, show it; otherwise show the directory
      if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "Activated: $VIRTUAL_ENV"
      else
        echo "Activated virtualenv in: $d/.venv"
      fi
      return 0
    fi

    # Stop once we've checked $HOME (or if we somehow hit /)
    if [[ "$d" = "$HOME" || "$d" = "/" ]]; then
      break
    fi

    # Go one directory up (zsh-specific shortcut for dirname)
    d=${d:h}
  done

  echo "No .venv found from $PWD up to ~"
  return 1
}

# ============================================================================
# Directory helpers
# ============================================================================

mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

# ============================================================================
# Programming quote-of-the-day (manual)
# ============================================================================

progq() {
  "$HOME/code/github.com/temataro/dotfiles/extra/lews-therin/humming.py"
}
progq

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

# Little helpers
alias wf='watch -n 0.1 -d'
alias wfls='watch -n 0.1 -d hat'

# ============================================================================
# zoxide (better cd)
# ============================================================================

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
