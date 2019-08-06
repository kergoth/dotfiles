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
        _pcposts "$@" | eval $LESSCOLORIZER -l yaml | pager
    else
        _pcposts "$@"
    fi
}
