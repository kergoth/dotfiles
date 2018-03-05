# Load pyenv on demand, to speed up shell startup
if [[ -d ~/.pyenv ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
fi

if (( $+commands[pyenv] )); then
    eval "$(pyenv init -)"

    for i in $(pyenv root)/completions/pyenv.zsh \
             ${HOMEBREW_PREFIX:-/Users/Shared/homebrew}/opt/pyenv/share/zsh/site-functions/pyenv.zsh; do
        if [[ -f $i ]]; then
            . $i
        fi
    done
fi
