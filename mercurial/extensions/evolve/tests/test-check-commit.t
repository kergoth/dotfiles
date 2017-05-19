#require test-repo

Enable obsolescence to avoid the warning issue when obsmarker are found

  $ cat << EOF >> $HGRCPATH
  > [experimental]
  > evolution=all
  > EOF

Go back in the hg repo

  $ cd $TESTDIR/..

  $ for node in `hg log --rev 'not public() and ::. and not desc("# no-check-commit")' --template '{node|short}\n'`; do
  >    hg export $node | ${RUNTESTDIR}/../contrib/check-commit > ${TESTTMP}/check-commit.out
  >    if [ $? -ne 0 ]; then
  >        echo "Revision $node does not comply with rules"
  >        echo '------------------------------------------------------'
  >        cat ${TESTTMP}/check-commit.out
  >        echo
  >   fi
  > done
