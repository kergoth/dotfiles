Import-Module Recycle
Import-Module posh-alias

if (Get-Command starship) {
    function Invoke-Starship-TransientFunction {
        &starship module character
    }

    Invoke-Expression (&starship init powershell)

    Enable-TransientPrompt
}

# Dracula readline configuration. Requires version 2.0, if you have 1.2 convert to `Set-PSReadlineOption -TokenType`
Set-PSReadlineOption -Color @{
    "Command"   = [ConsoleColor]::Green
    "Parameter" = [ConsoleColor]::Gray
    "Operator"  = [ConsoleColor]::Magenta
    "Variable"  = [ConsoleColor]::White
    "String"    = [ConsoleColor]::Yellow
    "Number"    = [ConsoleColor]::Blue
    "Type"      = [ConsoleColor]::Cyan
    "Comment"   = [ConsoleColor]::DarkCyan
}

if (-Not $env:DOTFILESDIR) {
    if (Test-Path "$env:USERPROFILE/dotfiles") {
        $env:DOTFILESDIR = "$env:USERPROFILE/dotfiles"
    }

    if (Test-Path "$env:HOME/.dotfiles") {
        $env:DOTFILESDIR = "$env:HOME/.dotfiles"
    }
}

# DirColors configuration
if (Test-Path "$env:USERPROFILE/.config/powershell/ls_colors") {
    $env:LS_COLORS = Get-Content "$env:USERPROFILE/.config/powershell/ls_colors"
}
Import-Module DirColors

# I prefer emacs readline behavior
Set-PSReadLineOption -EditMode Emacs

# Search history with arrows
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# In Emacs mode - Tab acts like in bash, but the Windows style completion
# is still useful sometimes, so bind some keys so we can do both
Set-PSReadLineKeyHandler -Key Ctrl+q -Function TabCompleteNext
Set-PSReadLineKeyHandler -Key Ctrl+Q -Function TabCompletePrevious

# Clipboard interaction is bound by default in Windows mode, but not Emacs mode.
Set-PSReadLineKeyHandler -Key Ctrl+C -Function Copy
Set-PSReadLineKeyHandler -Key Ctrl+v -Function Paste

# The built-in word movement uses character delimiters, but token based word
# movement is also very useful - these are the bindings you'd use if you
# prefer the token based movements bound to the normal emacs word movement
# key bindings.
Set-PSReadLineKeyHandler -Key Alt+d -Function ShellKillWord
Set-PSReadLineKeyHandler -Key Alt+Backspace -Function ShellBackwardKillWord
Set-PSReadLineKeyHandler -Key Alt+b -Function ShellBackwardWord
Set-PSReadLineKeyHandler -Key Alt+f -Function ShellForwardWord
Set-PSReadLineKeyHandler -Key Alt+B -Function SelectShellBackwardWord
Set-PSReadLineKeyHandler -Key Alt+F -Function SelectShellForwardWord

# Disable the annoying beep
Set-PSReadlineOption -BellStyle None

# Linux/Mac command muscle memory
if (Get-Command eza) {
    # TODO: Make a proper eza function with powershell-style arguments that translate to eza args
    function Get-ezaChildItem {
        eza --colour-scale all @args
    }
    function Get-ezaChildItemHidden {
        eza --colour-scale all -a @args
    }
    function Get-ezaChildItemDetailed {
        eza --colour-scale all -l @args
    }
    function Get-ezaChildItemSorted {
        eza --colour-scale all -s modified @args
    }
    New-Alias ls Get-ezaChildItem -Force
    New-Alias la Get-ezaChildItemHidden -Force
    New-Alias ll Get-ezaChildItemDetailed -Force
    New-Alias lr Get-ezaChildItemSorted -Force
} else {
    New-Alias ls Get-ChildItem -Force
}
New-Alias which Get-Command -Force
New-Alias grep Select-String -Force
New-Alias rm Remove-ItemSafely -Force
New-Alias rmdir Remove-ItemSafely -Force

if (Get-Command bat) {
    if (Test-Path alias:cat) {
        Remove-Alias cat
    }
    Add-Alias cat bat
}

if (Get-Command zoxide) {
    Invoke-Expression (& {
            $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell | Out-String)
        })
}
else {
    # 'z'. Always import it after prompt setup.
    Import-Module ZLocation
}

# Convenience
New-Alias recycle Remove-ItemSafely -Force
Add-Alias Reload-Profile '& $profile'

$env:Path += ";$env:USERPROFILE/.cargo/bin"

if (Test-Path "$env:USERPROFILE/.pyenv") {
    $env:PYENV = "$env:USERPROFILE/.pyenv/pyenv-win"
    $env:Path += ";$env:PYENV/bin;$env:PYENV/shims"
}
if (-Not (Get-Command python)) {
    if (Test-Path "C:\Python38") {
        $env:Path = "C:\Python38;" + $env:Path
    }
}
if (-Not (Get-Command python)) {
    if (Test-Path "C:\Python39") {
        $env:Path = "C:\Python39;" + $env:Path
    }
}
if (-Not (Get-Command 7z)) {
    if (Test-Path "C:\Program Files\7-Zip") {
        $env:Path = "C:\Program Files\7-Zip;" + $env:Path
    }
}
if (-Not (Test-Path alias:python3)) {
    Add-Alias python3 python
}
function Copy-SSH-Id {
    ssh-add -L | ssh @args "mkdir -p ~/.ssh; cat >> .ssh/authorized_keys"
}
Add-Alias ssh-copy-id Copy-SSH-Id

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    if (-Not (Get-Command vim -ErrorAction SilentlyContinue)) {
        Add-Alias vim nvim
    }
}
Add-Alias vi vim

if (Test-Path "$env:USERPROFILE\.local.ps1") {
    . "$env:USERPROFILE\.local.ps1"
}
