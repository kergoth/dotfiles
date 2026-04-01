#!/usr/bin/env pwsh

<#
.SYNOPSIS
Configures DevPod via CLI: provider, context options, and optional default IDE.

.PARAMETER DotfilesUrl
The URL of the dotfiles repository.

.PARAMETER DotfilesScript
The path to the setup script within the dotfiles repository.

.PARAMETER SshConfigPath
The absolute path to the SSH config file.

.PARAMETER ProviderName
The DevPod provider to use (default: docker).

.PARAMETER DefaultIde
Optional DevPod default IDE (e.g. vscode, zed).
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$DotfilesUrl,

    [Parameter(Mandatory = $true)]
    [string]$DotfilesScript,

    [Parameter(Mandatory = $true)]
    [string]$SshConfigPath,

    [Parameter(Mandatory = $false)]
    [string]$ProviderName = "docker",

    [Parameter(Mandatory = $false)]
    [string]$DefaultIde
)

if (-not (Get-Command devpod -ErrorAction SilentlyContinue)) {
    Write-Verbose "devpod not found, skipping DevPod configuration"
    exit 0
}

Write-Host "Configuring DevPod"

$providers = $null
try {
    $providerJson = devpod provider list --output json 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($providerJson)) {
        $providers = $providerJson | ConvertFrom-Json
    }
} catch {
    $providers = $null
}

if (-not $providers) {
    Write-Warning "Unable to read DevPod provider list, skipping provider configuration"
    exit 0
}

$providerExists = $providers.PSObject.Properties.Name -contains $ProviderName
if (-not $providerExists) {
    Write-Verbose "Adding DevPod provider '$ProviderName'"
    $null = devpod provider add $ProviderName 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to add DevPod provider '$ProviderName'"
        exit 0
    }
    try {
        $providerJson = devpod provider list --output json 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($providerJson)) {
            $providers = $providerJson | ConvertFrom-Json
        } else {
            Write-Warning "Unable to refresh DevPod provider list after add"
            exit 0
        }
    } catch {
        Write-Warning "Unable to refresh DevPod provider list after add"
        exit 0
    }
}

$isDefault = $false
try {
    $prov = $providers.$ProviderName
    if ($null -ne $prov -and $prov.PSObject.Properties.Name -contains 'default') {
        $isDefault = [bool]$prov.default
    }
} catch {
    $isDefault = $false
}

if (-not $isDefault) {
    Write-Host "Setting DevPod default provider to '$ProviderName'"
    $null = devpod provider use $ProviderName 2>$null
}

$options = @(
    "-o", "DOTFILES_URL=$DotfilesUrl",
    "-o", "DOTFILES_SCRIPT=$DotfilesScript",
    "-o", "GPG_AGENT_FORWARDING=false",
    "-o", "SSH_CONFIG_PATH=$SshConfigPath",
    "-o", "SSH_INJECT_GIT_CREDENTIALS=true",
    "-o", "TELEMETRY=false"
)

$null = devpod context set-options @options 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Failed to set some DevPod context options"
}

if (-not [string]::IsNullOrWhiteSpace($DefaultIde)) {
    Write-Host "Setting DevPod default IDE to '$DefaultIde'"
    $null = devpod ide use $DefaultIde 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to set DevPod default IDE to '$DefaultIde'"
    }
}
