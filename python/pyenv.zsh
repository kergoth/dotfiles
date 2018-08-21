export PYENV_ROOT="${PYENV_ROOT:-$XDG_DATA_HOME/pyenv}"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

if (( $+commands[pyenv] )); then
    for i in $PYENV_ROOT/completions/pyenv.zsh \
             ${HOMEBREW_PREFIX:-/opt/homebrew}/opt/pyenv/share/zsh/site-functions/pyenv.zsh; do
        if [[ -f $i ]]; then
            . $i
        fi
    done
fi
