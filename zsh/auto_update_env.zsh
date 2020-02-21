for cmd in repo mr ssh scp; do
eval "
    function $cmd {
        update_env
        command $cmd "\$@"
    }
"
done
