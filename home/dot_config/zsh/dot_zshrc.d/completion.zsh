zstyle ':completion:*' cache-path $XDG_CACHE_HOME/zsh/zcompcache

# matches case insensitive for lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# pasting with tabs doesn't perform completion
zstyle ':completion:*' insert-tab pending

# When set to "1", do not include "DWIM" suggestions in git-checkout
# completion (e.g., completing "foo" when "origin/foo" exists).
export GIT_COMPLETION_CHECKOUT_NO_GUESS=1

zstyle ':completion:*:*:git:*' user-commands fixup:'Create a fixup commit'

if (( $+commands[brew] )); then
    compdef adminbrew=brew 2>/dev/null
fi

if [[ -f "$fzfdir/../share/fzf/completion.zsh" ]]; then
    . "$fzfdir/../share/fzf/completion.zsh"
fi
