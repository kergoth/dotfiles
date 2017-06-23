  $ cat >> $HGRCPATH <<EOF
  > [extensions]
  > EOF
  $ echo "evolve=$(echo $(dirname $TESTDIR))/hgext3rd/evolve/" >> $HGRCPATH
  $ hg init alpha
  $ cd alpha
  $ echo foo > foo
  $ hg addremove
  adding foo
  $ hg ci -m 'foo'
  $ for x in 1 2 3 4 ; do
  >   echo foo $x > foo
  >   hg amend
  > done

Test conversion between obsolete marker formats
  $ hg debugobsolete
  e63c23eaa88ae77967edcf4ea194d31167c478b0 b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  a5b276878fa564da042b4b9efef3713ceea20350 0 {e63c23eaa88ae77967edcf4ea194d31167c478b0} (*) {'ef1': '*', 'user': 'test'} (glob)
  b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34 384fc811182687231962e486f23ea8c5bab7a2d3 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  2291082406feb57d0f83b9b0a6777b6074f3fde6 0 {b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34} (*) {'ef1': '*', 'user': 'test'} (glob)
  384fc811182687231962e486f23ea8c5bab7a2d3 949d379b3c3bf051906bc3528c049cb536e2ec86 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  1616bdbe82d3fd1fb7c4e068aee277835672ffdc 0 {384fc811182687231962e486f23ea8c5bab7a2d3} (*) {'ef1': '*', 'user': 'test'} (glob)
  949d379b3c3bf051906bc3528c049cb536e2ec86 f2e4c45b2a4a58ccf7ef6825b8fa5685873cd2f7 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  8668d55aac650158bb510be6d47d21e3db9e5c75 0 {949d379b3c3bf051906bc3528c049cb536e2ec86} (*) {'ef1': '*', 'user': 'test'} (glob)
  $ hg debugobsconvert --new-format 0
  Old store is version 1, will rewrite in version 0
  Done!
  $ hg debugobsolete
  e63c23eaa88ae77967edcf4ea194d31167c478b0 b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  a5b276878fa564da042b4b9efef3713ceea20350 0 {e63c23eaa88ae77967edcf4ea194d31167c478b0} (*) {'ef1': '*', 'user': 'test'} (glob)
  b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34 384fc811182687231962e486f23ea8c5bab7a2d3 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  2291082406feb57d0f83b9b0a6777b6074f3fde6 0 {b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34} (*) {'ef1': '*', 'user': 'test'} (glob)
  384fc811182687231962e486f23ea8c5bab7a2d3 949d379b3c3bf051906bc3528c049cb536e2ec86 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  1616bdbe82d3fd1fb7c4e068aee277835672ffdc 0 {384fc811182687231962e486f23ea8c5bab7a2d3} (*) {'ef1': '*', 'user': 'test'} (glob)
  949d379b3c3bf051906bc3528c049cb536e2ec86 f2e4c45b2a4a58ccf7ef6825b8fa5685873cd2f7 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  8668d55aac650158bb510be6d47d21e3db9e5c75 0 {949d379b3c3bf051906bc3528c049cb536e2ec86} (*) {'ef1': '*', 'user': 'test'} (glob)
  $ hg debugobsconvert --new-format 0
  abort: New format is the same as the old format, not upgrading!
  [255]
  $ hg debugobsolete
  e63c23eaa88ae77967edcf4ea194d31167c478b0 b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  a5b276878fa564da042b4b9efef3713ceea20350 0 {e63c23eaa88ae77967edcf4ea194d31167c478b0} (*) {'ef1': '*', 'user': 'test'} (glob)
  b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34 384fc811182687231962e486f23ea8c5bab7a2d3 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  2291082406feb57d0f83b9b0a6777b6074f3fde6 0 {b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34} (*) {'ef1': '*', 'user': 'test'} (glob)
  384fc811182687231962e486f23ea8c5bab7a2d3 949d379b3c3bf051906bc3528c049cb536e2ec86 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  1616bdbe82d3fd1fb7c4e068aee277835672ffdc 0 {384fc811182687231962e486f23ea8c5bab7a2d3} (*) {'ef1': '*', 'user': 'test'} (glob)
  949d379b3c3bf051906bc3528c049cb536e2ec86 f2e4c45b2a4a58ccf7ef6825b8fa5685873cd2f7 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  8668d55aac650158bb510be6d47d21e3db9e5c75 0 {949d379b3c3bf051906bc3528c049cb536e2ec86} (*) {'ef1': '*', 'user': 'test'} (glob)
  $ hg debugobsconvert --new-format 1
  Old store is version 0, will rewrite in version 1
  Done!
  $ hg debugobsolete
  e63c23eaa88ae77967edcf4ea194d31167c478b0 b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  a5b276878fa564da042b4b9efef3713ceea20350 0 {e63c23eaa88ae77967edcf4ea194d31167c478b0} (*) {'ef1': '*', 'user': 'test'} (glob)
  b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34 384fc811182687231962e486f23ea8c5bab7a2d3 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  2291082406feb57d0f83b9b0a6777b6074f3fde6 0 {b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34} (*) {'ef1': '*', 'user': 'test'} (glob)
  384fc811182687231962e486f23ea8c5bab7a2d3 949d379b3c3bf051906bc3528c049cb536e2ec86 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  1616bdbe82d3fd1fb7c4e068aee277835672ffdc 0 {384fc811182687231962e486f23ea8c5bab7a2d3} (*) {'ef1': '*', 'user': 'test'} (glob)
  949d379b3c3bf051906bc3528c049cb536e2ec86 f2e4c45b2a4a58ccf7ef6825b8fa5685873cd2f7 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  8668d55aac650158bb510be6d47d21e3db9e5c75 0 {949d379b3c3bf051906bc3528c049cb536e2ec86} (*) {'ef1': '*', 'user': 'test'} (glob)

Test that the default is some reasonably modern format (first downgrade)
  $ hg debugobsconvert --new-format 0
  Old store is version 1, will rewrite in version 0
  Done!
  $ hg debugobsconvert
  Old store is version 0, will rewrite in version 1
  Done!
  $ hg debugobsolete
  e63c23eaa88ae77967edcf4ea194d31167c478b0 b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  a5b276878fa564da042b4b9efef3713ceea20350 0 {e63c23eaa88ae77967edcf4ea194d31167c478b0} (*) {'ef1': '*', 'user': 'test'} (glob)
  b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34 384fc811182687231962e486f23ea8c5bab7a2d3 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  2291082406feb57d0f83b9b0a6777b6074f3fde6 0 {b81ac6b9d2a55f9a7a6b90a006b1aab0568d6d34} (*) {'ef1': '*', 'user': 'test'} (glob)
  384fc811182687231962e486f23ea8c5bab7a2d3 949d379b3c3bf051906bc3528c049cb536e2ec86 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  1616bdbe82d3fd1fb7c4e068aee277835672ffdc 0 {384fc811182687231962e486f23ea8c5bab7a2d3} (*) {'ef1': '*', 'user': 'test'} (glob)
  949d379b3c3bf051906bc3528c049cb536e2ec86 f2e4c45b2a4a58ccf7ef6825b8fa5685873cd2f7 0 (*) {'ef1': '*', 'user': 'test'} (glob)
  8668d55aac650158bb510be6d47d21e3db9e5c75 0 {949d379b3c3bf051906bc3528c049cb536e2ec86} (*) {'ef1': '*', 'user': 'test'} (glob)
