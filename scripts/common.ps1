$ProgressPreference = 'SilentlyContinue' # Suppress progress bar (speed up downloading, especially on PowerShell 5)
$ConfirmPreference = 'None' # Suppress confirmation prompts

Add-Type -AssemblyName System.Web

if ($IsWindows) {
  Set-ExecutionPolicy RemoteSigned -Scope Process -Force

  Import-Module -Name BitsTransfer
}

function RefreshEnvPath {
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") `
     + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Remove-PossiblyMissingItem {
  try {
    Remove-Item @args -ErrorAction Stop
  }
  catch [System.Management.Automation.ItemNotFoundException]{
    $null
  }
}

# Add-EnvironmentVariableItem from Get-EnvironmentVariable.ps1
# Copyright (C) Frank Skare (stax76)
# MIT License
function Add-EnvironmentVariableItem {
  [CmdletBinding()]
  [Alias('aevi')]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [string]$Value,
    [switch]$Machine,
    [switch]$User,
    [switch]$End
  )

  process {
    $scope = 'Process'

    if ($Machine) { $scope = 'Machine' }
    if ($User) { $scope = 'User' }

    $var = [Environment]::GetEnvironmentVariable($Name,$scope)
    $tempItems = New-Object Collections.Generic.List[String]

    foreach ($i in ($var -split ';')) {
      $i = $i.Trim()

      if ($i -eq '' -or $i -eq $Value) {
        continue
      }

      $tempItems.Add($i)
    }

    $var = $tempItems -join ';'

    if ($End) {
      $var = $var + ';' + $Value
    }
    else {
      $var = $Value + ';' + $var
    }

    [Environment]::SetEnvironmentVariable($Name,$var,$scope)
  }
}

function Get-GithubLatestRelease {
  param(
    [Parameter(Mandatory)] [string]$project,# e.g. paintdotnet/release
    [Parameter(Mandatory)] [string]$pattern,# regex. e.g. install.x64.zip
    [switch]$prerelease
  )

  # Get all releases and then get the first matching release. Necessary because a project's "latest"
  # release according to Github might be of a different product or component than the one you're
  # looking for. Also, Github's 'latest' release doesn't include prereleases.
  $releases = Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$project/releases"
  $downloadUrl = $releases |
  Where-Object { $_.prerelease -eq $prerelease } |
  ForEach-Object { $_.assets } |
  Where-Object { $_.Name -match $pattern } |
  Select-Object -First 1 -ExpandProperty "browser_download_url"

  return $downloadUrl
}

# Detects if running inside a Windows sandbox or container.
# Based on https://stackoverflow.com/questions/43002803/detect-if-process-executes-inside-a-windows-container
function Test-InWindowsSandbox {
  $foundService = Get-Service -Name cexecsvc -ErrorAction SilentlyContinue
  return $null -ne $foundService
}

function Set-UserOnlyFileAccess {
  param(
    [Parameter(Mandatory)] [string]$Pathname
  )
  # This does not use Get-Acl/Set-Acl, as Set-Acl requires the user to have
  # SeSecurityPrivilege, which should not be necessary for this operation.
  icacls $Pathname /grant ${env:USERNAME}:rw | Out-Null
  # Disable inheritance from folders
  icacls $Pathname /inheritance:d | Out-Null
  # Remove default groups (Authenticated Users, System, Administrators, Users)
  icacls $Pathname /remove *S-1-5-11 *S-1-5-18 *S-1-5-32-544 *S-1-5-32-545 | Out-Null
}

# Set platform variables for use in PowerShell prior to 6.0.
function Get-PSPlatform {
  return [System.Environment]::OSVersion.Platform
}

function Install-ModuleIfNotInstalled (
  [string][Parameter(Mandatory = $true)] $moduleName,
  [string]$minimalVersion = $null
) {
  $module = Get-Module -Name $moduleName -ListAvailable | `
     Where-Object { $null -eq $minimalVersion -or $minimalVersion -lt $_.Version } | `
     Select-Object -Last 1
  if ($null -ne $module) {
    Write-Verbose ('Module {0} (v{1}) is available.' -f $moduleName,$module.Version)
  }
  else {
    Import-Module -Name 'PowershellGet'
    $installedModule = Get-InstalledModule -Name $moduleName -ErrorAction SilentlyContinue
    if ($null -ne $installedModule) {
      Write-Verbose ('Module [{0}] (v {1}) is installed.' -f $moduleName,$installedModule.Version)
    }
    if ($null -eq $installedModule -or "" -eq $installedModule -or ($null -ne $minimalVersion -and "" -ne $minimalVersion -and $installedModule.Version -lt $minimalVersion)) {
      Write-Verbose ('Module {0} min.vers {1}: not installed; check if nuget v2.8.5.201 or later is installed.' -f $moduleName,$minimalVersion)
      #First check if package provider NuGet is installed. Incase an older version is installed the required version is installed explicitly
      if ((Get-PackageProvider -Name NuGet -Force).Version -lt '2.8.5.201') {
        Write-Warning ('Module {0} min.vers {1}: Install nuget!' -f $moduleName,$minimalVersion)
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force
      }
      $optionalArgs = New-Object -TypeName Hashtable
      if ("" -ne $minimalVersion) {
        $optionalArgs['RequiredVersion'] = $minimalVersion
      }
      Install-Module -Name $moduleName @optionalArgs -Scope CurrentUser -Force
    }
  }
}

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
    $packages = Get-WinGetPackage | Where-Object Id -EQ $Id
  } elseif ($Name) {
    $packages = Get-WinGetPackage | Where-Object Name -EQ $Name
  } else {
    throw "Id or Name must be specified"
  }
  if ($packages) {
    return
  }

  $params = @{
    Source = $Source
  }
  if ($Id) { $params['Id'] = $Id; $Name = $Id }
  elseif ($Name) { $params['Name'] = $Name }
  if ($Override) { $params['Override'] = $Override }

  Write-Host "Installing $Name"
  Install-WinGetPackage -Mode $Mode @params -ErrorAction Stop
}

function Install-Scoop-IfNotPresent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScoopName,

        [Parameter(Mandatory=$true)]
        [string]$WingetId
        )

    # Check if package is installed via winget
    $wingetPackage = Get-WinGetPackage -Id $WingetId -ErrorAction SilentlyContinue

    if ($wingetPackage) {
        Write-Verbose "Package '$WingetId' is already installed via winget."
        return $false
    }

    # Check if scoop is installed
    if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
        throw [System.Management.Automation.CommandNotFoundException]::new(
            "Scoop is not installed. Please install scoop first."
        )
    }

    # Attempt to install via scoop
    $result = scoop install $ScoopName

    if ($LASTEXITCODE -eq 0) {
        Write-Verbose "Successfully installed '$ScoopName' via scoop."
        return $true
    } else {
        throw [System.Management.Automation.RuntimeException]::new(
            "Failed to install '$ScoopName' via scoop. Error: $result"
        )
    }
}

function Get-UrlBaseName {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        [switch]$KeepExtension = $true,
        [switch]$DecodeUrl = $true
    )

    try {
        # Check if URL is valid
        if (-not [System.Uri]::IsWellFormedUriString($Url, [System.UriKind]::Absolute)) {
            throw "Invalid URL format"
        }

        # Create URI object
        $uri = [System.Uri]::new($Url)

        # Get the path and decode if requested
        $path = $uri.AbsolutePath
        if ($DecodeUrl) {
            $path = [System.Web.HttpUtility]::UrlDecode($path)
        }

        # Get filename with or without extension
        if ($KeepExtension) {
            $fileName = [System.IO.Path]::GetFileName($path)
        }
        else {
            $fileName = [System.IO.Path]::GetFileNameWithoutExtension($path)
        }

        # Return empty string if no filename found
        if ([string]::IsNullOrEmpty($fileName)) {
            return ""
        }

        return $fileName
    }
    catch {
        Write-Error "Error processing URL: $_"
        return $null
    }
}

function Invoke-ChildScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$scriptPath
    )

    if (Test-Path $scriptPath) {
        Write-Host "Running $scriptPath"
        try {
            & $scriptPath
        }
        catch {
            Write-Error "Failed to execute script ${scriptPath}: $_"
        }
    } elseif (Test-Path "$scriptPath.tmpl") {
        Write-Host "Running template script $scriptPath.tmpl"
        $templateDir = Split-Path -Parent "$scriptPath.tmpl"
        $tempScriptPath = Join-Path $templateDir ([System.IO.Path]::GetFileName($scriptPath))
        try {
            Get-Content -Path "$scriptPath.tmpl" |
                chezmoi execute-template |
                Set-Content -Path $tempScriptPath
            & $tempScriptPath
        }
        catch {
            Write-Error "Failed to process or execute template script $scriptPath"
        }
        finally {
            if (Test-Path $tempScriptPath) {
                Remove-Item -Path $tempScriptPath -ErrorAction SilentlyContinue
            }
        }
    } else {
        Write-Error "No $scriptPath script found"
    }
}

<#
.SYNOPSIS
Enables Windows Sandbox if supported on the system.

.DESCRIPTION
This function checks whether Windows Sandbox (the “Containers-DisposableClientVM” feature) is available on the machine,
verifies that hardware virtualization is enabled, warns if the system is a VM (which may require nested virtualization),
and attempts to enable the feature. It is designed to be called from system setup scripts with clean error handling.

.EXAMPLE
Enable-WindowsSandbox

This command will enable Windows Sandbox if all prerequisites are met.
If the feature isn’t available (e.g. on Windows Home), or if virtualization is disabled, it will output appropriate error messages.
#>
function Enable-WindowsSandbox {
    [CmdletBinding()]
    param()

    try {
        # Check if the Windows Sandbox feature is available.
        $sandboxFeature = Get-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -ErrorAction Stop
    }
    catch {
        Write-Error "Windows Sandbox is not available on this machine. (It may not be supported on Windows Home editions.)"
        return
    }

    if ($sandboxFeature.State -eq "Enabled") {
        Write-Verbose "Windows Sandbox is already enabled."
        Write-Output "Windows Sandbox is already enabled."
        return
    }

    # Verify that hardware virtualization is enabled.
    try {
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    }
    catch {
        Write-Error "Failed to retrieve CPU information. Details: $_"
        return
    }
    if (-not $cpu.VirtualizationFirmwareEnabled) {
        Write-Error "Virtualization is not enabled in the firmware. Windows Sandbox requires virtualization support."
        return
    }

    # Warn if running in a VM, as nested virtualization may be needed.
    try {
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    }
    catch {
        Write-Warning "Unable to retrieve computer system information for nested virtualization check."
    }
    if ($computerSystem -and $computerSystem.Model -match "Virtual") {
        Write-Warning "This system appears to be a virtual machine. Windows Sandbox runs as a nested Hyper-V container, so ensure nested virtualization is enabled."
    }

    # Attempt to enable the Windows Sandbox feature.
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -NoRestart -ErrorAction Stop
        Write-Output "Windows Sandbox has been enabled. Please restart your computer for the changes to take effect."
    }
    catch {
        Write-Error "Failed to enable Windows Sandbox. Details: $_"
    }
}

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

switch (Get-PSPlatform) {
  'Win32NT' {
    New-Variable -Option Constant -Name IsWindows -Value $True -ErrorAction SilentlyContinue
    New-Variable -Option Constant -Name IsLinux -Value $false -ErrorAction SilentlyContinue
    New-Variable -Option Constant -Name IsMacOs -Value $false -ErrorAction SilentlyContinue
  }
}
