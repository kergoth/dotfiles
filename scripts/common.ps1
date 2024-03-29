if ($IsWindows) {
    Import-Module -Name BitsTransfer
}

function RefreshEnvPath {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") `
        + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Remove-PossiblyMissingItem {
    try {
        Remove-Item @args -ErrorAction Stop
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        $null
    }
}

# Add-EnvironmentVariableItem from Get-EnvironmentVariable.ps1
# Copyright (C) Frank Skare (stax76)
# MIT License
function Add-EnvironmentVariableItem {
    [CmdletBinding()]
    [Alias('aevi')]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $Name,
        [Parameter(Mandatory = $true)]
        [string] $Value,
        [Switch] $Machine,
        [Switch] $User,
        [Switch] $End
    )

    process {
        $scope = 'Process'

        if ($Machine) { $scope = 'Machine' }
        if ($User) { $scope = 'User' }

        $var = [Environment]::GetEnvironmentVariable($Name, $scope)
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

        [Environment]::SetEnvironmentVariable($Name, $var, $scope)
    }
}

function Get-GithubLatestRelease {
    param (
        [parameter(Mandatory)][string]$project, # e.g. paintdotnet/release
        [parameter(Mandatory)][string]$pattern, # regex. e.g. install.x64.zip
        [switch]$prerelease
    )

    # Get all releases and then get the first matching release. Necessary because a project's "latest"
    # release according to Github might be of a different product or component than the one you're
    # looking for. Also, Github's 'latest' release doesn't include prereleases.
    $releases = Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$project/releases"
    $downloadUrl = $releases |
        Where-Object { $_.prerelease -eq $prerelease } |
        ForEach-Object { $_.assets } |
        Where-Object { $_.name -match $pattern } |
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
    param (
        [parameter(Mandatory)][string]$Pathname
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

Function Install-ModuleIfNotInstalled(
    [string] [Parameter(Mandatory = $true)] $moduleName,
    [string] $minimalVersion = $null
) {
    $module = Get-Module -Name $moduleName -ListAvailable |`
            Where-Object { $null -eq $minimalVersion -or $minimalVersion -lt $_.Version } |`
            Select-Object -Last 1
    if ($null -ne $module) {
        Write-Verbose ('Module {0} (v{1}) is available.' -f $moduleName, $module.Version)
    }
    else {
        Import-Module -Name 'PowershellGet'
        $installedModule = Get-InstalledModule -Name $moduleName -ErrorAction SilentlyContinue
        if ($null -ne $installedModule) {
            Write-Verbose ('Module [{0}] (v {1}) is installed.' -f $moduleName, $installedModule.Version)
        }
        if ($null -eq $installedModule -or ($null -ne $minimalVersion -and $installedModule.Version -lt $minimalVersion)) {
            Write-Verbose ('Module {0} min.vers {1}: not installed; check if nuget v2.8.5.201 or later is installed.' -f $moduleName, $minimalVersion)
            #First check if package provider NuGet is installed. Incase an older version is installed the required version is installed explicitly
            if ((Get-PackageProvider -Name NuGet -Force).Version -lt '2.8.5.201') {
                Write-Warning ('Module {0} min.vers {1}: Install nuget!' -f $moduleName, $minimalVersion)
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

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

switch (Get-PSPlatform) {
    'Win32NT' {
        New-Variable -Option Constant -Name IsWindows -Value $True -ErrorAction SilentlyContinue
        New-Variable -Option Constant -Name IsLinux  -Value $false -ErrorAction SilentlyContinue
        New-Variable -Option Constant -Name IsMacOs  -Value $false -ErrorAction SilentlyContinue
    }
}
