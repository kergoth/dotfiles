if [[ "$ZED_TERM" = true ]] && (( $+commands[zed] )); then
    export EDITOR="zed --wait"
    export VISUAL="$EDITOR"
fi
