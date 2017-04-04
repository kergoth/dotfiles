# common setup for head checking code

. $TESTDIR/testlib/common.sh

cat >> $HGRCPATH <<EOF
[ui]
logtemplate ="{node|short} ({phase}): {desc}\n"

[phases]
publish=False

[extensions]
strip=
evolve=
EOF

setuprepos() {
    echo creating basic server and client repo
    hg init server
    cd server
    mkcommit root
    hg phase --public .
    mkcommit A0
    cd .. 
    hg clone server client
}
