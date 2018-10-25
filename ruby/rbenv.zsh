export RBENV_ROOT="${RBENV_ROOT:-$XDG_DATA_HOME/rbenv}"
export PATH="$RBENV_ROOT/bin:$RBENV_ROOT/shims:$PATH"

if (( $+commands[rbenv] )); then
    for i in $RBENV_ROOT/completions/rbenv.zsh \
             ${HOMEBREW_PREFIX:-/opt/homebrew}/opt/rbenv/share/zsh/site-functions/rbenv.zsh; do
        if [[ -f $i ]]; then
            . $i
        fi
    done
fi
