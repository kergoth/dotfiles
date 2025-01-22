# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-NoProfile -NoExit -File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -Wait -FilePath (Get-Process -pid $pid).Path -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

. $PSScriptRoot\..\scripts\common.ps1

$ProgressPreference = 'SilentlyContinue' # Suppress progress bar (speed up downloading, especially on PowerShell 5)
$ConfirmPreference = 'None' # Suppress confirmation prompts

# Enable WSL, WSL 2, Sandbox
if (-Not (Test-InWindowsSandbox)) {
    # Enable WSL
    $feature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    if (-Not $feature) {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
    }

    # Enable Virtual Machine Platform for WSL 2
    $feature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    if (-Not $feature) {
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
    }

    # Enable Windows Sandbox
    $feature = Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM
    if (-Not $feature) {
        Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All -NoRestart
    }

    # Refresh $env:Path
    RefreshEnvPath
}

# Install winget
if (-Not (Get-Command winget -ErrorAction SilentlyContinue)) {
    $DownloadsFolder = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"

    Write-Output "Installing winget"

    if (-Not (Get-AppxPackage -Name Microsoft.VCLibs.140.00.UWPDesktop)) {
        $vclibs_url = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
        $vclibs = "$DownloadsFolder\" + (Split-Path $vclibs_url -Leaf)
        if (-Not (Test-Path $vclibs)) {
            Invoke-WebRequest -Uri $vclibs_url -OutFile $vclibs
        }
        Add-AppxPackage -Path $vclibs
    }

    if (-Not (Get-AppxPackage -Name Microsoft.UI.Xaml.2.7)) {
        $xaml = "$DownloadsFolder\Microsoft.UI.Xaml.2.7.appx"
        if (-Not (Test-Path "$xaml")) {
            $xaml_url = "https://globalcdn.nuget.org/packages/microsoft.ui.xaml.2.7.3.nupkg"
            $xamldl = "$DownloadsFolder\" + (Split-Path $xaml_url -Leaf)
            if (-Not (Test-Path "$xamldl.zip")) {
                Invoke-WebRequest -Uri $xaml_url -OutFile $xamldl.zip
            }

            $wingettemp = "$env:TEMP\winget"
            try {
                Expand-Archive "$xamldl.zip" -DestinationPath $wingettemp -Force
                Move-Item "$wingettemp\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx"  "$xaml"
            }
            finally {
                Remove-PossiblyMissingItem $wingettemp -Recurse -Force
            }
        }
        Add-AppxPackage -Path $xaml
    }

    $appinstaller_url = Get-GithubLatestRelease "microsoft/winget-cli" "Microsoft.DesktopAppInstaller"
    $appinstaller = "$DownloadsFolder\" + (Split-Path $appinstaller_url -Leaf)
    if (-Not (Test-Path $appinstaller)) {
        Invoke-WebRequest -Uri $appinstaller_url -OutFile $appinstaller
    }
    Add-AppxPackage -Path $appinstaller

    # Refresh $env:Path
    RefreshEnvPath
}

if (-Not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    winget install --disable-interactivity --accept-source-agreements --accept-package-agreements --silent --no-upgrade --id Microsoft.PowerShell

    # Refresh $env:Path
    RefreshEnvPath
}

# Install WinGet packages
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

# Configuration
pwsh -NoProfile $PSScriptRoot\windows\configure-admin.ps1
