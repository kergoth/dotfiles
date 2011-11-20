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
    set -x HOSTNAME (hostname)
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


# Aliases {{{1
alias bback  'ack --type=bitbake'
alias chrome 'google-chrome'
alias t      't.py --task-dir ~/Dropbox/Documents --list tasks.txt'
alias tmux   'tmux -u2'
if test $OS = darwin
    alias ps 'ps ux'
else
    alias ps 'ps fux'
end


# Other {{{1
. $tacklebox_path/tacklebox.fish


# To ensure that I don't see a failure status in the prompt at login
true

# vi:sts=4 sw=4 et fdm=marker
