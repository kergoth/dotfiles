# Dracula colors via https://gist.github.com/umayr/8875b44740702b340430b610b52cd182
export FZF_DEFAULT_OPTS='
  --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9
  --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9
  --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
  --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
  --height 40% --multi --reverse
'
# For Zoxide
export _ZO_FZF_OPTS=$FZF_DEFAULT_OPTS

fzfdir=$(dirname "${commands[fzf]}")
if [[ -d "$fzfdir/../share/fzf" ]] && ! (( $+commands[atuin] )); then
    . "$fzfdir/../share/fzf/key-bindings.zsh"
fi

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
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
