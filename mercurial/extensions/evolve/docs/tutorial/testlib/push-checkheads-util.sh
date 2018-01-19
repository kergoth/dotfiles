# setup config and various utility to test new heads checks on push

. $TESTDIR/testlib/common.sh

cat >> $HGRCPATH <<EOF
[ui]
# simpler log output
logtemplate ="{node|short} ({phase}): {desc}\n"

[phases]
# non publishing server
publish=False

[extensions]
# we need to strip some changeset for some test cases
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
