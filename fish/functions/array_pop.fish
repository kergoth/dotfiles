function array_pop
    echo $$argv[1][-1]
    set $argv[1] $$argv[1][1..-2]
end
