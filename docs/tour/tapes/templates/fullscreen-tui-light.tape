Source docs/tour/tapes/templates/settings-tui-borderless-light.tape


# Fullscreen TUI capture (tmux statusline, lazygit, etc.). Same pattern as
# vim: hide setup and launch, wait for the UI to render, then show and
# screenshot. No window title is available in VHS; use a README caption to
# identify the tool.
#
# Replace REPLACE-ME with the output filename stem.
# Replace /REPLACE-WITH-PATTERN/ with a string visible once the TUI is ready.

Hide
Type "REPLACE WITH COMMAND TO LAUNCH TUI"
Enter
Wait+Screen /REPLACE-WITH-PATTERN/
Sleep 500ms
Show
Screenshot docs/tour/REPLACE-ME-light.png
Sleep 100ms
