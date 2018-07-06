# Disable C-s (software flow control) on this tty
stty -ixon

# Freeze tty settings
ttyctl -f
