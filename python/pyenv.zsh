# Load pyenv on demand, to speed up shell startup
if [[ -d ~/.pyenv ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
fi

if (( $+commands[pyenv] )); then
    eval "$(pyenv init -)"
    compctl -K _pyenv pyenv
fi
