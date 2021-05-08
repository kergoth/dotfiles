zstyle ':completion:*' cache-path $XDG_CACHE_HOME/zsh/zcompcache

# matches case insensitive for lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# pasting with tabs doesn't perform completion
zstyle ':completion:*' insert-tab pending
