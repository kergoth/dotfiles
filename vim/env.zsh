if [[ -n $commands[mvim] ]]; then
    export EDITOR="mvim -v"
elif [[ -n $commands[vim] ]]; then
    export EDITOR=vim
else
    export EDITOR=vi
fi
export VISUAL=$EDITOR
