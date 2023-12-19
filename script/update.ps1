Write-Output "Updating chezmoi"
chezmoi upgrade

Write-Output "Updating dotfiles repository"
chezmoi update -R
