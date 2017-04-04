#require test-repo

  $ checkcm() {
  >   if ! (which check-manifest > /dev/null); then
  >     echo skipped: missing tool: check-manifest;
  >     exit 80;
  >   fi;
  > };
  $ checkcm
  $ cat << EOF >> $HGRCPATH
  > [experimental]
  > evolution=all
  > EOF

Run check manifest:

  $ cd $TESTDIR/..
  $ check-manifest
  lists of files in version control and sdist match
