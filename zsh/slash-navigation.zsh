slash-backward-path() {
    local WORDCHARS="${WORDCHARS}/"
    zle backward-word
}
zle -N slash-backward-path

slash-forward-path() {
    local WORDCHARS="${WORDCHARS}/"
    zle forward-word
}
zle -N slash-forward-path

slash-backward-kill-path() {
    local WORDCHARS="${WORDCHARS}/"
    zle backward-kill-word
}
zle -N slash-backward-kill-path

# Default navigation/deletion goes by path components
WORDCHARS="${WORDCHARS:s@/@}"

# alt-shift-left navigates between entire paths
bindkey '^[[1;10D' slash-backward-path

# alt-shift-right navigates between entire paths
bindkey '^[[1;10C' slash-forward-path

# alt-backspace deletes an entire path
bindkey '\e^?' slash-backward-kill-path
