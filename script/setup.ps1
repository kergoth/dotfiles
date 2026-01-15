. $PSScriptRoot\..\scripts\common.ps1

if ($IsWindows) {
  # Use RemoteSigned execution policy for PowerShell. Needed for scoop, etc.
  Set-ExecutionPolicy RemoteSigned -Scope Process -Force
}

& "$PSScriptRoot/bootstrap.ps1"

# First, run just the scripts to bootstrap secrets (age key, github token)
chezmoi apply --include=scripts

# Export the github token for externals if available
$tokenPath = "$env:USERPROFILE\.config\chezmoi_github_token"
if ((Test-Path $tokenPath) -and ((Get-Item $tokenPath).Length -gt 0)) {
    $env:CHEZMOI_GITHUB_ACCESS_TOKEN = (Get-Content $tokenPath -Raw).Trim()
}

# Apply my dotfiles
Write-Output "Applying dotfiles"
chezmoi apply --keep-going
