rg () {
    if [[ -t 1 ]]; then
        command rg -p "$@" | pager
    else
        command rg "$@"
    fi
}
