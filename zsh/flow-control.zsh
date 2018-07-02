# Disable C-s (software flow control) on this tty
stty -ixon

reset () {
  command reset
  stty -ixon
}
