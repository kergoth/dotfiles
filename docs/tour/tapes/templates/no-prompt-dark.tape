Source docs/tour/tapes/templates/settings-dark.tape


# No prompt shown. Use for fullscreen command output (git log/diff pager,
# etc.) where the prompt adds no context.
#
# Replace REPLACE-ME with the output filename stem.
# Replace /output-pattern/ with a string that appears in the final output.

Hide
Type "REPLACE WITH SETUP COMMANDS (cd, etc.)"
Enter
Wait+Screen /shell-ready-pattern/
Type "REPLACE WITH COMMAND"
Enter
Wait+Screen /output-pattern/
Sleep 500ms
Show
Screenshot docs/tour/REPLACE-ME-dark.png
Sleep 100ms
