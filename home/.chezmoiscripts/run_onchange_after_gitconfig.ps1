if (Get-Command git -ErrorAction SilentlyContinue) {
    if (Test-Path $env:USERPROFILE\.config\git\config) {
        $include = git config -f $env:USERPROFILE\.config\git\config include.path
        if ($include -eq "config.main") {
            return
        }
    }
    Remove-Item -Force $env:USERPROFILE\.config\git\config
    New-Item $env:USERPROFILE\.config\git\config | Out-Null
    git config -f $env:USERPROFILE\.config\git\config include.path config.main
}
