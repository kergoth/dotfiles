$ProgressPreference = 'SilentlyContinue' # Suppress progress bar (speed up downloading, especially on PowerShell 5)
$ConfirmPreference = 'None' # Suppress confirmation prompts

Add-Type -AssemblyName System.Web

if ($IsWindows) {
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
    if ($null -eq $installedModule -or ($null -ne $minimalVersion -and $installedModule.Version -lt $minimalVersion)) {
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

  $arguments = @("-Source","$Source")
  if ($Id) { $arguments += "-Id"; $arguments += "$Id"; $Name = $Id; }
  elseif ($Name) { $arguments += "-Name $Name" }
  if ($Override) { $arguments += "-Override $Override" }

  Write-Output "Installing package $Name"
  # Install-WinGetPackage -Mode $Mode @arguments -Verbose Continue -ErrorAction Stop
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

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

switch (Get-PSPlatform) {
  'Win32NT' {
    New-Variable -Option Constant -Name IsWindows -Value $True -ErrorAction SilentlyContinue
    New-Variable -Option Constant -Name IsLinux -Value $false -ErrorAction SilentlyContinue
    New-Variable -Option Constant -Name IsMacOs -Value $false -ErrorAction SilentlyContinue
  }
}
