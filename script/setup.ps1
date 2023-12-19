Join-Path $PSScriptRoot "bootstrap.ps1" | Invoke-Expression

Set-ExecutionPolicy RemoteSigned -Scope Process -Force

# Set path to this dotfiles repo
$env:DOTFILES_DIR = $PSScriptRoot | Split-Path -Parent

if ($env:DOTFILES_DIR -ne "$env:USERPROFILE\.local\share\chezmoi") {
    if (-Not (Test-Path "$env:USERPROFILE\.local\share")) {
        New-Item -ItemType Directory -Path "$env:USERPROFILE\.local\share" | Out-Null
    }
    # Symlink to ~/.local/share/chezmoi to let chezmoi find the hook scripts
    New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.local\share\chezmoi" -Target $env:DOTFILES_DIR -Force | Out-Null
}

# Apply my dotfiles
Write-Output "Applying dotfiles"
chezmoi init --apply --source="$env:DOTFILES_DIR" kergoth/dotfiles-chezmoi
