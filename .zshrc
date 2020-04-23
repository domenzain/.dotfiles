# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="tjkirch"
#fletcherm is a good theme...Also wedisagree

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"
export TERM=xterm-256color

# Uncomment following line if you want to disable autosetting terminal title.
DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(
cabal
cargo
docker
docker-compose
git
git-extras
pass
repo
rsync
tmux
virtualenvwrapper
)

source $ZSH/oh-my-zsh.sh

# Obtain common PATH
source $HOME/.profile

# Disable autocorrect.
unsetopt correct_all

# Use a sensible editor
export EDITOR='emacsclient -c'

# Useful aliases
alias cal=gcal
alias calw="gcal -K --iso-week-number=yes --starting-day=Monday"
alias top=htop
alias encrypt="gpg --encrypt --sign --armor --recipient ld@airinov.fr --recipient "
alias epoch="date +%s"
alias open=gnome-open
alias vim="$EDITOR"
alias emacs="$EDITOR"
alias azer='setxkbmap -rules evdev -model evdev -layout us -variant altgr-intl'
alias qwer='setxkbmap fr'
alias dots='/usr/bin/env git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
compdef dots=git
alias lt='ls -lthr'

# ===== History
setopt append_history # Allow multiple terminal sessions to all append to one zsh command history
setopt extended_history # save timestamp of command and duration
setopt inc_append_history # Add comamnds as they are typed, don't wait until shell exit
setopt hist_expire_dups_first # when trimming history, lose oldest duplicates first
setopt hist_ignore_dups # Do not write events to history that are duplicates of previous events
setopt hist_ignore_space # remove command line from history list when first character on the line is a space
setopt hist_find_no_dups # When searching history don't display results already cycled through twice
setopt hist_reduce_blanks # Remove extra blanks from each command line being added to history
setopt hist_verify # don't execute, just expand history
setopt share_history # imports new commands and appends typed commands to history


# Make sure other completions are available
fpath=(/usr/local/share/zsh-completions $fpath)
compinit
autoload -U bashcompinit && bashcompinit
