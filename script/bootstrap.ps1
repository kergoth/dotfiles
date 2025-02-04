function RefreshEnvPath {
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
     + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Set-UserOnlyFileAccess {
  param(
    [Parameter(Mandatory)] [string]$Pathname
  )
  # This does not use Get-Acl/Set-Acl, as Set-Acl requires the user to have
  # SeSecurityPrivilege, which should not be necessary for this operation.
  icacls $Pathname /grant ${env:USERNAME}:rw | Out-Null
  # Disable inheritance from folders
  icacls $Pathname /inheritance:d | Out-Null
  # Remove default groups (Authenticated Users, System, Administrators, Users)
  icacls $Pathname /remove *S-1-5-11 *S-1-5-18 *S-1-5-32-544 *S-1-5-32-545 | Out-Null
}

if ($IsWindows) {
  # Use RemoteSigned execution policy for PowerShell. Needed for scoop, etc.
  Set-ExecutionPolicy RemoteSigned -Scope Process -Force
}

# Install chezmoi if necessary
if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
  if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing scoop"
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
  }

  RefreshEnvPath

  scoop install chezmoi
}

# Set path to this dotfiles repo
$env:DOTFILES_DIR = $PSScriptRoot | Split-Path -Parent

$chezmoidir = "$env:USERPROFILE\.local\share\chezmoi"
if (($env:DOTFILES_DIR -ne $chezmoidir) -and (-not $IsWindows)) {
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
if (-Not (Test-Path "$env:USERPROFILE\.config\chezmoi\chezmoi.toml")) {
    Write-Host "Initializing dotfiles"
}
chezmoi init --source $env:DOTFILES_DIR
Set-UserOnlyFileAccess $env:USERPROFILE\.config\chezmoi\chezmoi.toml
