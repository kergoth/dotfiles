if (( $+commands[nvim] )); then
    alias vim=nvim
    export EDITOR=nvim
elif (( $+commands[vim] )); then
    export EDITOR=vim
else
    export EDITOR=vi
fi

alias vi=vim
export VISUAL=$EDITOR
