function psgrep
    set -l pids (pgrep -f $argv)
    if test $pids
        command ps u -p(pgrep -f $argv)
    end
end
