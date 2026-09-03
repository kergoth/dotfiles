Source docs/tour/tapes/templates/settings-dark.tape

Hide
Type "exec zsh -i"
Enter
Wait+Screen /❯/
Ctrl+L
Type "z dot"
Enter
Show
Wait+Screen /❯/
Ctrl+L
Sleep 1s
Type "git st"
Enter
Wait+Screen /\\?\\??/
Sleep 500ms
Type "git brstat"
Enter
Wait+Screen /origin\/main/
Sleep 500ms
Type "git l -5 origin/main"
Enter
Wait /❯/
Sleep 100ms
Screenshot docs/tour/git-usage-dark.png
Sleep 100ms
