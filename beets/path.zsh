if [[ -n $BEETSDIR ]]; then
    path=("${BEETSDIR%/*}/scripts" $path)
fi
