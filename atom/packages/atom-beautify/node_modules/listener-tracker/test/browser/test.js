/* globals document, window, describe, beforeEach, it */
'use strict';

var chai = require('chai');
chai.config.includeStack = true;
var expect = chai.expect;
var listenerTracker = require('./../..');

var createEvent = function(type) {
    var event = document.createEvent("HTMLEvents");
    event.initEvent(type, true, true);
    return event;
};

var wrapped;
var output;
var tracker;
var paragraphEl = document.createElement("p");
document.getElementsByTagName("body")[0].appendChild(paragraphEl);
var TEST = "test";
var ONCE = "once";
var MESSAGE = "works";
var OUTPUT = [MESSAGE, ONCE];
var testEvent = createEvent(TEST);
var onceEvent = createEvent(ONCE);
var testFunc = function() {
    output.push(MESSAGE);
};
var onceFunc = function() {
    output.push(ONCE);
};

describe('Non EventEmitter Wrap Suite' , function() {
    beforeEach(function() {
        output = [];
        wrapped = listenerTracker.wrap(paragraphEl);
        wrapped.on(TEST, testFunc);
        wrapped.once(ONCE, onceFunc);
        paragraphEl.dispatchEvent(testEvent);
        paragraphEl.dispatchEvent(onceEvent);
    });

    it('tests on', function() {
        expect(output).to.eql(OUTPUT);
    });

    it('tests once', function() {
        expect(output).to.eql(OUTPUT);
        paragraphEl.dispatchEvent(onceEvent);
        expect(output).to.eql(OUTPUT);
    });

    it('tests removeAllListeners for event', function() {
        expect(output).to.eql(OUTPUT);

        wrapped.removeAllListeners(TEST);
        paragraphEl.dispatchEvent(testEvent);
        expect(output).to.eql(OUTPUT);
    });

    it('tests removeAllListeners', function() {
        expect(output).to.eql(OUTPUT);

        wrapped.removeAllListeners();
        paragraphEl.dispatchEvent(testEvent);
        expect(output).to.eql(OUTPUT);
    });
});

describe('Non EventEmitter Tracker Suite' , function() {
    beforeEach(function() {
        output = [];
        tracker = listenerTracker.createTracker();
        tracker.subscribeTo(window).on(TEST, testFunc);
        tracker.subscribeTo(window).once(ONCE, onceFunc);
        window.dispatchEvent(testEvent);
        window.dispatchEvent(onceEvent);
    });

    it('tests on', function() {
        expect(output).to.eql(OUTPUT);
    });

    it('tests once', function() {
        expect(output).to.eql(OUTPUT);
        window.dispatchEvent(onceEvent);
        expect(output).to.eql(OUTPUT);
    });

    it('tests removeAllListeners for event', function() {
        expect(output).to.eql(OUTPUT);

        tracker.removeAllListeners();
        window.dispatchEvent(testEvent);
        expect(output).to.eql(OUTPUT);
    });
});
