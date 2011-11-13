function git-abbrev-branch -d 'Show branch name in abbreviated form'
    git rev-parse --abbrev-ref HEAD 2>/dev/null
end
