if [[ $OSTYPE = WSL ]]; then
    alias cdw='cd "$USERPROFILE"'
    alias start="cmd.exe /c start"
    winver () {
        ( cd "$USERPROFILE" && cmd.exe /c ver )
    }

    if ! (( $+commands[xdg-open] )); then
        alias open=wsl-open
    fi

    alias cmd=cmd.exe
    alias wsl=wsl.exe
    alias choco=choco.exe
    alias adb=adb.exe
fi
