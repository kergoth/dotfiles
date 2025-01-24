function RefreshEnvPath {
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
     + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

if ($IsWindows) {
  # Use RemoteSigned execution policy for PowerShell. Needed for scoop, etc.
  Set-ExecutionPolicy RemoteSigned -Scope Process -Force
}

# Install chezmoi if necessary
if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
  if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Output "Installing scoop"
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
  }

  RefreshEnvPath

  Write-Output "Installing chezmoi"
  scoop install chezmoi
}

# Set path to this dotfiles repo
$env:DOTFILES_DIR = $PSScriptRoot | Split-Path -Parent

$chezmoidir = "$env:USERPROFILE\.local\share\chezmoi"
if ($env:DOTFILES_DIR -ne $chezmoidir) {
  if (-not (Test-Path "$env:USERPROFILE\.local\share")) {
    New-Item -ItemType Directory -Path "$env:USERPROFILE\.local\share" | Out-Null
  }
  # Check for non-symbolic-link ~/.local/share/chezmoi
  if ((Test-Path $chezmoidir) -and ((Get-Item $chezmoidir).LinkType -ne 'SymbolicLink')) {
    throw "$chezmoidir exists and is not a symlink. Please remove it manually."
  }
  # Symlink to ~/.local/share/chezmoi to let chezmoi find the hook scripts
  New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.local\share\chezmoi" -Target $env:DOTFILES_DIR -Force | Out-Null
}

# Init my dotfiles
Write-Output "Initializing dotfiles"
chezmoi init
Set-UserOnlyFileAccess $env:USERPROFILE\.config\chezmoi\chezmoi.toml
