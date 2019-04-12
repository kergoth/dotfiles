if (( $+commands[vim] )); then
    export EDITOR=vim
else
    export EDITOR=vi
fi
export VISUAL=$EDITOR
