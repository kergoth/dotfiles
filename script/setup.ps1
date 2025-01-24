. $PSScriptRoot\..\scripts\common.ps1

if ($IsWindows) {
  # Use RemoteSigned execution policy for PowerShell. Needed for scoop, etc.
  Set-ExecutionPolicy RemoteSigned -Scope Process -Force
}

& "$PSScriptRoot/bootstrap.ps1"

# Apply my dotfiles
Write-Output "Applying dotfiles"
chezmoi apply --keep-going
