export HOMEBREW_AUTO_UPDATE=1
if [[ "$OSTYPE" == darwin* ]]; then
    export HOMEBREW_PREFIX=/opt/homebrew
else
    export HOMEBREW_PREFIX=~/.brew
fi
