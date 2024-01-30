. $PSScriptRoot\..\scripts\common.ps1

if ($IsWindows) {
    # Use RemoteSigned execution policy for PowerShell. Needed for scoop, etc.
    Set-ExecutionPolicy RemoteSigned -Scope Process -Force
}

& "$PSScriptRoot/bootstrap.ps1"

# Set path to this dotfiles repo
$env:DOTFILES_DIR = $PSScriptRoot | Split-Path -Parent

if ($env:DOTFILES_DIR -ne "$env:USERPROFILE\.local\share\chezmoi") {
    if (-Not (Test-Path "$env:USERPROFILE\.local\share")) {
        New-Item -ItemType Directory -Path "$env:USERPROFILE\.local\share" | Out-Null
    }
    # Remove any existing symbolic link to ~/.local/share/chezmoi
    if (Test-Path "$env:USERPROFILE\.local\share\chezmoi") {
        if ((Get-Item "$env:USERPROFILE\.local\share\chezmoi").LinkType -eq 'SymbolicLink') {
            Remove-Item "$env:USERPROFILE\.local\share\chezmoi" -Force
        }
        else {
            throw "$env:USERPROFILE\.local\share\chezmoi exists and is not a symlink. Please remove it manually."
        }
    }
    # Symlink to ~/.local/share/chezmoi to let chezmoi find the hook scripts
    New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.local\share\chezmoi" -Target $env:DOTFILES_DIR -Force | Out-Null
}

# Apply my dotfiles
Write-Output "Applying dotfiles"
chezmoi init --apply --keep-going --source="$env:DOTFILES_DIR" kergoth/dotfiles
Set-UserOnlyFileAccess $env:USERPROFILE\.config\chezmoi\chezmoi.toml
