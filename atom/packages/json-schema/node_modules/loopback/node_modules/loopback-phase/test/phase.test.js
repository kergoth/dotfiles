var assert = require('assert');
var expect = require('chai').expect;
var Phase = require('../').Phase;

describe('Phase', function() {
  describe('phase.run(ctx, cb)', function() {
    it('should execute phase handlers', function (done) {
      var phase = new Phase();
      var called = false;
      phase.use(function(ctx, cb) {
        called = true;
        cb();
      });
      phase.run(function() {
        assert(called === true);
        done();
      });
    });

    it('should set the context for handlers', function (done) {
      var phase = new Phase();
      phase.use(function(ctx, cb) {
        expect(ctx).to.have.property('foo', 'bar');
        cb();
      });
      phase.run({foo: 'bar'}, done);
    });

    describe('execution order', function() {
      var called;
      var mockHandler;

      beforeEach(function() {
        called = [];
        mockHandler = function(name) {
          return function(ctx, cb) {
            called.push(name);
            process.nextTick(function() {
              called.push(name + '_done');
              cb();
            });
          };
        };
      });

      it('should execute phase handlers in parallel', function(done) {
        var phase = new Phase({parallel: true});

        phase.before(mockHandler('b1'))
          .before(mockHandler('b2'))
          .use(mockHandler('h1'))
          .after(mockHandler('a1'))
          .after(mockHandler('a2'))
          .use(mockHandler('h2'));

        phase.run(function() {
          var orders = {};
          called.forEach(function(h, index) {
            orders[h] = index;
          });
          expect(called).to.eql(['b1', 'b2', 'b1_done', 'b2_done',
            'h1', 'h2', 'h1_done', 'h2_done',
            'a1', 'a2', 'a1_done', 'a2_done']);
          done();
        });
      });

      it('should execute phase handlers in serial', function(done) {
        var phase = new Phase('x');

        phase.before(mockHandler('b1'))
          .before(mockHandler('b2'))
          .use(mockHandler('h1'))
          .after(mockHandler('a1'))
          .after(mockHandler('a2'))
          .use(mockHandler('h2'));
        phase.run(function() {
          expect(called).to.eql(['b1', 'b1_done', 'b2', 'b2_done',
            'h1', 'h1_done', 'h2', 'h2_done',
            'a1', 'a1_done', 'a2', 'a2_done']);
          done();
        });
      });
    });
  });

  describe('phase.use(handler)', function() {
    it('should add a handler that is invoked during a phase', function (done) {
      var phase = new Phase();
      var invoked = false;
      phase.use(function(ctx, cb) {
        invoked = true;
        cb();
      });
      phase.run(function() {
        expect(invoked).to.equal(true);
        done();
      });
    });
  });

  describe('phase.after(handler)', function() {
    it('should add a handler that is invoked after a phase', function (done) {
      var phase = new Phase('test');
      phase
        .use(function(ctx, cb) {
          ctx.foo = 'ba';
          cb();
        })
        .use(function(ctx, cb) {
          ctx.foo = ctx.foo + 'r';
          cb();
        });
      phase.after(function(ctx, cb) {
        assert(ctx.foo === 'bar');
        cb();
      });
      phase.run(done);
    });
  });
});
