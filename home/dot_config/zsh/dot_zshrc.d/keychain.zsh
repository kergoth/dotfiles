if [[ -z "$SSH_AUTH_SOCK" ]] && (( $+commands[keychain] )); then
    eval "$(keychain --eval)"
    alias keychain='keychain --absolute --dir "${XDG_RUNTIME_DIR:-$XDG_DATA_HOME}"/keychain'
fi
