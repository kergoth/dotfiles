# Executes commands at the start of an interactive session.
#
# vi:sts=4 sw=4 et fdm=marker fdl=0

if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Zsh options {{{1

# Show running time for commands which take longer than 10 seconds
export REPORTTIME=5

# Don't share my shell history among zsh instances
unsetopt sharehistory
unsetopt incappendhistory

# I don't use the ability to execute a directory to cd into it
unsetopt autocd

# I don't want relative path typos on a cd line to go to dirs in ~
unsetopt cdablevars

# Key bindings {{{1
autoload edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Aliases {{{1
if [[ -e $XDG_CONFIG_HOME/tmux/config ]]; then
    alias tmux="tmux -u2 -f $XDG_CONFIG_HOME/tmux/config"
else
    alias tmux="tmux -u2"
fi

if (( $+commands[hub] )); then
    eval "$(hub alias -s)"
fi

if (( $+commands[fasd] )); then
    fasd_cache="$XDG_DATA_HOME/fasd/env.zsh"
    if [[ ! -e $fasd_cache ]]; then
        mkdir -p $XDG_DATA_HOME/fasd
        fasd --init auto | sed 's,$,;,' >$fasd_cache
    fi
    source $fasd_cache
    unset $fasd_cache

    if [[ $OSTYPE =~ darwin* ]]; then
        alias o="a -e open"
    else
        alias o="a -e xdg-open"
    fi
    alias v='f -t -e vim -b viminfo'
fi
