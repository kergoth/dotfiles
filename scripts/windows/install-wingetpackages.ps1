. $PSScriptRoot\..\common.ps1

function Install-WinGetPackageIfNotInstalled {
    param(
        [string]$Id = $null,
        [string]$Mode = "Interactive",
        [string]$Source = "winget",
        [string]$Name = $null,
        [string]$Override = $null
    )

    # Check if the package is already installed
    # Get-WinGetPackage with -Id or -Name is unreliable, so we use Where-Object instead.    
    if ($Id) {
        $packages = Get-WinGetPackage | Where-Object Id -eq $Id
    } elseif ($Name) {
        $packages = Get-WinGetPackage | Where-Object Name -eq $Name
    } else {
        throw "Id or Name must be specified"
    }
    if ($packages) {
        return
    }

    $arguments = @("-Source", "$Source")
    if ($Id) { $arguments += "-Id"; $arguments += "$Id"; $Name = $Id; }
    elseif ($Name) { $arguments += "-Name $Name" }
    if ($Override) { $arguments += "-Override $Override" }

    Write-Output "Installing package $Name"
    # Install-WinGetPackage -Mode $Mode @arguments -Verbose Continue -ErrorAction Stop
}

Install-ModuleIfNotInstalled Microsoft.WinGet.Client

Import-Module Microsoft.WinGet.Client

Install-WinGetPackageIfNotInstalled -Mode Silent -Id AgileBits.1Password | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id AntibodySoftware.WizTree | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id 7zip.7zip | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Discord.Discord | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Ditto.Ditto | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id GnuPG.Gpg4win | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id IRCCloud.IRCCloud | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id AutoHotkey.AutoHotkey | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id BiniSoft.WindowsFirewallControl | Out-Null
Install-winGetPackageIfNotInstalled -Mode Silent -Id egoist.devdocs-desktop | Out-Null
Install-winGetPackageIfNotInstalled -Mode Silent -Id gerardog.gsudo | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Klocman.BulkCrapUninstaller | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Microsoft.PowerShell | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Microsoft.PowerToys | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Microsoft.VisualStudio.2022.BuildTools | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Microsoft.VisualStudioCode | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Microsoft.WindowsTerminal | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Notepad++.Notepad++ | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id QL-Win.QuickLook | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id SyncTrayzor.SyncTrayzor | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Vivaldi.Vivaldi | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id VideoLAN.VLC | Out-Null

# SnipDo
Install-WinGetPackageIfNotInstalled -Mode Silent -Source msstore -Name SnipDo

# WiFi Analyzer
Install-WinGetPackageIfNotInstalled -Mode Silent -Source msstore -Id 9NBLGGH33N0N

# Visual Studio C++ Desktop Workload
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Microsoft.VisualStudio.2022.Community -Override "--wait --quiet --add ProductLang En-us --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended"

# GUI Apps for work
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Microsoft.Teams
Install-WinGetPackageIfNotInstalled -Mode Silent -Id PuTTY.PuTTY
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Rufus.Rufus
