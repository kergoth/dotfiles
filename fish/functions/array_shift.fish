function array_shift
    echo $$argv[1][1]
    set $argv[1] $$argv[1][2..-1]
end
