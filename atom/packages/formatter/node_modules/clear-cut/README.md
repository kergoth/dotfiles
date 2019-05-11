# clear cut [![Build Status](https://travis-ci.org/atom/clear-cut.png?branch=master)](https://travis-ci.org/atom/clear-cut)

Calculate the specificity of a CSS selector

## Using

```sh
npm install clear-cut
```

```coffee
{specificity} = require 'clear-cut'
specificity('body') # 1
specificity('#footer') # 100
specificity('.error.message') # 20
```

## Developing

```sh
git clone https://github.com/atom/clear-cut.git
cd clear-cut
npm install
npm test
```
