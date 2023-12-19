# When set to "1", do not include "DWIM" suggestions in git-checkout
# completion (e.g., completing "foo" when "origin/foo" exists).
export GIT_COMPLETION_CHECKOUT_NO_GUESS=1

zstyle ':completion:*:*:git:*' user-commands fixup:'Create a fixup commit'
