function mkcd -d "cd to new directory"
    if test (count $argv) -ne 1
        echo >&2 "Usage: mkcd DIRECTORY"
        return 1
    end
    mkdir $argv
    cd $argv
end
