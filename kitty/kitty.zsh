if [[ "$TERM" = "xterm-kitty" ]] || [[ -n "$KITTY_WINDOW_ID" ]]; then
    # if [[ -n "$XDG_DATA_HOME/kitty-ssh-kitten/kitty/bin" ]]; then
    if [[ -z "$KITTY_INSTALLATION_DIR" ]] && [[ -n "$XDG_DATA_HOME/kitty-ssh-kitten" ]]; then
        export KITTY_INSTALLATION_DIR="$XDG_DATA_HOME/kitty-ssh-kitten"
    fi
    if [[ -n "$XDG_DATA_HOME/kitty-ssh-kitten/kitty/bin" ]]; then
        path=($path "$XDG_DATA_HOME/kitty-ssh-kitten/kitty/bin")
    fi

    if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
        export KITTY_SHELL_INTEGRATION="enabled"
        autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
        kitty-integration
        unfunction kitty-integration
    fi

    alias ssh="kitty +kitten ssh"
fi
