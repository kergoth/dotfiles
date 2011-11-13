if test -d ~/bin
    set PATH ~/bin $PATH
end

if not set -q HOME
    set -x HOME (cd ~; and pwd)
end

if not set -q HOSTNAME
    set -x HOSTNAME (hostname)
end

set -x EMAIL "kergoth@gmail.com"
set -x FULLNAME "Christopher Larson"
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
