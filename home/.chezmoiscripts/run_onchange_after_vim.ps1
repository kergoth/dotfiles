$update = Join-Path $env:USERPROFILE .config\vim\script\update.ps1
if (Test-Path $update) {
    $update | Invoke-Expression
}
