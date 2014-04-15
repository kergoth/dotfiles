# Variables {{{1
set FISHDIR (dirname $argv[1])
set DOTFILESDIR $FISHDIR/..
set tacklebox_path $FISHDIR/tacklebox
set tacklebox_plugins misc python volatile z virtualenv

set PATH $DOTFILESDIR/scripts $DOTFILESDIR/scripts/connections $DOTFILESDIR/external/bin $PATH

for dir in ~/.gem/ruby/*/bin
    if test -e $dir
        set PATH $dir $PATH
    end
end

if test -e ~/.local/bin
    set PATH ~/.local/bin $PATH
end

if not set -q HOME
    set -x HOME (cd ~; and pwd)
end

if not set -q HOSTNAME
    set -x HOSTNAME (hostname -s)
end

if test -z $XDG_CONFIG_HOME
    set -x XDG_CONFIG_HOME ~/.config
end
if test -z $XDG_DATA_HOME
    set -x XDG_DATA_HOME ~/.local/share
end
if test -z $XDG_CACHE_HOME
    set -x XDG_CACHE_HOME ~/.cache
end

set -x EMAIL 'kergoth@gmail.com'
set -x FULLNAME 'Christopher Larson'
set -x DEBEMAIL $EMAIL
set -x DEBFULLNAME $FULLNAME

set -x CVS_RSH ssh
set -x CVSREAD yes

set -x LC_MESSAGES C
set -x LC_ALL

set -x LESS FRX
set -x PAGER less
set -x MANWIDTH 80
set -x VIRTUALENVWRAPPER_VIRTUALENV_ARGS --no-site-packages --distribute

set -x ACKRC .ackrc
set -x INPUTRC $XDG_CONFIG_HOME/readline/inputrc
set -x TERMINFO $XDG_CONFIG_HOME/ncurses/terminfo
set -x CURL_HOME $XDG_CONFIG_HOME/curl

set -x _FASD_VIMINFO $XDG_CACHE_HOME/vim/viminfo
set -x LESSHISTFILE $XDG_CACHE_HOME/less/lesshist
set -x PIP_DOWNLOAD_CACHE $XDG_CACHE_HOME/pip
set -x _FASD_DATA $XDG_CACHE_HOME/fasd/data
set -g z_datafile $XDG_CACHE_HOME/z/data

if not test -e $XDG_CACHE_HOME/z
    mkdir $XDG_CACHE_HOME/z
end

if not test -e $XDG_CACHE_HOME/fasd
    mkdir $XDG_CACHE_HOME/fasd
end


set OS (uname -s | tr A-Z a-z)

if test $OS = darwin
    set tacklebox_plugins $tacklebox_plugins osx
end


# Editor {{{1
if have vim
    alias vi vim

    set -gx EDITOR vim
    set -gx VISUAL $EDITOR
end
set -gx VIMINIT 'let $MYVIMRC = "$XDG_CONFIG_HOME/vim/vimrc" | source $MYVIMRC'

# Reduce the ncurses escape wait time (ms)
set -gx ESCDELAY 25

set -gx NCURSES_NO_UTF8_ACS 1

set -x SHELL (which fish)

# Functions {{{1
if begin test -z $TMUX; and begin test $TERM = screen; or test $TERM = screen-256color; end; end
    # This is disabled for tmux as we can let tmux handle it itself
    function screen_title --on-variable fish_title_string
        printf "\033k%s\033\\" $fish_title_string
    end
end


# Aliases {{{1
alias tmux   'tmux -u2 -f ~/.config/tmux/config'
alias bback  'ack --type=bitbake'
alias chrome 'google-chrome'
alias t.py   'command t.py --task-dir ~/Dropbox/Documents'
alias t      't.py --list tasks.txt'
alias h      't.py --list tasks-personal.txt'
alias bbag   "ag -G '\.(bb|bbappend|inc|conf)\$'"
alias dtrx   'dtrx --one=here'
alias mosh   'mosh --forward-agent'

# Context specific config files {{{1
if test -e $FISHDIR/$OS.fish
    . $FISHDIR/$OS.fish
end

if test -e $FISHDIR/$HOSTNAME.fish
    . $FISHDIR/$HOSTNAME.fish
end

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
