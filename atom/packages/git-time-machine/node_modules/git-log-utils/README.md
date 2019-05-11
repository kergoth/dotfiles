
# git-log-utils
Utility methods for parsing `git log` output

## Installation
```
  npm install git-log-utils
  
```
## Usage
```javascript

GitLogUtils = require('git-log-utils')

GitLogUtils.getFileCommitHistory(fileName)
```
Returns an array of javascript objects representing the commits that effected the requested file
with line stats, that looks like this:
```javascript  
[{
  "id": "1c41d8f647f7ad30749edcd0a554bd94e301c651",
  "authorName": "Bee Wilkerson",
  "relativeDate": "6 days ago",
  "authorDate": 1450881433,
  "message": "docs all work again after refactoring to bumble-build",
  "body": "",
  "hash": "1c41d8f",
  "linesAdded": 2,
  "linesDeleted": 2
}, {
  ...
}]
```

