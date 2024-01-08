function RefreshEnvPath {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") `
        + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# Use RemoteSigned execution policy for PowerShell. Needed for scoop, etc.
Set-ExecutionPolicy RemoteSigned -Scope Process -Force

# Install chezmoi if necessary
if (-Not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
    if (-Not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Output "Installing scoop"
        Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
    }

    RefreshEnvPath

    Write-Output "Installing chezmoi"
    scoop install chezmoi
}

