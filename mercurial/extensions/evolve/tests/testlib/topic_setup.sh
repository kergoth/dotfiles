#!/bin/sh

# This file holds logic that is used in many tests.
# It can be called in a test like this:
#  $ . "$TESTDIR/testlib/topic_setup.sh"

# Enable obsolete markers and enable extensions
cat >> $HGRCPATH << EOF
[experimental]
evolution=createmarkers,exchange

[extensions]
rebase=
EOF
echo "topic=$(echo $(dirname $TESTDIR))/hgext3rd/topic" >> $HGRCPATH
