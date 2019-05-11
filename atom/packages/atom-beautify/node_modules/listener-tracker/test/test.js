'use strict';
var chai = require('chai');
chai.config.includeStack = true;
var expect = require('chai').expect;
var EventEmitter = require('events').EventEmitter;

var listenerTracker = require('../');

describe('listener-tracker' , function() {

    beforeEach(function(done) {
        for (var k in require.cache) {
            if (require.cache.hasOwnProperty(k)) {
                delete require.cache[k];
            }
        }
        done();
    });

    it('should handle removing all correctly for a single wrapped instance', function() {
        var ee = new EventEmitter();
        var wrapped = listenerTracker.wrap(ee);

        var output = [];

        wrapped.on('foo', function() {
            output.push('foo-wrapped');
        });

        wrapped.on('bar', function() {
            output.push('bar-wrapped');
        });

        ee.on('foo', function() {
            output.push('foo');
        });

        ee.on('bar', function() {
            output.push('bar');
        });

        ee.emit('foo');
        ee.emit('bar');
        expect(output).to.deep.equal(['foo-wrapped', 'foo', 'bar-wrapped', 'bar']);

        wrapped.removeAllListeners();

        ee.emit('foo');
        ee.emit('bar');
        expect(output).to.deep.equal(['foo-wrapped', 'foo', 'bar-wrapped', 'bar', 'foo', 'bar']);
    });

    it('should handle removing all for a specific event correctly for a single wrapped instance', function() {
        var ee = new EventEmitter();
        var wrapped = listenerTracker.wrap(ee);

        var output = [];

        wrapped.on('foo', function() {
            output.push('foo-wrapped');
        });

        wrapped.on('bar', function() {
            output.push('bar-wrapped');
        });

        ee.on('foo', function() {
            output.push('foo');
        });

        ee.on('bar', function() {
            output.push('bar');
        });


        ee.emit('foo');
        ee.emit('bar');
        expect(output).to.deep.equal(['foo-wrapped', 'foo', 'bar-wrapped', 'bar']);

        wrapped.removeAllListeners('bar');

        ee.emit('foo');
        ee.emit('bar');
        expect(output).to.deep.equal(['foo-wrapped', 'foo', 'bar-wrapped', 'bar', 'foo-wrapped', 'foo', 'bar']);
    });

    it('should handle removing all correctly for multiple emitters', function() {


        var tracker = listenerTracker.createTracker();
        var ee1 = new EventEmitter();
        var ee2 = new EventEmitter();

        var output = [];

        tracker.subscribeTo(ee1)
            .on('foo', function() {
                output.push('ee1:foo-wrapped');
            })
            .on('bar', function() {
                output.push('ee1:bar-wrapped');
            });

        tracker.subscribeTo(ee2)
            .on('foo', function() {
                output.push('ee2:foo-wrapped');
            })
            .on('bar', function() {
                output.push('ee2:bar-wrapped');
            });

        ee1
            .on('foo', function() {
                output.push('ee1:foo');
            })
            .on('bar', function() {
                output.push('ee1:bar');
            });

        ee2
            .on('foo', function() {
                output.push('ee2:foo');
            })
            .on('bar', function() {
                output.push('ee2:bar');
            });

        ee1.emit('foo');
        ee2.emit('foo');
        ee1.emit('bar');
        ee2.emit('bar');

        expect(output).to.deep.equal([
            'ee1:foo-wrapped', 'ee1:foo', 'ee2:foo-wrapped', 'ee2:foo',
            'ee1:bar-wrapped', 'ee1:bar', 'ee2:bar-wrapped', 'ee2:bar']);

        tracker.removeAllListeners();

        ee1.emit('foo');
        ee2.emit('foo');
        ee1.emit('bar');
        ee2.emit('bar');

        expect(output).to.deep.equal([
            'ee1:foo-wrapped', 'ee1:foo', 'ee2:foo-wrapped', 'ee2:foo',
            'ee1:bar-wrapped', 'ee1:bar', 'ee2:bar-wrapped', 'ee2:bar',
            'ee1:foo', 'ee2:foo',
            'ee1:bar', 'ee2:bar']);
    });

    it('should handle removing all from one emitter correctly for multiple emitters', function() {


        var tracker = listenerTracker.createTracker();
        var ee1 = new EventEmitter();
        var ee2 = new EventEmitter();

        var output = [];

        tracker.subscribeTo(ee1)
            .on('foo', function() {
                output.push('ee1:foo-wrapped');
            })
            .on('bar', function() {
                output.push('ee1:bar-wrapped');
            });

        tracker.subscribeTo(ee2)
            .on('foo', function() {
                output.push('ee2:foo-wrapped');
            })
            .on('bar', function() {
                output.push('ee2:bar-wrapped');
            });

        ee1
            .on('foo', function() {
                output.push('ee1:foo');
            })
            .on('bar', function() {
                output.push('ee1:bar');
            });

        ee2
            .on('foo', function() {
                output.push('ee2:foo');
            })
            .on('bar', function() {
                output.push('ee2:bar');
            });

        ee1.emit('foo');
        ee2.emit('foo');
        ee1.emit('bar');
        ee2.emit('bar');

        expect(output).to.deep.equal([
            'ee1:foo-wrapped', 'ee1:foo', 'ee2:foo-wrapped', 'ee2:foo',
            'ee1:bar-wrapped', 'ee1:bar', 'ee2:bar-wrapped', 'ee2:bar']);

        tracker.removeAllListeners(ee1);

        ee1.emit('foo');
        ee2.emit('foo');
        ee1.emit('bar');
        ee2.emit('bar');

        expect(output).to.deep.equal([
            'ee1:foo-wrapped', 'ee1:foo', 'ee2:foo-wrapped', 'ee2:foo',
            'ee1:bar-wrapped', 'ee1:bar', 'ee2:bar-wrapped', 'ee2:bar',
            'ee1:foo', 'ee2:foo-wrapped', 'ee2:foo',
            'ee1:bar', 'ee2:bar-wrapped', 'ee2:bar']);
    });

    it('should handle removing all from one emitter for specific event correctly for multiple emitters', function() {


        var tracker = listenerTracker.createTracker();
        var ee1 = new EventEmitter();
        var ee2 = new EventEmitter();

        var output = [];

        tracker.subscribeTo(ee1)
            .on('foo', function() {
                output.push('ee1:foo-wrapped');
            })
            .on('bar', function() {
                output.push('ee1:bar-wrapped');
            });

        tracker.subscribeTo(ee2)
            .on('foo', function() {
                output.push('ee2:foo-wrapped');
            })
            .on('bar', function() {
                output.push('ee2:bar-wrapped');
            });

        ee1
            .on('foo', function() {
                output.push('ee1:foo');
            })
            .on('bar', function() {
                output.push('ee1:bar');
            });

        ee2
            .on('foo', function() {
                output.push('ee2:foo');
            })
            .on('bar', function() {
                output.push('ee2:bar');
            });

        ee1.emit('foo');
        ee2.emit('foo');
        ee1.emit('bar');
        ee2.emit('bar');

        expect(output).to.deep.equal([
            'ee1:foo-wrapped', 'ee1:foo', 'ee2:foo-wrapped', 'ee2:foo',
            'ee1:bar-wrapped', 'ee1:bar', 'ee2:bar-wrapped', 'ee2:bar']);

        tracker.removeAllListeners(ee1, 'foo');

        ee1.emit('foo');
        ee2.emit('foo');
        ee1.emit('bar');
        ee2.emit('bar');

        expect(output).to.deep.equal([
            'ee1:foo-wrapped', 'ee1:foo', 'ee2:foo-wrapped', 'ee2:foo',
            'ee1:bar-wrapped', 'ee1:bar', 'ee2:bar-wrapped', 'ee2:bar',
            'ee1:foo', 'ee2:foo-wrapped', 'ee2:foo',
            'ee1:bar-wrapped', 'ee1:bar', 'ee2:bar-wrapped', 'ee2:bar']);
    });

    it('should handle destroy for a single emitter', function() {
        var ee = new EventEmitter();
        var wrapped = listenerTracker.wrap(ee);

        var output = [];

        wrapped.on('foo', function() {
            output.push('foo-wrapped');
        });

        wrapped.on('bar', function() {
            output.push('bar-wrapped');
        });

        expect(wrapped.$__listeners.length).to.equal(2);
        ee.emit('destroy');
        expect(wrapped.$__listeners.length).to.equal(0);
    });

    it('should handle destroy for multiple emitters', function() {


        var tracker = listenerTracker.createTracker();
        var ee1 = new EventEmitter();
        var ee2 = new EventEmitter();

        var output = [];

        tracker.subscribeTo(ee1)
            .on('foo', function() {
                output.push('ee1:foo-wrapped');
            })
            .on('bar', function() {
                output.push('ee1:bar-wrapped');
            });

        tracker.subscribeTo(ee2)
            .on('foo', function() {
                output.push('ee2:foo-wrapped');
            })
            .on('bar', function() {
                output.push('ee2:bar-wrapped');
            });

        expect(tracker.$__subscribeToList.length).to.equal(2);
        ee1.emit('destroy');
        expect(tracker.$__subscribeToList.length).to.equal(1);

    });

    it('should auto-unsubscribe when target is destroyed', function() {


        var tracker = listenerTracker.createTracker();
        var ee = new EventEmitter();

        var fooEvent = null;

        tracker.subscribeTo(ee)
            .on('foo', function() {
                fooEvent = arguments;
            });

        expect(ee.listeners('destroy').length).to.equal(1);

        ee.emit('foo', 'a', 'b');

        expect(fooEvent[0]).to.equal('a');
        expect(fooEvent[1]).to.equal('b');

        fooEvent = null;

        ee.emit('destroy');

        ee.emit('foo', 'a', 'b');

        expect(fooEvent).to.equal(null);
    });

    it('should provide option to not attach "destroy" listener on target', function() {


        var tracker = listenerTracker.createTracker();
        var ee = new EventEmitter();

        var fooEvent = null;

        tracker.subscribeTo(ee, {addDestroyListener: false})
            .on('foo', function() {
                fooEvent = arguments;
            });

        expect(ee.listeners('destroy').length).to.equal(0);
    });

    it('[SubscriptionTracker] should do proper cleanup when a wrapped EventEmitter has no more listeners', function() {
        var tracker = listenerTracker.createTracker();

        var ee = new EventEmitter();
        var removed = false;

        expect(tracker.$__subscribeToList.length).to.equal(0);

        tracker.subscribeTo(ee, { addDestroyListener: false })
            .once('removed', function() {
                removed = true;
            });

        expect(tracker.$__subscribeToList.length).to.equal(1);
        expect(removed).to.equal(false);

        ee.emit('removed');

        expect(removed).to.equal(true);

        expect(tracker.$__subscribeToList.length).to.equal(0);
    });

    it('[EventEmitterWrapper] should do proper cleanup for a `once` event', function() {
        var ee = new EventEmitter();

        var eeWrapped = listenerTracker.wrap(ee);

        expect(eeWrapped.$__listeners.length).to.equal(0);

        var fooEmitted = false;

        eeWrapped.once('foo', function() {
            fooEmitted = true;
        });

        expect(eeWrapped.$__listeners.length).to.equal(1);

        ee.emit('foo');

        expect(eeWrapped.$__listeners.length).to.equal(0);
    });

    it('[EventEmitterWrapper] should allow a `once` event listener to be removed', function() {
        var ee = new EventEmitter();

        var eeWrapped = listenerTracker.wrap(ee);

        expect(eeWrapped.$__listeners.length).to.equal(0);

        var fooEmitted = false;

        function fooListener() {
            fooEmitted = true;
        }

        eeWrapped.once('foo', fooListener);

        expect(eeWrapped.$__listeners.length).to.equal(1);


        eeWrapped.removeListener('foo', fooListener);

        ee.emit('foo');

        expect(fooEmitted).to.equal(false);

        expect(eeWrapped.$__listeners.length).to.equal(0);
    });

    it('[EventEmitterWrapper] should allow an `on` event listener to be removed', function() {
        var ee = new EventEmitter();

        var eeWrapped = listenerTracker.wrap(ee);

        expect(eeWrapped.$__listeners.length).to.equal(0);

        var fooEmitted = false;

        function fooListener() {
            fooEmitted = true;
        }

        eeWrapped.on('foo', fooListener);

        expect(eeWrapped.$__listeners.length).to.equal(1);


        eeWrapped.removeListener('foo', fooListener);

        ee.emit('foo');

        expect(fooEmitted).to.equal(false);

        expect(eeWrapped.$__listeners.length).to.equal(0);
    });

});