. $PSScriptRoot\..\scripts\common.ps1

$os = $null
if ($IsLinux) {
    $os = "linux"
}
elseif ($IsMacOS) {
    $os = "macos"
}
elseif ($IsWindows) {
    $os = "windows"
}
if ($os) {
    $script = Join-Path $PSScriptRoot ".." "scripts" "setup-system-$os.ps1"
    if (Test-Path $script) {
        Write-Output "Running setup-system-$os.ps1"
        $script | Invoke-Expression
    }
    else {
        Write-Error "No setup-system-$os.ps1 script found"
    }
}
if ($IsLinux) {
    if (Test-Path "/etc/os-release") {
        $release = Get-Content /etc/os-release | ConvertFrom-StringData
        $distro = $release.ID
        $script = Join-Path $PSScriptRoot ".." "scripts" "setup-system-$distro.ps1"
        if (Test-Path $script) {
            Write-Output "Running setup-system-$distro.ps1"
            $script | Invoke-Expression
        }
        else {
            Write-Warning "No setup-system-$distro.ps1 script found"
        }
    }
}

Write-Output "System setup complete"

