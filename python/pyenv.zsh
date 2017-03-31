# Load pyenv on demand, to speed up shell startup
if (( $+commands[pyenv] )); then
    export PATH="$HOME/.pyenv/shims:$PATH"

    pyenv () {
        eval "$(command pyenv init -)"
        pyenv "$@"
    }

    compctl -K _pyenv pyenv
    _pyenv () {
        eval "$(command pyenv init -)"
        _pyenv "$@"
    }
fi
