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
if [ -e $XDG_CONFIG_HOME/tmux/config ]; then
    alias tmux="tmux -u2 -f $XDG_CONFIG_HOME/tmux/config"
else
    alias tmux="tmux -u2"
fi
