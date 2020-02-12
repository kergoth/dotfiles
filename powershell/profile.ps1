Import-Module DirColors
Import-Module PSReadLine
Import-Module Recycle
Import-Module ZLocation

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
New-Alias ls Get-ChildItem -Force
New-Alias which Get-Command -Force
New-Alias grep Select-String -Force
New-Alias rm Remove-ItemSafely -Force
New-Alias rmdir Remove-ItemSafely -Force

# Convenience
New-Alias recycle Remove-ItemSafely -Force

if (Get-Module -Listavailable -Name posh-alias)
{
    Add-Alias Reload-Profile '& $profile'
}

# Add pyenv-win to the Path if we have it. Note: can use setx to set it in the registry instead.
if (Test-Path "$env:USERPROFILE/.pyenv")
{
    $env:PYENV = "$env:USERPROFILE/.pyenv/pyenv-win"
    $env:Path += ";$env:PYENV/bin;$env:PYENV/shims"
}
