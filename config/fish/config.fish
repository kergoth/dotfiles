. ~/.config/fish/environment.fish

set OS (uname -s | tr A-Z a-z)
if test -e ~/.config/fish/$OS.fish
    . ~/.config/fish/$OS.fish
end

if test -e ~/.config/fish/$HOSTNAME.fish
    . ~/.config/fish/$HOSTNAME.fish
end

. ~/.config/fish/volatile.fish

# To ensure that I don't see a failure status in the prompt at login
true
