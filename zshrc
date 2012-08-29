# Environment {{{1
export DOTFILES=$HOME/.dotfiles
export INPUTRC=$HOME/.inputrc
export TERMINFO=$HOME/.terminfo
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache
export ACKRC=.ackrc

ZSH=$DOTFILES/oh-my-zsh
ZSH_CUSTOM=$DOTFILES/zsh

PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:$PATH

if [[ -n $commands[ruby] ]]; then
    rubydir=$(ruby -rubygems -e "puts Gem.user_dir" 2>/dev/null)
    if [ $? -eq 0 ]; then
        PATH=$rubydir/bin:$PATH
    fi
fi

fpath=($ZSH_CUSTOM/functions $fpath)

if [[ -z $HOSTNAME ]]; then
    if [[ -n $HOST ]]; then
        export HOSTNAME=$HOST
    else
        export HOSTNAME=$(hostname -s)
    fi
fi

export CVS_RSH=ssh
export CVSREAD=yes


export LC_MESSAGES=C
export LC_ALL

export LESS=FRX
export PAGER=less
export MANWIDTH=80

export VIRTUALENVWRAPPER_VIRTUALENV_ARGS=--no-site-packages=--distribute

# If we have a proxy config file, use it
if [[ -e ~/.proxy.pac ]]; then
    export auto_proxy=file://$HOME/.proxy.pac
fi

if [[ $OSTYPE =~ darwin && -n $commands[brew] ]]; then
    if [[ ! -e ~/.brewenv ]]; then
        brew --env >~/.brewenv
    fi
    . ~/.brewenv
fi

# Oh-my-zsh {{{1
ZSH_THEME=prose

# Comment this out to disable weekly auto-update checks
DISABLE_AUTO_UPDATE="true"

# Let tmux handle its own terminal titles
if [[ -n $TMUX ]]; then
    DISABLE_AUTO_TITLE="true"
fi

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

plugins=(git github mercurial fasd python pip history-substring-search zsh-syntax-highlighting osx brew)

source $ZSH/oh-my-zsh.sh

# Zsh options {{{1

# Don't share my shell history among zsh instances
unsetopt share_history

# Disable typo correction, the prompt just gets in the way
unsetopt correctall

# Aliases {{{1
alias lr="ls -thl"
alias ll="ls -hl"
alias la="ls -Ah"

if [[ $OSTYPE =~ darwin ]]; then
    alias ps='ps ux'
    if [[ -n $commands[dfc] ]]; then
        alias df="dfc -T"
    fi
else
    alias ps='ps fux'
    if [[ -n $commands[dfc] ]]; then
        alias df="dfc -T -q mount -p -rootfs"
    fi
fi

alias tmux='tmux -u2'
alias bback='ack --type=bitbake'
alias chrome='google-chrome'
alias t.py='command t.py --task-dir ~/Dropbox/Documents'
alias t='t.py --list tasks.txt'
alias h='t.py --list tasks-personal.txt'

# Editor {{{1
if [[ -n $commands[vim] ]]; then
    alias vi=vim

    export EDITOR=vim
else
    export EDITOR=vi
fi
export VISUAL=$EDITOR

# Keychain {{{1
if [[ -n $commands[keychain] ]]; then
    eval "$(keychain -q --eval $HOSTNAME 2>/dev/null)"
fi

# Hub {{{1
if [[ -n $commands[hub] ]]; then
    eval "$(hub alias -s)"
fi

# Autoload functions {{{1
for func in $ZSH_CUSTOM/functions/*; do
    autoload $(basename $func)
done

# vi:sts=4 sw=4 et fdm=marker fdl=0
