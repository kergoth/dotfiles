# utility to setup pythonpath to point into the tested repository

export SRCDIR=`dirname $TESTDIR`
if [ -n "$PYTHONPATH" ]; then
    export HGTEST_ORIG_PYTHONPATH=$PYTHONPATH
    export PYTHONPATH=$SRCDIR:$PYTHONPATH
else
    export PYTHONPATH=$SRCDIR
fi
