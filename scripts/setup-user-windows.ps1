
# Install scoop
if (-Not $env:SCOOP) {
    $env:SCOOP = "$env:USERPROFILE/scoop"
}
if (-Not (Test-Path "$env:SCOOP")) {
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
}
RefreshEnvPath

if (-Not (Test-Path "$env:SCOOP/buckets/extras")) {
    scoop bucket add extras
}
if (-Not (Test-Path "$env:SCOOP/buckets/kergoth")) {
    scoop bucket add kergoth https://github.com/kergoth/scoop-bucket
}

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
scoop install git-absorb
scoop install git-branchless
scoop install sapling

# Disk tools
scoop install dua
scoop install dust

# Bug tracking and workflow
scoop install jira-cli

pipx install git-revise
pipx install git-imerge

RefreshEnvPath

if (Get-Process ssh-agent -ErrorAction SilentlyContinue) {
    if ((Test-Path "$env:USERPROFILE\.ssh\keys") -And (Get-Command ssh-add -ErrorAction SilentlyContinue)) {
        Write-Output "Adding SSH keys to SSH agent"
        Get-ChildItem -Path "$env:USERPROFILE\.ssh\keys" -File -Recurse |
            Where-Object { ($_.Name -NotLike "*.pub") -and ($_.Name -NotLike "*.ppk") } |
            ForEach-Object {
                $pub = $_.FullName + ".pub"
                if (-Not (Test-Path ($pub))) {
                    ssh-keygen -y -f $_.FullName | Out-File ($pub)
                }
                if (-Not (ssh-add -l | Select-String -SimpleMatch -Pattern (ssh-keygen -lf $pub))) {
                    ssh-add $_.FullName
                }
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

# Install fonts
. $PSScriptRoot\windows\register-fonts.ps1

# Apply my dotfiles
$env:DOTFILES_DIR = $PSScriptRoot | Split-Path -Parent
Join-Path $env:DOTFILES_DIR "script\setup.ps1" | Invoke-Expression
