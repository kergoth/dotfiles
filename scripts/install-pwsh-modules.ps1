# Via https://stackoverflow.com/a/56893689

. $PSScriptRoot\common.ps1

Write-Verbose "Installing PowerShell modules"
Install-ModuleIfNotInstalled DirColors
Install-ModuleIfNotInstalled Microsoft.WinGet.Client
Install-ModuleIfNotInstalled posh-alias
Install-ModuleIfNotInstalled PSFzf
Install-ModuleIfNotInstalled Recycle
