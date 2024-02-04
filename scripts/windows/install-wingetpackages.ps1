. $PSScriptRoot\..\common.ps1

Install-ModuleIfNotInstalled Microsoft.WinGet.Client

Import-Module Microsoft.WinGet.Client

Install-WinGetPackage -Mode Silent -Id AgileBits.1Password | Out-Null
Install-WinGetPackage -Mode Silent -Id AntibodySoftware.WizTree | Out-Null
Install-WinGetPackage -Mode Silent -Id 7zip.7zip | Out-Null
Install-WinGetPackage -Mode Silent -Id Discord.Discord | Out-Null
Install-WinGetPackage -Mode Silent -Id Ditto.Ditto | Out-Null
Install-WinGetPackage -Mode Silent -Id GnuPG.Gpg4win | Out-Null
Install-WinGetPackage -Mode Silent -Id IRCCloud.IRCCloud | Out-Null
Install-WinGetPackage -Mode Silent -Id AutoHotkey.AutoHotkey | Out-Null
Install-WinGetPackage -Mode Silent -Id BiniSoft.WindowsFirewallControl | Out-Null
Install-winGetPackage -Mode Silent -Id egoist.devdocs-desktop | Out-Null
Install-winGetPackage -Mode Silent -Id gerardog.gsudo | Out-Null
Install-WinGetPackage -Mode Silent -Id Klocman.BulkCrapUninstaller | Out-Null
Install-WinGetPackage -Mode Silent -Id Microsoft.PowerShell | Out-Null
Install-WinGetPackage -Mode Silent -Id Microsoft.PowerToys | Out-Null
Install-WinGetPackage -Mode Silent -Id Microsoft.VisualStudio.2022.BuildTools | Out-Null
Install-WinGetPackage -Mode Silent -Id Microsoft.VisualStudioCode | Out-Null
Install-WinGetPackage -Mode Silent -Id Microsoft.WindowsTerminal | Out-Null
Install-WinGetPackage -Mode Silent -Id Notepad++.Notepad++ | Out-Null
Install-WinGetPackage -Mode Silent -Id QL-Win.QuickLook | Out-Null
Install-WinGetPackage -Mode Silent -Id SyncTrayzor.SyncTrayzor | Out-Null
Install-WinGetPackage -Mode Silent -Id Vivaldi.Vivaldi | Out-Null
Install-WinGetPackage -Mode Silent -Id VideoLAN.VLC | Out-Null

# SnipDo
Install-WinGetPackage -Mode Silent -Source msstore -Name SnipDo | Out-Null

# WiFi Analyzer
Install-WinGetPackage -Mode Silent -Source msstore -Id 9NBLGGH33N0N | Out-Null

# Visual Studio C++ Desktop Workload
Install-WinGetPackage -Mode Silent -Id Microsoft.VisualStudio.2022.Community -Override "--wait --quiet --add ProductLang En-us --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended" | Out-Null

# GUI Apps for work
Install-WinGetPackage -Mode Silent -Id Microsoft.Teams | Out-Null
Install-WinGetPackage -Mode Silent -Id PuTTY.PuTTY | Out-Null
Install-WinGetPackage -Mode Silent -Id Rufus.Rufus | Out-Null
