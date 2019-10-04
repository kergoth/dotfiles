pcyamlpager () {
    if [[ "$PAGER" = bat ]]; then
        set -- -l YAML
        pager "$@"
    elif [[ "$PAGER" = less ]]; then
        eval "$LESSCOLORIZER" -l yaml | pager "$@"
        return
    else
        pager "$@"
    fi
}

pcless () {
    pin-cushion "$1" --format json | jq -C . | pager
}

pc () {
    if [ -t 1 ]; then
        pcless "$1"
    else
        pin-cushion "$1" --format json | jq .
    fi
}

_pcposts () {
    pc "posts/${1:-recent}" | jq '.posts | map({href, description, extended, tags, time})' | json2yaml
}

pcposts () {
    if [ -t 1 ]; then
        _pcposts "$@" | pcyamlpager
    else
        _pcposts "$@"
    fi
}
