# Install the Windows Build Tools and Visual Studio 2022 Community Edition workload for C++ development
# These are needed to install tools with cargo or golang.

$env:DOTFILES_DIR = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent

. "$env:DOTFILES_DIR\scripts\common.ps1"

Install-WinGetPackageIfNotInstalled -Mode Silent -Id Microsoft.VisualStudio.2022.BuildTools | Out-Null
Install-WinGetPackageIfNotInstalled -Mode Silent -Id Microsoft.VisualStudio.2022.Community -Override "--wait --quiet --add ProductLang En-us --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended" | Out-Null
