if [[ -z "$EDITOR" ]]; then
    if (( $+commands[nvim] )); then
        alias vim=nvim
        export EDITOR=nvim
    elif (( $+commands[vim] )); then
        export EDITOR=vim
    else
        export EDITOR=vi
    fi
fi

if (( $+commands[nvim] )); then
    alias vim=nvim
fi
if (( $+commands[vim] )); then
    alias vi=vim
fi
export VISUAL=$EDITOR
