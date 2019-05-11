#!/usr/bin/env coffee

GitLogUtils = require '../lib/git-log-utils'

debugger
path = process.argv[2]
if !path? || path == "--help"
  console.log """
    Dumps git log json for a file or directory.
    
    usage:  node_modules/git-log-utils/bin/gitLogJson.coffee mySubdir/myFile.whatever
    
  """
  process.exit(1)
  
console.log GitLogUtils.getCommitHistory(path)
