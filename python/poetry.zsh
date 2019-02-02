if [ ! -e "$XDG_CACHE_HOME/zsh/completions/_poetry" ]; then
    mkdir -p "$XDG_CACHE_HOME/zsh/completions"
    poetry completions zsh >"$XDG_CACHE_HOME/zsh/completions/_poetry"
fi
