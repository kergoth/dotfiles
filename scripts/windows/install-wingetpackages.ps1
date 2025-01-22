. $PSScriptRoot\..\common.ps1

Install-ModuleIfNotInstalled Microsoft.WinGet.Client

Import-Module Microsoft.WinGet.Client

Install-WinGetPackageIfNotInstalled -Mode Silent -Id AgileBits.1Password | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id AntibodySoftware.WizTree | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id 7zip.7zip | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Discord.Discord | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Ditto.Ditto | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id GnuPG.Gpg4win | Out-Null
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
