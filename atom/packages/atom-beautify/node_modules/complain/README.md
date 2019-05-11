# complain

Mark methods as deprecated and warn the user when they're called. Forked from [brianc/node-deprecate](https://github.com/brianc/node-deprecate).

## api

`var complain = require('complain');`

### complain()
<sup>
`complain([String message1 [, String message2 [,...]]], [Object options])`
</sup>

Call `complain` within a function you are deprecating.  It will spit out all the messages to the console the first time _and only the first time_ the method is called.

```js
1  │ var complain = require('complain');
2  │
3  │ var someDeprecatedFunction = function() {
4  │   complain('someDeprecatedFunction() is deprecated');
5  │ };
6  │
…  │ // …
30 │
31 │ someDeprecatedFunction();
```

_program output:_

<img width="373" src="https://cloud.githubusercontent.com/assets/1958812/20812831/f2a1cde0-b7c7-11e6-93e6-1613e028e719.png">

#### Options

**`location`**: a string in the format `${filepath}:${line}:${column}` indicating where the deprecated function was called from.  Setting this to `false` disables outputting the location and will only log the message once.

### complain.method()
<sup>
`complain.method(Object proto, String methodName, [String message1 [, String message2 [,...]]], [Object options])`
</sup>

Deprecates a method on an object:

```js
complain.method(console, 'log', 'You should not log.');
```

### complain.fn()
<sup>
`complain.fn(Function func, [String message1 [, String message2 [,...]]], [Object options])`
</sup>

Deprecates a function and returns it:

```js
console.log = complain.fn(console.log, 'You should not log.');
```

### complain.color

Set to `false` to disable color output.  Set to `true` to force color output.  Defaults to the value of `complain.stream.isTTY`.


### complain.colors

Controls the colors used when logging. Default value:
```js
{
  warning: '\x1b[31;1m', // red, bold
  message: false, // use system color
  location: '\u001b[90m' // gray
}
```

_How the default looks on a dark background vs. a light background:_

<img width="373" src="https://cloud.githubusercontent.com/assets/1958812/20812831/f2a1cde0-b7c7-11e6-93e6-1613e028e719.png"><img width="344" src="https://cloud.githubusercontent.com/assets/1958812/20812832/f2a1edb6-b7c7-11e6-81f5-73319ae5f968.png">

### complain.silence

When `true`, do nothing when the complain method is called.

### complain.stream

The to which output is written.  Defaults to `process.stderr`.

### complain.log(message)

The function used to log, by default this function writes to `complain.stream` and falls back to `console.warn`.

You can replace this with your own logging method.

## license

MIT
