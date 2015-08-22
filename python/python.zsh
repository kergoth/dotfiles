if [[ ! $OSTYPE =~ darwin* ]]; then
    export PYTHONUSERBASE="$XDG_DATA_HOME/.."
fi
