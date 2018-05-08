export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/rc

rg () {
    if [[ -t 1 ]]; then
        command rg -p "$@" | pager
    else
        command rg "$@"
    fi
}
