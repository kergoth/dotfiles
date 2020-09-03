for cmd in repo mr ssh scp code e dbitbake; do
eval "
    function $cmd {
        update_env
        command $cmd "\$@"
    }
"
done
