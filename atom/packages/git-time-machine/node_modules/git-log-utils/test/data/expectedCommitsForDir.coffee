###
  this is the expected data for the first five commits of test-data/fiveCommits.txt.
  Only the keys in these objects are tested against the actual first five commits read
  from git log

  this should remain static, but if you need to redo, use bin/gitLogJson.coffee test/lib/fiveCommits.txt
  and replace array below with pasted output

###
module.exports = [
  { 
    id: "8b94d8444351171180fa01b24e302bc215f21474",
    authorName: "Bee Wilkerson",
    # relativeDate will always be wrong, don't test it
    # relativeDate: "2 hours ago",
    authorDate: 1453041651,
    message: "5th of 5 commits test",
    body: "",
    hash: "8b94d84",
    linesAdded: 1,
    linesDeleted: 1 
  },{ 
    id: "73a007fed9c0aa562a6acf6cfb7ae019d82f677d",
    authorName: "Bee Wilkerson",
    authorDate: 1453041603,
    message: "4th of 5 commits test",
    body: "",
    hash: "73a007f",
    linesAdded: 1,
    linesDeleted: 3 
  },{ 
    id: "b275decc27a27fcfcf653d50c79d705e1cec0c20",
    authorName: "Bee Wilkerson",
    authorDate: 1453041536,
    message: "3rd of 5 commits test",
    body: "",
    hash: "b275dec",
    linesAdded: 2,
    linesDeleted: 0 
  },{ 
    id: "04f65dcf5b6d7da5bad9dcc6a9fba52acb3e548f",
    authorName: "Bee Wilkerson",
    authorDate: 1453041463,
    message: "2nd of 5 commits test",
    body: "",
    hash: "04f65dc",
    linesAdded: 54,
    linesDeleted: 1 
  },{ 
    id: "404744f451bfbac84598c19cd20506af87b2060d",
    authorName: "Bee Wilkerson",
    authorDate: 1453041370,
    message: "brought over git-utils and test from git-time-machine. also start of 5 commits test.",
    body: "",
    hash: "404744f",
    linesAdded: 297,
    linesDeleted: 4 
  } 
]