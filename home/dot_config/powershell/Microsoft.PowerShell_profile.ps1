# Use UTF-8 encoding for both input and output
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# Pass through the original encoding to existing executables. Do not convert to ASCII.
$OutputEncoding = [Console]::OutputEncoding

if (-Not $env:USERPROFILE) {
    $env:USERPROFILE = "$env:HOME"
}

Import-Module PSReadline
Import-Module Recycle
Import-Module posh-alias
Import-Module PSFzf

# Dracula colors via https://gist.github.com/umayr/8875b44740702b340430b610b52cd182
$env:FZF_DEFAULT_OPTS='
  --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9
  --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9
  --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
  --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
  --height 40% --multi --reverse
'
$env:_ZO_FZF_OPTS=$env:FZF_DEFAULT_OPTS

if (Get-Command fd -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_COMMAND = 'fd -c always -t f ""'
    $env:FZF_CTRL_T_COMMAND = "$env:FZF_DEFAULT_COMMAND"
    $env:FZF_ALT_C_COMMAND = 'fd -c always -t d ""'
    $env:FZF_DEFAULT_OPTS = "$env:FZF_DEFAULT_OPTS --ansi"
}

$env:LESS = '-F -g -i -M -R -w -X -z-4'
$env:PYTHONWARNINGS = 'ignore:DEPRECATION'
if ($IsWindows) {
    $env:TEALDEER_CONFIG_DIR = "$env:APPDATA\tealdeer"
    $env:RIPGREP_CONFIG_PATH = "$env:USERPROFILE\.config\ripgrep\config"
    $env:CURL_HOME = "$env:USERPROFILE\.config\curl"
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
    function Invoke-Starship-TransientFunction {
        &starship module character
    }

    Invoke-Expression (&starship init powershell)
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

# Use FZF for tab completion
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }

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

# Use Ctrl+r from FZF rather than Readline
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

# Linux/Mac command muscle memory
if (Get-Command eza -ErrorAction SilentlyContinue) {
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

if (Get-Command ghq -ErrorAction SilentlyContinue) {
    if (-Not $env:GHQ_ROOT) {
        $env:GHQ_ROOT = "$env:USERPROFILE/Repos"
    }

    function Invoke-SetLocationGHQ {
        ghq get @args
        $repo = ghq list --exact @args
        if ($repo) {
            Set-Location "$env:GHQ_ROOT/$repo"
        }
    }
    function Invoke-FuzzyGetRepositoryGHQ {
        ghq list | fzf (-split $env:FZF_DEFAULT_OPTS) --query="$args" --select-1
    }
    function Invoke-FuzzySetLocationGHQ {
        $repo = Invoke-FuzzyGetRepositoryGHQ @args
        if ($repo) {
            Set-Location "$env:GHQ_ROOT/$repo"
        }
    }
    New-Alias gg Invoke-SetLocationGHQ -Force
    New-Alias gz Invoke-FuzzySetLocationGHQ -Force
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    if (Test-Path alias:cat) {
        Remove-Alias cat
    }
    Add-Alias cat bat
}

if (Get-Command batgrep -ErrorAction SilentlyContinue) {
    if (Test-Path alias:rg) {
        Remove-Alias rg
    }
    Add-Alias rg batgrep
}
New-Alias g rg -Force

function Set-Location-Create {
    New-Item -ItemType Directory -ErrorAction SilentlyContinue -force @args | Out-Null
    Set-Location @args
}
New-Alias mcd Set-Location-Create -Force

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& {
            $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell | Out-String)
        })
    New-Alias zz zi -Force
}
else {
    # 'z'. Always import it after prompt setup.
    Import-Module ZLocation
}

# Enable transient prompt. This must be enabled after zoxide init.
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Enable-TransientPrompt
}

# Convenience
New-Alias recycle Remove-ItemSafely -Force
Add-Alias Reload-Profile '& $profile'

$env:Path += ";$env:USERPROFILE/.cargo/bin"

if (Test-Path "$env:USERPROFILE/.pyenv") {
    $env:PYENV = "$env:USERPROFILE/.pyenv/pyenv-win"
    $env:Path += ";$env:PYENV/bin;$env:PYENV/shims"
}
if (-Not (Get-Command python -ErrorAction SilentlyContinue)) {
    if (Test-Path "C:\Python38") {
        $env:Path = "C:\Python38;" + $env:Path
    }
}
if (-Not (Get-Command python -ErrorAction SilentlyContinue)) {
    if (Test-Path "C:\Python39") {
        $env:Path = "C:\Python39;" + $env:Path
    }
}
if (-Not (Get-Command 7z -ErrorAction SilentlyContinue)) {
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
    $env:EDITOR = "nvim"
    $env:VISUAL = "nvim"
}
Add-Alias vi vim

if (($env:TERM_PROGRAM -eq 'vscode') -And (Get-Command code -ErrorAction SilentlyContinue)) {
    $env:EDITOR = "code --wait"
    $env:VISUAL = "code --wait"

    New-Alias e code -Force
} else {
    New-Alias e vi -Force
}

if (Test-Path "$env:USERPROFILE\.local.ps1") {
    . "$env:USERPROFILE\.local.ps1"
}
