if [[ $OSTYPE = WSL ]]; then
    winver () {
        ( cd "$USERPROFILE" && cmd.exe /c ver )
    }

    if ! (( $+commands[xdg-open] )); then
        alias open=wsl-open
    fi

    alias cdw='cd "$USERPROFILE"'
    alias start="cmd.exe /c start"
    alias cmd=cmd.exe
    alias wsl=wsl.exe
    alias adminwsl="psadmin wsl.exe"
    alias wt=wt.exe
    alias adminwt="psadmin 'shell:appsFolder\Microsoft.WindowsTerminal_8wekyb3d8bbwe!App'"
    alias adb=adb.exe

    alias trash=recycle

    if [[ -z "$WSL_IS_ADMIN" ]]; then
        if net.exe session >/dev/null 2>&1; then
            export WSL_IS_ADMIN=1
        else
            export WSL_IS_ADMIN=0
        fi
    fi
fi
