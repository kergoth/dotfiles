if [[ -z "$SSH_AUTH_SOCK" ]] && (( $+commands[keychain] )); then
    eval "$(keychain --eval)"
fi
