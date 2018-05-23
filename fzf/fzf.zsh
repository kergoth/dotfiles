. $DOTFILESDIR/fzf/themes/base16-tomorrow-night.config

if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd -c always -t f ""'
    export FZF_ALT_C_COMMAND='fd -c always -t d ""'
    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --ansi"
    # Use fd (https://github.com/sharkdp/fd) instead of the default find
    # command for listing path candidates.
    # - The first argument to the function ($1) is the base path to start traversal
    # - See the source code (completion.{bash,zsh}) for the details.
    _fzf_compgen_path() {
        fd --color always --hidden --follow --exclude ".git" . "$1"
    }

    # Use fd to generate the list for directory completion
    _fzf_compgen_dir() {
        fd --color always --type d --hidden --follow --exclude ".git" . "$1"
    }
else
    export FZF_DEFAULT_COMMAND='ag --color -g ""'
fi
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
