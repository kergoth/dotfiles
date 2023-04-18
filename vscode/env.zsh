if [[ -n "$VSCODE_INJECTION" ]]; then
    code_bin="$(command -v code)"
    if [[ $? -ne 0 ]]; then
        code_bin="$(ls -1rt ~/.vscode-server/bin/*/bin/remote-cli/code | tail -n 1)"
        code_dir="$(dirname "$code_bin")"
        path=($code_dir $path)
    else
        code_dir="$(dirname "$code_bin")"
    fi
    if [[ -n "$code_bin" ]]; then
        export VSCODE_SERVER_DIR=
        case "$code_dir" in
            "$HOME/.vscode-server/"*)
                VSCODE_SERVER_DIR="$(dirname "$code_dir")"
                ;;
        esac
        export VISUAL=codewait EDITOR=codewait
        export GIT_MERGETOOL=vscode
    fi
    export VSCODE_INJECTION
fi
#export VSCODE_PORTABLE="$XDG_DATA_HOME"/vscode
