function hg-is-clean -d 'Return success if the current mercurial tree is clean (no changes in either index or working copy)'
    test (count (hg status)) = 0
end
