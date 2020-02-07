if [[ "$OSTYPE" = WSL ]]; then
    alias pwsh=pwsh.exe
    if (( $+commands[pwsh.exe] )); then
        alias powershell=pwsh.exe
    else
        alias powershell=powershell.exe
    fi
fi
