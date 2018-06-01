export PYENV_ROOT="$XDG_DATA_HOME/pyenv"
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

if (( $+commands[pyenv] )); then
    eval "$(pyenv virtualenv-init - 2>/dev/null)"

    for i in $PYENV_ROOT/completions/pyenv.zsh \
             ${HOMEBREW_PREFIX:-/opt/homebrew}/opt/pyenv/share/zsh/site-functions/pyenv.zsh; do
        if [[ -f $i ]]; then
            . $i
        fi
    done

    # The python shared libraries are needed by vim for its python support
    if [[ $OSTYPE =~ darwin* ]]; then
        export PYTHON_CONFIGURE_OPTS="--enable-system-expat --enable-shared"
    else
        export PYTHON_CONFIGURE_OPTS="--enable-shared"
    fi
fi
