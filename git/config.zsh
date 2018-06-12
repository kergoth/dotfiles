if autoload -Uz git-escape-magic; then
    git-escape-magic
fi

alias gitcolor='git -c color.ui=always'
alias gitnofancy='git -c "core.pager=diff-highlight | less --tabs=4 -RFX"'
