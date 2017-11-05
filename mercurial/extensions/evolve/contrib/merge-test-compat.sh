#!/bin/bash
set -euox pipefail

unset GREP_OPTIONS
NOTOPIC="--config experimental.topic-mode=ignore"

compatbranches=`hg branches --quiet | grep 'mercurial-' | grep -v ':' | sort -n --reverse`
prev='stable'
for branch in $compatbranches; do
    hg up $branch
    hg merge $prev
    hg commit -m "test-compat: merge $prev into $branch"
    prev=$branch
done

