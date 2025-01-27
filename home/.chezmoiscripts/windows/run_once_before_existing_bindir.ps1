# Check if the directory exists and is not a git repository
if (Test-Path -Path "$HOME\bin" -PathType Container -and -not (Test-Path -Path "$HOME\bin\.git")) {
    try {
        # Change to the directory
        Set-Location -Path "$HOME\bin"

        # Check if git is available
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Error "Error: git not found, exiting"
            exit 1
        }

        # Initialize git repository and set remote
        git init
        git remote add origin https://github.com/kergoth/scripts
        git fetch --depth=1 origin main
        git checkout --force -b main origin/main
    }
    catch {
        # Remove the .git directory if an error occurs
        Remove-Item -Recurse -Force "$HOME\bin\.git"
        exit 1
    }
}