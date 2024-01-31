. $PSScriptRoot\..\scripts\common.ps1

if ($IsWindows) {
    # Use RemoteSigned execution policy for PowerShell. Needed for scoop, etc.
    Set-ExecutionPolicy RemoteSigned -Scope Process -Force
}

& "$PSScriptRoot/bootstrap.ps1"

# Set path to this dotfiles repo
$env:DOTFILES_DIR = $PSScriptRoot | Split-Path -Parent

$chezmoidir = "$env:USERPROFILE\.local\share\chezmoi"
if ($env:DOTFILES_DIR -ne $chezmoidir) {
    if (-Not (Test-Path "$env:USERPROFILE\.local\share")) {
        New-Item -ItemType Directory -Path "$env:USERPROFILE\.local\share" | Out-Null
    }
    # Check for non-symbolic-link ~/.local/share/chezmoi
    if ((Test-Path $chezmoidir) -And ((Get-Item $chezmoidir).LinkType -ne 'SymbolicLink')) {
        throw "$chezmoidir exists and is not a symlink. Please remove it manually."
    }
    # Symlink to ~/.local/share/chezmoi to let chezmoi find the hook scripts
    New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.local\share\chezmoi" -Target $env:DOTFILES_DIR -Force | Out-Null
}

# Apply my dotfiles
Write-Output "Applying dotfiles"
chezmoi init
chezmoi apply --keep-going
Set-UserOnlyFileAccess $env:USERPROFILE\.config\chezmoi\chezmoi.toml
