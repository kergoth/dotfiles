Source docs/tour/tapes/templates/settings-light.tape


# Preceding prompt visible, no following prompt. Use for focused command
# showcases where the shell context matters but the next prompt would clutter.
#
# Replace REPLACE-ME with the output filename stem.
# Replace /output-pattern/ with a string that appears in the final output.
# Replace /❯/ if your prompt uses a different final character.
#
# Timing note: the Sleep after Wait+Screen exploits the window between command
# exit and Powerlevel10k's async prompt redraw. 100ms is usually sufficient;
# increase it if the following prompt bleeds into the screenshot, decrease it
# if the command's own output is slow to settle.

Hide
Type "REPLACE WITH SETUP COMMANDS (cd, etc.)"
Enter
Wait+Screen /❯/
Show
Type "REPLACE WITH COMMAND"
Enter
Wait+Screen /output-pattern/
Sleep 100ms
Screenshot docs/tour/REPLACE-ME-light.png
Sleep 100ms
