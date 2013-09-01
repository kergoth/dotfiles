# Executes commands at the start of an interactive session.
#
# vi:sts=4 sw=4 et fdm=marker fdl=0

if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

export HISTFILE=${XDG_DATA_HOME}/zsh/history

# This is set here rather than in .zshenv as /etc/zsh/profile gets
# sourced after .zshenv, resulting in the PATH being overridden on
# some systems.

path=(
  $HOME/bin
  $ZDOTDIR/../scripts
  $ZDOTDIR/../external/bin
  /opt/homebrew/bin
  /opt/homebrew/share/python
  /usr/local/{bin,sbin}
  $path
)

setopt nullglob
for perlpath in $HOME/Library/Perl/*/bin; do
    path=($perlpath $path)
done
unsetopt nullglob

if [[ -n $GOPATH ]]; then
    path=($GOPATH/bin $path)
fi

# Zsh options {{{1

autoload -U url-quote-magic
zle -N self-insert url-quote-magic

# Kill correction, which seems to try to correct things which exist in my PATH
unsetopt correct

# Show running time for commands which take longer than 10 seconds
export REPORTTIME=5

# Don't share my shell history among zsh instances
unsetopt sharehistory
unsetopt incappendhistory

# I don't use the ability to execute a directory to cd into it
unsetopt autocd

# I don't want relative path typos on a cd line to go to dirs in ~
unsetopt cdablevars

# Don't auto-add variable stored paths to ~ list
unsetopt autonamedirs

# Key bindings {{{1
autoload edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Aliases {{{1
alias la="ls -GA"
alias smem='smem -k'
alias cd-last='cd "$(z -t -l -R|head -n 1)"'

if [[ -e $XDG_CONFIG_HOME/tmux/config ]]; then
    alias tmux="tmux -u2 -f $XDG_CONFIG_HOME/tmux/config"
else
    alias tmux="tmux -u2"
fi

alias mosh="perl -E 'print \"\e[?1005h\e[?1002h\"'; mosh"
alias go="goproj-go"

if [[ $OSTYPE =~ darwin ]]; then
    if (( $+commands[dfc] )); then
        alias df=dfc
        alias dfc="dfc -T"
    fi
    alias cpanm="cpanm --local-lib ~/Library/Perl/5.12"
    alias locate="mdfind -name"
else
    if (( $+commands[dfc] )); then
        alias df=dfc
        alias dfc="dfc -T -q mount -p -rootfs"
    fi
fi

if (( $+commands[pacman-color] )); then
    alias pacman='pacman-color'
fi

if (( $+commands[ag] )); then
    alias bbag="ag -G '\.(bb|bbappend|inc|conf)$'"
elif (( $+commands[ack] )); then
    alias ag=ack
    alias bback='ack --type=bitbake'
    alias bbag=bback
fi

if (( $+commands[hub] )); then
    eval "$(hub alias -s $SHELL)"
fi

if (( $+commands[fasd] )); then
    fasd_cache="$XDG_DATA_HOME/fasd/env.zsh"
    if [[ ! -e $fasd_cache ]]; then
        mkdir -p $XDG_DATA_HOME/fasd
        fasd --init auto | sed 's,$,;,' >$fasd_cache
    fi
    source $fasd_cache
    unset fasd_cache

    if [[ $OSTYPE =~ darwin* ]]; then
        alias o="a -e open"
    else
        alias o="a -e xdg-open"
    fi
    alias v='f -t -e vim -b viminfo'
fi
alias dtrx='dtrx -r --one=here'

prompt steeef
