# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="ys"
# ZSH_THEME="blinks"
ZSH_THEME="alanpeabody"
# Launch tmux
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  exec tmux
fi

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="dd/mm/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='mvim'
fi

#
# github.com/o2sh/onefetch
# Run onefetch whenever you cd into a repo folder.
# git repository greeter
last_repository=
check_directory_for_new_repository() {
	current_repository=$(git rev-parse --show-toplevel 2> /dev/null)
	
	if [ "$current_repository" ] && \
	   [ "$current_repository" != "$last_repository" ]; then
		onefetch
	fi
	last_repository=$current_repository
}
cd() {
	builtin cd "$@"
	check_directory_for_new_repository
}

# Gem of a find from the kitty config doc monstrosity
scroll-and-clear-screen() {
    printf '\n%.0s' {1..$LINES}
    zle clear-screen
}

zle -N scroll-and-clear-screen
bindkey '^l' scroll-and-clear-screen

# optional, greet also when opening shell directly in repository directory
# adds time to startup
check_directory_for_new_repository

#
# Compilation flags
export ARCHFLAGS="-arch x86_64"

# For iCESugar-nano FPGA
export PATH=$PATH:"/home/Code/fpga_playground/icesugar/tools"
# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

#  Use Zoxide
eval "$(zoxide init zsh)"

# mkdir and cd into a directory at the same time

function mkcd
{
	mkdir $1 && cd $1
}

function gitwip
{
	git commit -m "WIP: $1"
}


function source(){
    d="$PWD"; while [ "$d" != "$HOME" ] && [ "$d" != "/" ]; do
        for v in .venv venv env; do
            if [ -f "$d/$v/bin/activate" ]; then . "$d/$v/bin/activate";
                echo "Activated: $VIRTUAL_ENV";
            return;
            fi;
        done;
        d="$(dirname "$d")"; done; echo "No venv found up to ~"; 
    }


# Run a random chapter of 97 Things Every Programmer Should Know
# $HOME/dev/dotfiles/97-things/qotd.sh
$HOME/code/github.com/temataro/dotfiles/extra/lews-therin/humming.py
# ---- replacing ls with exa ---
alias hat="exa --group-directories-first -al --sort newest"
# alias hat='ls -lhat --color'
alias ll='ls -alF --color'
alias la='ls -lha --color'
alias l='ls -CF --color'
alias ls=l
alias hh='ls -lhat | head -n 6'
alias gls="git ls-files | xargs ls -lhat --color=auto"
# ---
alias c='clear'
alias sl='ls --color'
alias yt-dlp="yt-dlp --list-formats"
alias clera='clear'
alias lgg='lazygit'
alias vim='nvim'
alias vi='/usr/bin/vim'
alias brf='bladeRF-cli'
alias grc='gnuradio-companion'
alias ls='ls -lhat --color'
alias tmd='tmux detach'
alias tma='tmux attach'
alias celar='clear'
alias open='xdg-open'
alias clera='clear'
alias quarto=/opt/quarto/bin/quarto
alias docker=podman
alias zpool="sudo zpool"
alias gits='git status --column=always,nodense,auto'
alias grep='rg'
alias cat=batcat
alias sduo=sudo
alias zfs="sudo zfs"
alias szsh="source ~/.zshrc"
alias rm="rm -i"
alias wf="watch -n 0.1 -d"
alias wfls="watch -n 0.1 -d hat"
export LD_LIBRARY_PATH=/opt/cuda/lib64
export PATH=/home/tem/.local/bin:/opt/cuda/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/opt/quarto/bin/quarto:/home/tem/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/home/Code/fpga_playground/icesugar/tools:/home/Code/fpga_playground/icesugar/tools
. "$HOME/.local/bin/env"

export PATH="$PATH:/home/tem/.modular/bin"
