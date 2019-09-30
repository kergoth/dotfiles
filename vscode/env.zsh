if [[ -n "$SSH_AUTH_SOCK" ]] && (( $+commands[code] )); then
    code_dir="$(dirname "$(command -v code)")"
    export VSCODE_SERVER_DIR=
    case "$code_dir" in
        "$HOME/.vscode-server/"*)
            VSCODE_SERVER_DIR="$(dirname "$code_dir")"
            ;;
    esac
    export VISUAL=code EDITOR=code
fi
