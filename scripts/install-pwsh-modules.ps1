# Via https://stackoverflow.com/a/56893689

. $PSScriptRoot\common.ps1

$ConfirmPreference = 'None' # Suppress confirmation prompts

Write-Verbose "Installing PowerShell modules"
Install-ModuleIfNotInstalled DirColors
Install-ModuleIfNotInstalled PSFzf

if ($IsWindows) {
  Install-ModuleIfNotInstalled Microsoft.WinGet.Client
}
