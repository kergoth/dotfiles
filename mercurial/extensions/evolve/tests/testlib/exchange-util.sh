#!/bin/sh

cat >> $HGRCPATH <<EOF
[web]
push_ssl = false
allow_push = *

[ui]
logtemplate ="{node|short} ({phase}): {desc}\n"

[phases]
publish=False

[experimental]
verbose-obsolescence-exchange=false
bundle2-exp=true
bundle2-output-capture=True

[alias]
debugobsolete=debugobsolete -d '0 0'

[extensions]
hgext.strip=
EOF
echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH

mkcommit() {
   echo "$1" > "$1"
   hg add "$1"
   hg ci -m "$1"
}
getid() {
   hg log --hidden --template '{node}\n' --rev "$1"
}

setuprepos() {
    echo creating test repo for test case $1
    mkdir $1
    cd $1
    echo - pulldest
    hg init pushdest
    cd pushdest
    mkcommit O
    hg phase --public .
    cd ..
    echo - main
    hg clone -q pushdest main
    echo - pushdest
    hg clone -q main pulldest
    echo 'cd into `main` and proceed with env setup'
}

dotest() {
# dotest TESTNAME [TARGETNODE]

    testcase=$1
    shift
    target="$1"
    if [ $# -gt 0 ]; then
        shift
    fi
    targetnode=""
    desccall=""
    cd $testcase
    echo "## Running testcase $testcase"
    if [ -n "$target" ]; then
        desccall="desc("\'"$target"\'")"
        targetnode="`hg -R main id -qr \"$desccall\"`"
        echo "# testing echange of \"$target\" ($targetnode)"
    fi
    echo "## initial state"
    echo "# obstore: main"
    hg -R main     debugobsolete | sort
    echo "# obstore: pushdest"
    hg -R pushdest debugobsolete | sort
    echo "# obstore: pulldest"
    hg -R pulldest debugobsolete | sort

    if [ -n "$target" ]; then
        echo "## pushing \"$target\"" from main to pushdest
        hg -R main push -r "$desccall" $@ pushdest
    else
        echo "## pushing from main to pushdest"
        hg -R main push pushdest $@
    fi
    echo "## post push state"
    echo "# obstore: main"
    hg -R main     debugobsolete | sort
    echo "# obstore: pushdest"
    hg -R pushdest debugobsolete | sort
    echo "# obstore: pulldest"
    hg -R pulldest debugobsolete | sort
    if [ -n "$target" ]; then
        echo "## pulling \"$targetnode\"" from main into pulldest
        hg -R pulldest pull -r $targetnode $@ main
    else
        echo "## pulling from main into pulldest"
        hg -R pulldest pull main $@
    fi
    echo "## post pull state"
    echo "# obstore: main"
    hg -R main     debugobsolete | sort
    echo "# obstore: pushdest"
    hg -R pushdest debugobsolete | sort
    echo "# obstore: pulldest"
    hg -R pulldest debugobsolete | sort

    cd ..

}
