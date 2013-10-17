function prompt-git -d 'Show status information about the current git tree formatted for the shell prompt'
    if not is-git
        return 0
    end

    set -l git
    if not test (command git config --get fish.hide)
        set git (git-abbrev-branch)
        if test "$git" = HEAD
            set git (command git rev-parse --short HEAD 2>/dev/null)
        end
    end
    printf $git
end
