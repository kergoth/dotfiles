if [[ -n "$TMUX" ]] || [[ -n "$ATT_SESSION" ]]; then
    for cmd in repo mr ssh scp code e dbitbake; do
    eval "
        function $cmd {
            update_env
            command $cmd "\$@"
        }
    "
    done
fi
