#!/bin/bash
. $TESTDIR/testlib/pythonpath.sh

mkcommit() {
   echo "$1" > "$1"
   hg add "$1"
   hg ci -m "$1"
}

getid() {
   hg log --hidden --template '{node}\n' --rev "$1"
}

cat >> $HGRCPATH <<EOF
[alias]
debugobsolete=debugobsolete -d '0 0'
EOF

html_output() {
    filepath="$1"
    touch "$filepath"
    shift

    python $TESTDIR/testlib/arguments_printer.py 'hg' "$@" > "$filepath"
    hg "$@" --color=always 2>&1 | aha -n | tee -a "$filepath"
}

html_raw_output() {
    filepath="$1"
    touch "$filepath"
    shift

    # python $TESTDIR/testlib/arguments_printer.py "$@" > "$filepath"
    echo "" > "$filepath"
    "$@" | tee -a "$filepath"
}

graph() {
    hg docgraph --rankdir LR --arrowhead=true --obsarrowhead=true --sphinx-directive --dot-output "$@"
}
