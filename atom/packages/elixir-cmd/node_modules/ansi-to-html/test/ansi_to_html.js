(function() {
  var Filter, expect, test;

  Filter = require('../lib/ansi_to_html.js');

  expect = require('chai').expect;

  test = function(text, result, done, opts) {
    var f, filtered;
    if (opts == null) {
      opts = {};
    }
    f = new Filter(opts);
    filtered = function(memo, t) {
      return memo += f.toHtml(t);
    };
    text = typeof text.reduce === 'function' ? text : [text];
    expect(text.reduce(filtered, '')).to.equal(result);
    return done();
  };

  describe('ansi to html', function() {
    describe('constructed with no options', function() {
      it("doesn't modify the input string", function(done) {
        var result, text;
        text = result = 'some text';
        return test(text, result, done);
      });
      it('returns plain text when given plain text', function(done) {
        var result, text;
        text = 'test\ntest\n';
        result = 'test\ntest\n';
        return test(text, result, done);
      });
      it('renders foreground colors', function(done) {
        var result, text;
        text = "colors: \x1b[30mblack\x1b[37mwhite";
        result = 'colors: <span style="color:#000">black<span style="color:' + '#AAA">white</span></span>';
        return test(text, result, done);
      });
      it('renders light foreground colors', function(done) {
        var result, text;
        text = 'colors: \x1b[90mblack\x1b[97mwhite';
        result = 'colors: <span style="color:#555">black<span style="color:' + '#FFF">white</span></span>';
        return test(text, result, done);
      });
      it('renders background colors', function(done) {
        var result, text;
        text = 'colors: \x1b[40mblack\x1b[47mwhite';
        result = 'colors: <span style="background-color:#000">black<span ' + 'style="background-color:#AAA">white</span></span>';
        return test(text, result, done);
      });
      it('renders light background colors', function(done) {
        var result, text;
        text = 'colors: \x1b[100mblack\x1b[107mwhite';
        result = 'colors: <span style="background-color:#555">black<span ' + 'style="background-color:#FFF">white</span></span>';
        return test(text, result, done);
      });
      it('renders strikethrough', function(done) {
        var result, text;
        text = 'strike: \x1b[9mthat';
        result = 'strike: <strike>that</strike>';
        return test(text, result, done);
      });
      it('renders blink', function(done) {
        var result, text;
        text = 'blink: \x1b[5mwhat';
        result = 'blink: <blink>what</blink>';
        return test(text, result, done);
      });
      it('renders underline', function(done) {
        var result, text;
        text = 'underline: \x1b[3mstuff';
        result = 'underline: <u>stuff</u>';
        return test(text, result, done);
      });
      it('renders bold', function(done) {
        var result, text;
        text = 'bold: \x1b[1mstuff';
        result = 'bold: <b>stuff</b>';
        return test(text, result, done);
      });
      it('handles ressets', function(done) {
        var result, text;
        text = '\x1b[1mthis is bold\x1b[0m, but this isn\'t';
        result = '<b>this is bold</b>, but this isn\'t';
        return test(text, result, done);
      });
      it('handles multiple resets', function(done) {
        var result, text;
        text = 'normal, \x1b[1mbold, \x1b[3munderline, \x1b[31mred\x1b[0m, normal';
        result = 'normal, <b>bold, <u>underline, <span style="color:' + '#A00">red</span></u></b>, normal';
        return test(text, result, done);
      });
      it('handles resets with implicit 0', function(done) {
        var result, text;
        text = '\x1b[1mthis is bold\x1b[m, but this isn\'t';
        result = '<b>this is bold</b>, but this isn\'t';
        return test(text, result, done);
      });
      it('renders multi-attribute sequences', function(done) {
        var result, text;
        text = 'normal, \x1b[1;3;31mbold, underline, and red\x1b[0m, normal';
        result = 'normal, <b><u><span style="color:#A00">bold, underline,' + ' and red</span></u></b>, normal';
        return test(text, result, done);
      });
      it('renders multi-attribute sequences with a semi-colon', function(done) {
        var result, text;
        text = 'normal, \x1b[1;3;31;mbold, underline, and red\x1b[0m, normal';
        result = 'normal, <b><u><span style="color:#A00">bold, underline, ' + 'and red</span></u></b>, normal';
        return test(text, result, done);
      });
      it('eats malformed sequences', function(done) {
        var result, text;
        text = '\x1b[25oops forgot the \'m\'';
        result = 'oops forgot the \'m\'';
        return test(text, result, done);
      });
      it('renders xterm 256 sequences', function(done) {
        var result, text;
        text = '\x1b[38;5;196mhello';
        result = '<span style="color:#ff0000">hello</span>';
        return test(text, result, done);
      });
      it('handles resetting to default foreground color', function(done) {
        var result, text;
        text = '\x1b[30mblack\x1b[39mdefault';
        result = '<span style="color:#000">black<span style="color:#FFF">' + 'default</span></span>';
        return test(text, result, done);
      });
      it('handles resetting to default background color', function(done) {
        var result, text;
        text = '\x1b[100mblack\x1b[49mdefault';
        result = '<span style="background-color:#555">black<span style=' + '"background-color:#000">default</span></span>';
        return test(text, result, done);
      });
      it('is able to disable underline', function(done) {
        var result, text;
        text = 'underline: \x1b[4mstuff\x1b[24mthings';
        result = 'underline: <u>stuff</u>things';
        return test(text, result, done);
      });
      it('renders two escape sequences in sequence', function(done) {
        var result, text;
        text = 'months remaining\x1b[1;31mtimes\x1b[m\x1b[1;32mmultiplied' + ' by\x1b[m $10';
        result = 'months remaining<b><span style="color:#A00">times</span>' + '</b><b><span style="color:#0A0">multiplied by</span></b> $10';
        return test(text, result, done);
      });
      it('drops EL code with no parameter', function(done) {
        var result, text;
        text = '\x1b[Khello';
        result = 'hello';
        return test(text, result, done);
      });
      it('drops EL code with 0 parameter', function(done) {
        var result, text;
        text = '\x1b[0Khello';
        result = 'hello';
        return test(text, result, done);
      });
      it('drops EL code with 1 parameter', function(done) {
        var result, text;
        text = '\x1b[1Khello';
        result = 'hello';
        return test(text, result, done);
      });
      return it('drops EL code with 2 parameter', function(done) {
        var result, text;
        text = '\x1b[2Khello';
        result = 'hello';
        return test(text, result, done);
      });
    });
    describe('with escapeXML option enabled', function() {
      return it('escapes XML entities', function(done) {
        var result, text;
        text = 'normal, \x1b[1;3;31;mbold, <underline>, and red\x1b[0m, normal';
        result = 'normal, <b><u><span style="color:#A00">bold, &lt;underline' + '&gt;, and red</span></u></b>, normal';
        return test(text, result, done, {
          escapeXML: true
        });
      });
    });
    describe('with newline option enabled', function() {
      return it('renders line breaks', function(done) {
        var result, text;
        text = 'test\ntest\n';
        result = 'test<br/>test<br/>';
        return test(text, result, done, {
          newline: true
        });
      });
    });
    return describe('with stream option enabled', function() {
      it('persists styles between toHtml() invocations', function(done) {
        var result, text;
        text = ['\x1b[31mred', 'also red'];
        result = '<span style="color:#A00">red</span><span style="color:' + '#A00">also red</span>';
        return test(text, result, done, {
          stream: true
        });
      });
      it('persists styles between more than two toHtml() invocations', function(done) {
        var result, text;
        text = ['\x1b[31mred', 'also red', 'and red'];
        result = '<span style="color:#A00">red</span><span style="color:' + '#A00">also red</span><span style="color:#A00">and red</span>';
        return test(text, result, done, {
          stream: true
        });
      });
      it('does not persist styles beyond their usefulness', function(done) {
        var result, text;
        text = ['\x1b[31mred', 'also red', '\x1b[30mblack', 'and black'];
        result = '<span style="color:#A00">red</span><span style="color:' + '#A00">also red</span><span style="color:#A00"><span style="color:' + '#000">black</span></span><span style="color:#000">and black</span>';
        return test(text, result, done, {
          stream: true
        });
      });
      return it('removes all state when encountering a reset', function(done) {
        var result, text;
        text = ['\x1b[1mthis is bold\x1b[0m, but this isn\'t', ' nor is this'];
        result = '<b>this is bold</b>, but this isn\'t nor is this';
        return test(text, result, done, {
          stream: true
        });
      });
    });
  });

}).call(this);
