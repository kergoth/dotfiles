# Variables {{{1
set tacklebox_path ~/.config/fish/tacklebox
set tacklebox_plugins misc python volatile z virtualenv lastdir

set_path ~/bin ~/.local/bin ~/.gem/ruby/*/bin $PATH /usr/local/sbin /usr/sbin /sbin

if not set -q HOME
    set -x HOME (cd ~; and pwd)
end

if not set -q HOSTNAME
    set -x HOSTNAME (hostname -s)
end

set -x EMAIL 'kergoth@gmail.com'
set -x FULLNAME 'Christopher Larson'
set -x DEBEMAIL $EMAIL
set -x DEBFULLNAME $FULLNAME

set -x CVS_RSH ssh
set -x CVSREAD yes

set -x INPUTRC ~/.inputrc
set -x TERMINFO ~/.terminfo
set -x ACKRC .ackrc

set -x LC_MESSAGES C
set -x LC_ALL

set -x LESS FRX
set -x PAGER less
set -x MANWIDTH 80
set -x SHELL (which fish)

set -x PIP_DOWNLOAD_CACHE $HOME/.pip/cache
set -x VIRTUALENVWRAPPER_VIRTUALENV_ARGS --no-site-packages --distribute


set OS (uname -s | tr A-Z a-z)
if test -e ~/.config/fish/$OS.fish
    . ~/.config/fish/$OS.fish
end

if test -e ~/.config/fish/$HOSTNAME.fish
    . ~/.config/fish/$HOSTNAME.fish
end

if test $OS = darwin
    set tacklebox_plugins $tacklebox_plugins osx
end

# Editor {{{1
if have vim
    alias vi vim

    set -gx EDITOR vim
    set -gx VISUAL $EDITOR
end

# Functions {{{1
if begin test $TERM = screen; or test $TERM = screen-256color; end
    function screen_title --on-variable fish_title_string # damn hack
        printf "\033k%s\033\\" $fish_title_string
    end
end

# Aliases {{{1
if test $OS = darwin
    alias ps 'ps ux'
else
    alias ps 'ps fux'
end

alias tmux   'tmux -u2'
alias bback  'ack --type=bitbake'
alias chrome 'google-chrome'
alias t.py   'command t.py --task-dir ~/Dropbox/Documents'
alias t      't.py --list tasks.txt'
alias h      't.py --list tasks-personal.txt'

# Tacklebox {{{1
if status --is-interactive
    . $tacklebox_path/tacklebox.fish
end

# Keychain {{{1
if have keychain
    keychain --eval $HOSTNAME | sed 's/.*set -x -U/set -gx/' | while read line
        eval $line
    end
end

# To ensure that I don't see a failure status in the prompt at login
true

# vi:sts=4 sw=4 et fdm=marker
