if [[ ! $OSTYPE =~ darwin* ]]; then
    export PYTHONUSERBASE="$XDG_DATA_HOME/.."
fi
if [[ -e "$XDG_CONFIG_HOME/python/pythonrc" ]]; then
    export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
fi
export PYTHON_HISTORY="$XDG_STATE_HOME/python_history"

export PYTHONWARNINGS=ignore:DEPRECATION

alias ptpython='ptpython "--config-dir=$XDG_DATA_HOME/ptpython"'

if (( $+commands[poetry] )) && [ ! -e "$XDG_CACHE_HOME/zsh/completions/_poetry" ]; then
    mkdir -p $XDG_CACHE_HOME/zsh/completions
    chmod 0700 $XDG_CACHE_HOME/zsh/completions
    poetry completions zsh >"$XDG_CACHE_HOME/zsh/completions/_poetry"
fi

export PIPX_HOME=$XDG_DATA_HOME/../pipx
