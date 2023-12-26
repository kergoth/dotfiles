
# Install scoop
if (-Not $env:SCOOP)
{
    $env:SCOOP = "$env:USERPROFILE/scoop"
}
if (-Not (Test-Path "$env:SCOOP"))
{
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
}
RefreshEnvPath

# Install git
scoop install git
scoop install git-lfs

# Install languages
scoop install rust go python
$reg = Get-ChildItem $env:USERPROFILE\scoop\apps\python\*\install-pep-514.reg -ErrorAction SilentlyContinue | Select-Object -First 1
if ($reg) {
    Write-Host "Importing python registry entries"
    reg import $reg
}
RefreshEnvPath

# Windows-specific
scoop install sudo gow starship npiperelay

# Install core
# Unavailable on Windows: tmux, zsh
scoop install neovim
scoop install wget
scoop install curl

# Add scoop's Git for Windows bin directory to the PATH for its bash
$gitdir = scoop prefix git
Add-EnvironmentVariableItem "PATH" "$gitdir\bin" -User

# Add cargo bindir to the PATH
Add-EnvironmentVariableItem "PATH" "$env:USERPROFILE\.cargo\bin" -User

# Add USERPROFILE to the WSL environment
Add-EnvironmentVariableItem "WSLENV" "USERPROFILE/up" -User

# Install tools
scoop install bat
scoop install bat-extras
scoop install cht
scoop install direnv
scoop install duf
scoop install eza
scoop install fd
scoop install less
scoop install ripgrep
scoop install zoxide
scoop install fzf

scoop install shfmt
scoop install shellcheck
scoop install jq
scoop install pipx
scoop install sad
scoop install sd
cargo install choose
scoop install tealdeer
scoop install unar
scoop install zstd

# SCM & Related
scoop install delta
scoop install gh
scoop install ghq
scoop install git-branchless
scoop install sapling

# Disk tools
scoop install dua
scoop install dust

# Bug tracking and workflow
scoop install jira-cli

pipx install git-revise
pipx install git-imerge

# git-absorb is available only via release archives on Windows. It fails to build with cargo.
if (-Not (Test-Path "$env:USERPROFILE\.cargo\bin\git-absorb.exe")) {
    $DownloadsFolder = Get-ItemPropertyValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"
    $absorb_url = Get-GithubLatestRelease tummychow/git-absorb "pc-windows-msvc.*.zip"
    $absorb = "$DownloadsFolder\" + (Split-Path $absorb_url -Leaf)
    if (-Not (Test-Path $absorb)) {
        Start-BitsTransfer $absorb_url -Destination $DownloadsFolder
    }
    $absorbtemp = "$env:TEMP\absorb"
    try {
        Expand-Archive "$absorb" -DestinationPath $absorbtemp -Force
        $absorbdir = (Get-ChildItem -Path $absorbtemp | Select-Object -First 1).FullName
        Move-Item "$absorbdir\git-absorb.exe" -Destination "$env:USERPROFILE\.cargo\bin\"
    }
    finally {
        Remove-Item $absorbtemp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

RefreshEnvPath

if (Get-Process ssh-agent -ErrorAction SilentlyContinue) {
    # Add ssh keys from $env:USERPROFILE/.ssh/keys to the ssh agent
    if ((Test-Path "$env:USERPROFILE\.ssh\keys") -And (Get-Command ssh-add -ErrorAction SilentlyContinue)) {
        Write-Output "Adding SSH keys to keychain"
        Get-ChildItem -Path "$env:USERPROFILE\.ssh\keys" -File -Recurse |
            Where-Object { $_.Name -NotLike "*.pub" } |
            ForEach-Object {
                ssh-add $_.FullName
            }
    }
}

# Add installed software to the user's PATH and/or startup
if (Test-Path "C:\Program Files\7-Zip") {
    Add-EnvironmentVariableItem "PATH" "C:\Program Files\7-Zip" -User
}

# Run SyncTrayzor, which will add itself to startup
if (Test-Path "C:\Program Files\SyncTrayzor") {
    Start-Process "C:\Program Files\SyncTrayzor\SyncTrayzor.exe" -ArgumentList --minimized
}

# Apply my dotfiles
$env:DOTFILES_DIR = $PSScriptRoot | Split-Path -Parent
Join-Path $env:DOTFILES_DIR "script\setup.ps1" | Invoke-Expression
