function prompt-hg -d 'Show status information about the current mercurial tree formatted for the shell prompt'
    if not is-hg
        return
    end

    printf (hg branch)
end
