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

  # Use RemoteSigned execution policy for PowerShell.
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}
if ($os) {
  Invoke-ChildScript "$PSScriptRoot\..\scripts\setup-system-$os.ps1"
}
if ($IsLinux) {
  if (Test-Path "/etc/os-release") {
    $release = Get-Content /etc/os-release | ConvertFrom-StringData
    $distro = $release.ID
    Invoke-ChildScript "$PSScriptRoot\..\scripts\setup-system-$distro.ps1"
  }
}

Write-Output "System setup complete"
