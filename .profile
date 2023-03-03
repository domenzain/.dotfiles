# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi


# PATH configuration...
PATH="/usr/games:$PATH"
PATH="/usr/local/opt/ruby/bin:$PATH"
PATH="/usr/bin:$PATH"
PATH="/bin:$PATH"
PATH="/usr/local/sbin:$PATH"
PATH="/usr/sbin:$PATH"
PATH="/sbin:$PATH"
PATH="/usr/X11/bin:$PATH"
PATH="/usr/texbin:$PATH"
PATH="/opt/local/bin:$PATH"
PATH="/opt/local/sbin:$PATH"
PATH="/usr/local/texlive/2013/bin/x86_64-darwin:$PATH"
PATH="$HOME/bin:$PATH"
PATH="$HOME/.local/bin:$PATH"
PATH="$HOME/.cargo/bin:$PATH"
PATH="$HOME/.cabal/bin:$PATH"
PATH="$HOME/Library/Haskell/bin:$PATH"
PATH="$HOME/.emacs.d/layers/+window-management/exwm/files/:$PATH"
PATH="/usr/local/cuda/bin/:$PATH"
PATH="$HOME/.local/bin:$PATH"
PATH="$HOME/perl5/bin:$PATH"
PATH="/usr/local/bin:$PATH"
PATH="/usr/local/go/bin:$PATH"
PATH="$HOME/go/bin:$PATH"
PATH="$HOME/.config/nvm/versions/node/v18.14.0/bin:$PATH"
export PATH=$PATH

PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
PERL_MB_OPT="--install_base \"$HOME/perl5\""
PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
export PERL5LIB=$PERL5LIB
export PERL_LOCAL_LIB_ROOT=$PERL_LOCAL_LIB_ROOT
export PERL_MB_OPT=$PERL_MB_OPT
export PERL_MM_OPT=$PERL_MM_OPT
export NVM_PATH="$HOME/repos/tools/nvm"
export ARDUINO_PATH=/usr/local/arduino
export KALEIDOSCOPE_DIR="$HOME/repos/tools/kaleidoscope"
export FZF_BASE="$HOME/repos/tools/fzf"

GPG_TTY=$(tty)
export GPG_TTY
export SSH_AUTH_SOCK

export PATH="$HOME/.cargo/bin:$PATH"

export VIRTUALENVWRAPPER_PYTHON=$(which python3)
