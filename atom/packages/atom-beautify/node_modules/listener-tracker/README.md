listener-tracker
=============

[![Build Status](https://travis-ci.org/raptorjs/listener-tracker.svg?branch=master)](https://travis-ci.org/raptorjs/listener-tracker)

Lightweight module to support tracking added event listeners for easy removal later.

# Installation

```
npm install listener-tracker --save
```

# Overview

The native Node.js events module makes it difficult to remove listeners since you must keep a reference to the listener function in order to remove it later. For example, to properly remove a listener you must do the following:

```javascript
function fooListener() {
    /* ... */
}

// Add a listener:
eventEmitter.on('foo', fooListener);

// Now remove it:
eventEmitter.removeListener('foo', fooListener);
```

This is a problem because often times it is more convenient to add listeners with an anonymous function. For example:

```javascript
// Add a listener:
eventEmitter.on('foo', function fooListener() {
    /* ... */
});

// How can we remove it???
```

Also, what if an object is being destroyed and needs to remove all listeners that were added to other `EventEmitter` instances? This module solves these types of problems by keeping tracking of all listeners that are attached by proxying all of the methods that are used to add listeners (i.e. `on`, `once` and `addListener`).

To prevent a memory leak resulting from keeping references to all of the listener functions that were attached, this module will automatically do cleanup if a target `EventEmitter` emits a `destroy` event. You can also manually remove all listeners, of course.

# Usage

## Tracking listeners for a single `EventEmitter` instance for easy removal

```javascript
var EventEmitter = require('events').EventEmitter;

var myEventEmitter = EventEmitter();
var wrapped = require('listener-tracker').wrap(myEventEmitter);

wrapped
    .on('foo', function() { /* ... */ })
    .on('bar', function() { /* ... */ });

// Remove all of the listenters that were tracked by this instance:
wrapped.removeAllListeners();

// Remove the listenters that were tracked by this instance for a specific event:
wrapped.removeAllListeners('foo');
```

## Tracking listeners to multiple `EventEmitter` instances for easy removal

```javascript
var EventEmitter = require('events').EventEmitter;

var listenerTracker = require('listener-tracker').createTracker();
var eventEmitter1 = EventEmitter();
var eventEmitter2 = EventEmitter();

listenerTracker.subscribeTo(eventEmitter1)
    .on('foo', function() { /* ... */ })
    .on('bar', function() { /* ... */ });

listenerTracker.subscribeTo(eventEmitter2)
    .on('foo', function() { /* ... */ })
    .on('bar', function() { /* ... */ });

// Remove all listeners across all EventEmitters that were subscribed to:
listenerTracker.removeAllListeners();

// It's also possible to remove just listeners from one of the event emitters:
listenerTracker.removeAllListeners(eventEmitter1);

// Finally, it's also possible to remove just listeners from one of the event
// emitters for a specific event type:
listenerTracker.removeAllListeners(eventEmitter1, 'foo');
```

# Contributors

* [Patrick Steele-Idem](https://github.com/patrick-steele-idem) (Twitter: [@psteeleidem](http://twitter.com/psteeleidem))
* [Phillip Gates-Idem](https://github.com/philidem/) (Twitter: [@philidem](https://twitter.com/philidem))

# Contribute

Pull Requests welcome. Please submit Github issues for any feature enhancements, bugs or documentation problems.

# License

Apache License v2.0
