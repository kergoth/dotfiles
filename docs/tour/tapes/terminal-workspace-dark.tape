Set Height 520
Source docs/tour/tapes/templates/settings-dark.tape

Hide
Type "exec zsh -i"
Enter
Wait+Screen /❯/
Ctrl+L
Type "cd"
Enter
Wait+Screen /❯/
Ctrl+L
Show
Sleep 1s
Type "z dot"
Enter
Wait /❯/
Sleep 500ms
Type "fd -p pi/settings"
Enter
Wait+Screen /settings\/pi\/settings.json.tmpl/
Sleep 500ms
Type "rg chezmoi-diff-managed docs/*.md"
Enter
Wait+Screen /che[zs]moi-diff-managed/
Wait /❯/
Sleep 100ms
Type "sleep 5"
Enter
Wait /❯/
Sleep 2s
Screenshot docs/tour/terminal-workspace-dark.png
Sleep 100ms
