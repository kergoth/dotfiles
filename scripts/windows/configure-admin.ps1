#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"

function Invoke-Sophia {
  . .\Functions.ps1

  if (-not (Test-InWindowsSandbox)) {
    try {
      CreateRestorePoint
    }
    catch {
    }
  }

  # Uninstall OneDrive
  OneDrive -Uninstall
  Remove-PossiblyMissingItem -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -Force

  # Associate *.txt to Notepad++
  if (Test-Path "$env:ProgramFiles\Notepad++\notepad++.exe") {
    Set-Association -ProgramPath "%ProgramFiles%\Notepad++\notepad++.exe" -Extension .txt -Icon "%ProgramFiles%\Notepad++\notepad++.exe,0"
  }

  DiagTrackService -Disable

  FeedbackFrequency -Never
  SigninInfo -Disable
  LanguageListAccess -Disable
  AdvertisingID -Disable
  WindowsWelcomeExperience -Hide
  WindowsTips -Enable
  SettingsSuggestedContent -Hide
  AppsSilentInstalling -Disable
  WhatsNewInWindows -Disable
  TailoredExperiences -Disable
  BingSearch -Disable
  CheckBoxes -Disable
  HiddenItems -Enable
  FileExtensions -Show
  MergeConflicts -Show
  OpenFileExplorerTo -ThisPC
  CortanaButton -Hide
  OneDriveFileExplorerAd -Hide
  FileTransferDialog -Detailed
  QuickAccessRecentFiles -Hide
  QuickAccessFrequentFolders -Hide
  TaskViewButton -Hide
  PeopleTaskbar -Hide
  WindowsInkWorkspace -Hide
  MeetNow -Hide
  NewsInterests -Disable
  UnpinTaskbarShortcuts -Shortcuts Edge,Store,Mail
  ControlPanelView -LargeIcons
  JPEGWallpapersQuality -Max
  RestartNotification -Show
  ShortcutsSuffix -Disable
  PrtScnSnippingTool -Enable
  StorageSense -Enable
  StorageSenseTempFiles -Enable
  StorageSenseFrequency -Month
  MappedDrivesAppElevatedAccess -Enable
  DeliveryOptimization -Disable

  New-ItemProperty -Path HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name AllowMUUpdateService -PropertyType DWord -Value 1 -Force
  try {
    UpdateMicrosoftProducts -Enable
  }
  catch [System.Runtime.InteropServices.COMException]{
    $null
  }
  ReservedStorage -Disable
  StickyShift -Disable
  Autoplay -Disable
  SaveRestartableApps -Enable
  RecentlyAddedApps -Hide
  AppSuggestions -Hide
  CortanaAutostart -Disable
  XboxGameBar -Disable
  XboxGameTips -Disable

  DismissMSAccount
  DismissSmartScreenFilter

  WindowsScriptHost -Disable
  MSIExtractContext -Show
  CABInstallContext -Show
  MultipleInvokeContext -Enable
  Errors
}

. $PSScriptRoot\..\common.ps1

# Start SSH agent and set the service to be started automatically
$agent = Get-Service -Name ssh-agent
if ($agent.Status -ne "Running") {
  $agent | Start-Service
}
if ($agent.StartType -ne "Automatic") {
  $agent | Set-Service -StartupType Automatic
}

# Enable Network Protection
if (-not (Test-Path -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows Defender")) {
  New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows Defender" -ItemType Directory -Force
}
if (-not (Test-Path -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard")) {
  New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard" -ItemType Directory -Force
}
if (-not (Test-Path -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection")) {
  New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection" -ItemType Directory -Force
}
New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection" -Name EnableNetworkProtection -PropertyType DWord -Value 1 -Force

# Enable Potentially Unwanted Applications Protection
if (-not (Test-Path -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows Defender")) {
  New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows Defender" -ItemType Directory -Force
}
if (-not (Test-Path -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine")) {
  New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" -ItemType Directory -Force
}
New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" -Name MpEnablePus -PropertyType DWord -Value 1 -Force

# Enable Defender Sandboxing
setx /M MP_FORCE_USE_SANDBOX 1

if (-not (Test-Path -Path "HKCU:\SOFTWARE\Microsoft\Windows Security Health")) {
  New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows Security Health" -ItemType Directory -Force
}
if (-not (Test-Path -Path "HKCU:\SOFTWARE\Microsoft\Windows Security Health\State")) {
  New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows Security Health\State" -ItemType Directory -Force
}

# Enable app sideloading
New-ItemProperty -Path HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowAllTrustedApps -Type DWord -Value 1 -Force

# Enable windows developer mode
New-ItemProperty -Path HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -Type DWord -Value 1 -Force

# Small icons in taskbar
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "TaskbarSmallIcons" -Type DWord -Value 1

# Minimize diagnostic data collection
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection -Name AllowTelemetry -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection -Name MaxTelemetryAllowed -PropertyType DWord -Value 1 -Force
New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack -Name ShowedToastAtLevel -PropertyType DWord -Value 1 -Force

# Disable Scheduled Tasks
[string[]]$CheckedScheduledTasks = @(
  # Collects program telemetry information if opted-in to the Microsoft Customer Experience Improvement Program
  "ProgramDataUpdater",

  # This task collects and uploads autochk SQM data if opted-in to the Microsoft Customer Experience Improvement Program
  "Proxy",

  # If the user has consented to participate in the Windows Customer Experience Improvement Program, this job collects and sends usage data to Microsoft
  "Consolidator",

  # The USB CEIP (Customer Experience Improvement Program) task collects Universal Serial Bus related statistics and information about your machine and sends it to the Windows Device Connectivity engineering group at Microsoft
  "UsbCeip",

  # The Windows Disk Diagnostic reports general disk and system information to Microsoft for users participating in the Customer Experience Program
  "Microsoft-Windows-DiskDiagnosticDataCollector"
)

$Tasks = Get-ScheduledTask | Where-Object -FilterScript { ($_.State -eq "Ready") -and ($_.TaskName -in $CheckedScheduledTasks) }
$Tasks | Disable-ScheduledTask

# Disable Error Reporting
Get-ScheduledTask -TaskName QueueReporting | Disable-ScheduledTask
New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name Disabled -PropertyType DWord -Value 1 -Force
Get-Service -Name WerSvc | Stop-Service -Force
Get-Service -Name WerSvc | Set-Service -StartupType Disabled

# System configuration via Sophia
$DownloadsFolder = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"

$windowsVersion = [System.Environment]::OSVersion.Version
if ($windowsVersion.Major -eq 10 -and $windowsVersion.Build -ge 22000) {
    $baseVersionString = "Sophia.Script.for.Windows.11"
} elseif ($windowsVersion.Major -eq 10) {
    $baseVersionString = "Sophia.Script.for.Windows.10"
} else {
    throw "Unsupported Windows version: $windowsVersion"
}
$powershellVersion = $PSVersionTable.PSVersion.Major
if ($powershellVersion -eq 5) {
    $powershellString = ""
} elseif ($powershellVersion -eq 7) {
    $powershellString = ".PowerShell.7"
} else {
    throw "Unsupported PowerShell version: $powershellVersion"
}
$sophia_url = Get-GithubLatestRelease "farag2/Sophia-Script-for-Windows" "$baseVersionString$powershellString"
$sophia = "$DownloadsFolder\" + (Split-Path $sophia_url -Leaf)
if (-not (Test-Path $sophia)) {
  Start-BitsTransfer $sophia_url -Destination $DownloadsFolder
}

$sophiadir = "$env:TEMP\sophia"
try {
  $cwd = Get-Location
  Write-Output "Configuring with Sophia Script"
  Expand-Archive $sophia -DestinationPath $sophiadir -Force
  Set-Location (Get-ChildItem -Path $sophiadir | Select-Object -First 1).FullName
  Invoke-Sophia
}
finally {
  Set-Location -Path $cwd
  Remove-Item $sophiadir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output "Admin configuration complete"
