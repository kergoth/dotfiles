# Fix SSH auth socket location so agent forwarding works with tmux and VS Code
if [ -n "$SSH_AUTH_SOCK" ] && [ -e "$HOME/.ssh/auth_sock" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/auth_sock" ]; then
    export SSH_AUTH_SOCK="$HOME/.ssh/auth_sock"
fi
