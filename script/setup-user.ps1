if ($IsWindows) {
  # Get the ID and security principal of the current user account
  $myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal ($myWindowsID)

  # Get the security principal for the Administrator role
  $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

  if ($myWindowsPrincipal.IsInRole($adminRole)) {
    # We are running "as Administrator" - so relaunch as user

    $cmd = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoExit -WindowStyle Maximized -NoProfile -InputFormat None -ExecutionPolicy RemoteSigned -File " + $MyInvocation.MyCommand.Definition
    runas /trustlevel:0x20000 $cmd
    exit
  }

  # Use RemoteSigned execution policy for PowerShell. Needed for scoop, etc.
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

. $PSScriptRoot\..\scripts\common.ps1

& "$PSScriptRoot/bootstrap.ps1"

$env:DOTFILES_DIR = $PSScriptRoot | Split-Path -Parent

$os = $null
if ($IsLinux) {
  $os = "linux"
}
elseif ($IsMacOS) {
  $os = "macos"
}
elseif ($IsWindows) {
  $os = "windows"
}
if ($os) {
  Invoke-ChildScript "$PSScriptRoot\..\scripts\setup-user-$os.ps1"
}
if ($IsLinux) {
  if (Test-Path "/etc/os-release") {
    $release = Get-Content /etc/os-release | ConvertFrom-StringData
    $distro = $release.ID
    Invoke-ChildScript "$PSScriptRoot\..\scripts\setup-user-$distro.ps1"
  }
}

# Install PowerShell modules
if (Get-Command pwsh -ErrorAction SilentlyContinue) {
  pwsh -NoProfile $PSScriptRoot\..\scripts\install-pwsh-modules.ps1
} else {
  Write-Warning "PowerShell Core not installed"
}

Write-Output "User setup complete"
