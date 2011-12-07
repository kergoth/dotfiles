# This is useful, as set PATH chokes on nonexistent paths
function set_path -d 'Set the system PATH with the provided values'
    set -l path
    for dir in $argv
        if test -d $dir
            set path $path $dir
        end
    end
    set PATH $path
end
