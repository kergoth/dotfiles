if [[ "$ZED_TERM" = true ]] && (( $+commands[zed] )); then
    export EDITOR="zed --wait"
    export VISUAL="$EDITOR"

    # Zed does not hard wrap commit messages, use vim
    if (( $+commands[nvim] )); then
        export GIT_EDITOR=nvim
    elif (( $+commands[vim] )); then
        export GIT_EDITOR=vim
    else
        export GIT_EDITOR=vi
    fi
fi
