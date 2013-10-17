function array_join
    if test (count $argv) -gt 1
        set -l sep $argv[2]
    else
        set -l sep ''
    end
    _join "$sep" $$argv[1]
end
