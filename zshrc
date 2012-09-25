# Functions {{{1
abspath () {
    _path="$1"
    if [ -n "${_path##/*}" ]; then
        _path="$PWD/$1"
    fi
    echo "$_path"
}

# Environment {{{1
zshrc_path=$(dirname $(readlink $HOME/.zshrc))
export DOTFILES=$(abspath $zshrc_path)
if [ ! -d $DOTFILES ]; then
        DOTFILES=$HOME/$zshrc_path
fi
unset zshrc_path

export INPUTRC=$HOME/.inputrc
export TERMINFO=$HOME/.terminfo
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache
export ACKRC=.ackrc

ZSH=$DOTFILES/oh-my-zsh
ZSH_CUSTOM=$DOTFILES/zsh

path=($HOME/bin /usr/local/bin /usr/local/sbin $path)

if [[ -e ~/.local/bin ]]; then
    path=($HOME/.local/bin $path)
fi

if [[ -e ~/Library/Python ]]; then
    for i in ~/Library/Python/*; do
        if [[ -e "$i" ]]; then
            path=($i/bin $path)
        fi
    done
fi

if [[ -n $commands[ruby] ]]; then
    rubydir=$(ruby -rubygems -e "puts Gem.user_dir" 2>/dev/null)
    if [ $? -eq 0 ]; then
        path=($rubydir/bin $path)
    fi
fi

fpath=($ZSH_CUSTOM/functions $fpath)

if [[ -z $HOSTNAME ]]; then
    export HOSTNAME=$(hostname -s)
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
        brew --env | grep -v "^export PATH=" >~/.brewenv
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

# Show running time for commands which take longer than 10 seconds
export REPORTTIME=5

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

if [[ -n $commands[pacman-color] ]]; then
    alias pacman='pacman-color'
fi
alias smem='smem -k'
alias tmux='tmux -u2'
alias bback='ack --type=bitbake'
alias bbag="ag -G '\.(bb|bbappend|inc|conf)$'"
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
    eval "$(hub alias -s $SHELL)"
fi

# Autoload functions {{{1
for func in $ZSH_CUSTOM/functions/*; do
    autoload $(basename $func)
done

# Darwin environment.plist {{{1
if [[ $OSTYPE =~ darwin ]] && [[ -e ~/.MacOSX ]]; then
    sed -i -e "/<key>PATH<\/key>/{ n; s#^.*\$#	<string>$PATH</string>#; }" ~/.MacOSX/environment.plist
fi

# vi:sts=4 sw=4 et fdm=marker fdl=0
