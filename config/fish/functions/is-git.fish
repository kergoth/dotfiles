function is-git
    if not have git
        return 1
    end

    env git rev-parse --git-dir ^/dev/null >/dev/null
end
