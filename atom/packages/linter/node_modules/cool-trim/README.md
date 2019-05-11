Cool-Trim
========

Cool-Trim is the only thing you'll need to trim your strings

![Everything's awesome](https://cloud.githubusercontent.com/assets/4278113/13688141/fec70458-e6dc-11e5-8e9b-fc39e9961cb5.gif)


## Installation

```sh
npm install --save cool-trim
```

## API

```js
function trim(subject: string, indent: number = 0): string

module.exports = trim
```

## Examples
```js
import trim from 'cool-trim'

trim`
  Top
    Child
  Another Top
` === `Top
  Child
AnotherTop`; // true
```

## License

This project is licensed under the terms of MIT License, see the LICENSE file for more info
