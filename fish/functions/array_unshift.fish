function array_unshift
    set $argv[1] $argv[2..-1] $$argv[1]
end
