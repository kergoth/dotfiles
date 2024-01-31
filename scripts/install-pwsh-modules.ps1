# Via https://stackoverflow.com/a/56893689

. $PSScriptRoot\common.ps1

$ProgressPreference = 'SilentlyContinue' # Suppress progress bar (speed up downloading, especially on PowerShell 5)
$ConfirmPreference = 'None' # Suppress confirmation prompts

Write-Verbose "Installing PowerShell modules"
Install-ModuleIfNotInstalled DirColors
Install-ModuleIfNotInstalled Microsoft.WinGet.Client
Install-ModuleIfNotInstalled posh-alias
Install-ModuleIfNotInstalled PSFzf
Install-ModuleIfNotInstalled Recycle
