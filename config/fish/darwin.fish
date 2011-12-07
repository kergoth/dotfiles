set -x CLICOLOR 1
set -x COMMAND_MODE unix2003

set_path ~/bin ~/.local/bin (dirname (which fish)) /usr/local/bin /usr/local/sbin /usr/X11R6/bin /usr/bin /usr/sbin /bin /sbin
set PATH (command ls -d ~/Library/Python/*/bin 2>/dev/null) $PATH
