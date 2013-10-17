function abspath -d 'Return the absolute path when passed a relative or absolute path'
    for path in $argv
        if echo $path | grep -q '^/'
            echo $path
        else
            echo $PWD/$path
        end
    end
end
