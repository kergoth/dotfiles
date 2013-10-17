function _join
    set -l output ""
    set -l first 1
    set -l sep $argv[1]
    set -e argv[1]

    for i in $argv
        if test $first = 1
            set first 0
            set output $i
        else
            set output "$output$sep$i"
        end
    end

    echo "$output"
end
