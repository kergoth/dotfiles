$bindir = "$env:USERPROFILE\AppData\Local\Programs\bin"
$bin = "$bindir\chezmoi_modify_manager.exe"
if (-Not (Test-Path "$bin")) {
    . $env:CHEZMOI_COMMAND_DIR\scripts\common.ps1

    $zipFilePath = "$env:TEMP\chezmoi_modify_manager.zip"
    try {
        $manager_url = Get-GithubLatestRelease "VorpalBlade/chezmoi_modify_manager" "x86_64-pc-windows-msvc.zip"
        Invoke-WebRequest -Uri $manager_url -OutFile $zipFilePath
        if (-Not (Test-Path "$bindir")) {
            New-Item -ItemType Directory -Path "$bindir" | Out-Null
        }
        Expand-Archive $zipFilePath -DestinationPath $bindir -Force
    }
    finally {
        Remove-Item $zipFilePath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
