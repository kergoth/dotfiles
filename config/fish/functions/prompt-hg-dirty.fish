function prompt-hg-dirty -d 'Echo a "*" if the mercurial tree is dirty'
    if not hg-is-clean
        printf '*'
    end
    return 0
end
