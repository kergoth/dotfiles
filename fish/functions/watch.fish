if not set -q watch_interval
    set -g watch_interval 2
end

function watch
    if test (count $argv) -ne 1
        echo >&2 "Usage: watch command ARGS"
        return 1
    end

    set -l prefix (printf "Every %0.1fs: %s" $watch_interval "$argv")
    set -l width (echo $prefix | wc -c)
    set -l pad (eval expr $COLUMNS - $width + 1)
    set -l pattern (printf "%%s%%%ss\\n" $pad)

    while true
        clear
        set -l date (date +'%a %b %d %H:%m:%S %Y')
        printf $pattern $prefix $date
        eval $argv
        sleep $watch_interval
    end
end
