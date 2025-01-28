if (( $+commands[lima] )); then
    export LIMA_SHELL=${LIMA_SHELL:-zsh}
    export LIMA_INSTANCE=${LIMA_INSTANCE:-docker}
fi
