export GNUPGHOME="$XDG_DATA_HOME/gnupg"
if [[ -n "$SSH_AUTH_SOCK" ]]; then
    export GPG_TTY=${GPG_TTY:-${SSH_TTY:-$(tty)}}
fi