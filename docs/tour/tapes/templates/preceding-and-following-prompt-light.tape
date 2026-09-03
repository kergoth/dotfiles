Source docs/tour/tapes/templates/settings-light.tape


# Preceding prompt, command output, and following prompt. Use for terminal
# workspace shots showing a real shell workflow. Add more Type/Enter/Wait
# blocks for multi-command sequences; each Wait+Screen /❯/ waits for the
# full Powerlevel10k prompt to redraw before continuing.
#
# Replace REPLACE-ME with the output filename stem.
# Replace /❯/ if your prompt uses a different final character.

Hide
Type "exec zsh -i"
Enter
Wait+Screen /❯/
Ctrl+L
Type "REPLACE WITH SETUP COMMANDS (cd, etc.)"
Enter
Wait+Screen /❯/
Ctrl+L
Show
Sleep 1s
Type "REPLACE WITH COMMAND"
Enter
Wait+Screen /❯/
# Add further commands here, each followed by Wait+Screen /❯/
Sleep 2s
Screenshot docs/tour/REPLACE-ME-light.png
Sleep 100ms
