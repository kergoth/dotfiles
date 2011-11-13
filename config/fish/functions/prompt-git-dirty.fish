function prompt-git-dirty -d 'Echo a "*" if the git tree is dirty'
    if not git-is-clean
        printf '*'
    end
    return 0
end
