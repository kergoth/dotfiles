function git-is-clean -d 'Return success if the current git tree is clean (no changes in either index or working copy)'
    git diff-index --quiet HEAD 2>/dev/null
end
