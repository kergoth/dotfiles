#require test-repo

  $ checkflake8() {
  >   if ! (which flake8 > /dev/null); then
  >     echo skipped: missing tool: flake8;
  >     exit 80;
  >   fi;
  > };
  $ checkflake8

Copied from Mercurial core (60ee2593a270)

  $ cd "`dirname "$TESTDIR"`"

run flake8 if it exists; if it doesn't, then just skip

  $ hg files -0 'set:(**.py or grep("^#!.*python")) - removed()' 2>/dev/null \
  > | xargs -0 flake8
