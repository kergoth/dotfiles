# Variables {{{1
set tacklebox_path ~/.config/fish/tacklebox
set tacklebox_plugins misc python volatile z

begin
    set -l path
    for dir in ~/bin ~/.local/bin $PATH
        if test -d $dir
            set path $path $dir
        end
    end
    set PATH $path
end

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

set -x EDITOR vim
set -x VISUAL $EDITOR

set -x INPUTRC ~/.inputrc
set -x ACKRC .ackrc

set -x LC_MESSAGES C
set -x LC_ALL

set -x LESS FRX
set -x PAGER less
set -x MANWIDTH 80

set -x PIP_DOWNLOAD_CACHE "$HOME/.pip/cache"


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
. $tacklebox_path/tacklebox.fish

# Messages {{{1
if status --is-interactive
    if test (t | wc -l) -ne 0
        echo Tasks:
        t | sed 's/^/  /'
    end

    if test (h | wc -l) -ne 0
        echo Personal tasks:
        h | sed 's/^/  /'
    end

    # To ensure that I don't see a failure status in the prompt at login
    true
end

# vi:sts=4 sw=4 et fdm=marker
