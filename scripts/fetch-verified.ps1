<#
.SYNOPSIS
Download a file, verify its SHA-256 digest, and install it to a path.

.DESCRIPTION
Downloads a file to a temporary location in the same directory as the
destination, verifies its SHA-256 digest, and only then moves it to the
output path.  Exits 0 immediately if the destination already matches the
expected digest.  Exits 100 on digest mismatch; exits 101 on other local
errors.

.PARAMETER Url
The URL to download.

.PARAMETER Digest
The expected SHA-256 digest (64 lowercase hex characters).

.PARAMETER OutFile
Write the verified file to this path (required).

.PARAMETER Force
Replace a mismatched existing output file instead of erroring.

.EXAMPLE
scripts\fetch-verified.ps1 $url $hash -OutFile "$tmpDir\installer.exe"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Url,

    [Parameter(Mandatory, Position = 1)]
    [string]$Digest,

    [Parameter(Mandatory)]
    [string]$OutFile,

    [Parameter()]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$script:VerifyExitCode = 100
$script:LocalErrorExitCode = 101

function Write-FetchError {
    param([string]$Message)
    [Console]::Error.WriteLine("fetch-verified: $Message")
    exit $script:LocalErrorExitCode
}

function Get-FileSha256 {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLower()
}

$expectedDigest = $Digest.ToLower()

if ($expectedDigest -notmatch '^[0-9a-f]{64}$') {
    Write-FetchError "digest must be 64 lowercase hex characters"
}

$outDir = Split-Path -Parent $OutFile
if ([string]::IsNullOrEmpty($outDir)) {
    $outDir = (Get-Location).Path
}
if (-not (Test-Path -LiteralPath $outDir -PathType Container)) {
    Write-FetchError "output directory does not exist: $outDir"
}

if (Test-Path -LiteralPath $OutFile) {
    if (-not (Test-Path -LiteralPath $OutFile -PathType Leaf)) {
        Write-FetchError "destination must be a regular file: $OutFile"
    }
    $existingDigest = Get-FileSha256 -Path $OutFile
    if ($existingDigest -eq $expectedDigest) {
        exit 0
    }
    if (-not $Force) {
        Write-FetchError "existing file digest mismatch: $OutFile"
    }
}

$tempDir = Join-Path $outDir (".fetch-verified." + [System.IO.Path]::GetRandomFileName())
try {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    $tempFile = Join-Path $tempDir "download"

    try {
        Invoke-WebRequest -Uri $Url -OutFile $tempFile -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-FetchError "download failed: $_"
    }

    if (-not (Test-Path -LiteralPath $tempFile -PathType Leaf)) {
        Write-FetchError "download produced no file"
    }
    if ((Get-Item -LiteralPath $tempFile).Length -eq 0) {
        Write-FetchError "download produced empty file"
    }

    $actualDigest = Get-FileSha256 -Path $tempFile
    if ($actualDigest -ne $expectedDigest) {
        [Console]::Error.WriteLine("fetch-verified: digest mismatch for $Url")
        exit $script:VerifyExitCode
    }

    Move-Item -LiteralPath $tempFile -Destination $OutFile -Force
} finally {
    if (Test-Path -LiteralPath $tempDir) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
