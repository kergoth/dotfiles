if [[ $OSTYPE = WSL ]]; then
    alias cdw='cd "$USERPROFILE"'
    alias start="cmd.exe /C START"

    if ! (( $+commands[xdg-open] )); then
        alias open=wsl-open
    fi

    alias choco=choco.exe
    alias adb=adb.exe
fi
