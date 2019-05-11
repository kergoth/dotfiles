# bumble-strings

Some simple javascript string helpers for testing weak equality and more.

[<img alt="Screenshot from doc/examples/model/model.html" src="https://travis-ci.org/littlebee/bumble-strings.svg?branch=master"
/>](https://travis-ci.org/zulily/react-datum)

(Api Docs and Examples)[http://littlebee.github.io/bumble-strings/docs/api/]


### Installation
```
  npm install bumble-strings
```

### Usage
Like any other common js library...
```javascript
Bstr = require('bumble-strings')
resule = Bstr.weaklyHas("My   dog has   flees", "my dog")
console.log(result)  # true
```


