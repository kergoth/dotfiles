# events-light

This is a lighter and small version of the builtin Node.js [events](https://nodejs.org/api/events.html) with some removals, but no additional features. This module was designed to be a trimmed down polyfill for the `events` module in the browser, but it can also be used on the server.

# Install

```bash
npm install events-light --save
```

# Usage

```javascript
var EventEmitter = require('events-light');

var myEventEmitter = new EventEmitter();

myEventEmitter.on('hello', function(name) {
    console.log('Hello ' + name);
});

myEventEmitter.emit('hello', 'World');
```

# Difference from the Node.js `events` module

- Much smaller
- Slightly different error messages
- Removed:
    - [`EventEmitter.defaultMaxListeners`](https://nodejs.org/api/events.html#events_eventemitter_defaultmaxlisteners)
    - [`EventEmitter.listenerCount(emitter, eventName)`](https://nodejs.org/api/events.html#events_eventemitter_listenercount_emitter_eventname)
    - [`Event: 'removeListener'`](https://nodejs.org/api/events.html#events_event_removelistener)
    - [`Event: 'newListener'`](https://nodejs.org/api/events.html#events_event_newlistener)
    - [`emitter.prependOnceListener(eventName, listener)`](https://nodejs.org/api/events.html#events_emitter_prependoncelistener_eventname_listener)
    - [`emitter.setMaxListeners(n)`](https://nodejs.org/api/events.html#events_emitter_setmaxlisteners_n)
    - [`emitter.addListener(eventName, listener)`](https://nodejs.org/api/events.html#events_emitter_addlistener_eventname_listener) (use `on` instead)
    - [`emitter.listenerCount(eventName)`](https://nodejs.org/api/events.html#events_emitter_listenercount_eventname)
    - [`emitter.listeners(eventName)`](https://nodejs.org/api/events.html#events_emitter_listeners_eventname)

# License

MIT