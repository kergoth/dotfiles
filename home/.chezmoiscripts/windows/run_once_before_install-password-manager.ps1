if (-Not (Get-Command op -ErrorAction SilentlyContinue)) {
    . $env:CHEZMOI_COMMAND_DIR\scripts\common.ps1

    if (-Not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
    }
    RefreshEnvPath

    scoop install 1password-cli
}
