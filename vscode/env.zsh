if [[ -n "$VSCODE_IPC_HOOK_CLI" ]]; then
    code_dir="$(dirname "$(command -v code)")"
    export VSCODE_SERVER_DIR=
    case "$code_dir" in
        "$HOME/.vscode-server/"*)
            VSCODE_SERVER_DIR="$(dirname "$code_dir")"
            ;;
    esac
    export VISUAL=codewait EDITOR=codewait
    export VSCODE_IPC_HOOK_CLI
fi
