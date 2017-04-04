#require test-repo pyflakes

Copied from Mercurial core (60ee2593a270)

  $ cd "`dirname "$TESTDIR"`"

run pyflakes on all tracked files ending in .py or without a file ending
(skipping binary file random-seed)

  $ hg locate 'set:(**.py or grep("^#!.*python")) - removed()' 2>/dev/null \
  > | xargs pyflakes 2>/dev/null
