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
    alias adb=adb.exe

    psrunas () {
        local cmd args
        cmd="$1"
        shift
        args="$(quote-args "$@"|sed -e "s/'/\\'/g; s/\"/'/g")"
        powershell.exe -c start "$cmd" -Verb runAs ${args:+-argumentlist "\"$args\""}
    }
    alias choco="psrunas choco"
fi
