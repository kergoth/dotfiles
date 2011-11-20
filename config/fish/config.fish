. ~/.config/fish/environment.fish

alias t 't.py --task-dir ~/Dropbox/Documents --list tasks.txt'

set tacklebox_path ~/.config/fish/tacklebox
set tacklebox_plugins misc python volatile z

set OS (uname -s | tr A-Z a-z)
if test -e ~/.config/fish/$OS.fish
    . ~/.config/fish/$OS.fish
end

if test -e ~/.config/fish/$HOSTNAME.fish
    . ~/.config/fish/$HOSTNAME.fish
end

. $tacklebox_path/tacklebox.fish


# To ensure that I don't see a failure status in the prompt at login
true
