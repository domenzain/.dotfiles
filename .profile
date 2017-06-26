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
PATH="/usr/local/bin:$PATH"
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
export PATH=$PATH

export PATH="$HOME/.cargo/bin:$PATH"

GPG_TTY=$(tty)
export GPG_TTY
