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
function Add-EnvironmentVariableItem
{
    [CmdletBinding()]
    [Alias('aevi')]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $Name,
        [Parameter(Mandatory=$true)]
        [string] $Value,
        [Switch] $Machine,
        [Switch] $User,
        [Switch] $End
    )

    process
    {
        $scope = 'Process'

        if ($Machine) { $scope = 'Machine' }
        if ($User)    { $scope = 'User' }

        $var = [Environment]::GetEnvironmentVariable($Name, $scope)
        $tempItems = New-Object Collections.Generic.List[String]

        foreach ($i in ($var -split ';'))
        {
            $i = $i.Trim()

            if ($i -eq '' -or $i -eq $Value)
            {
                continue
            }

            $tempItems.Add($i)
        }

        $var = $tempItems -join ';'

        if ($End)
        {
            $var = $var + ';' + $Value
        }
        else
        {
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
