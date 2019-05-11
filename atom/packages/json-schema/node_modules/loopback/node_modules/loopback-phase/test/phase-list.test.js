var PhaseList = require('../').PhaseList;
var Phase = require('../').Phase;
var expect = require('chai').expect;

describe('PhaseList', function() {
  var phaseList;

  beforeEach(function createEmptyPhaseList() {
    phaseList = new PhaseList();
  });

  describe('phaseList.find(phaseName)', function() {
    it('should find a phase by phaseName', function() {
      var phase = phaseList.add('test');
      expect(phase).to.eql(phaseList.find('test'));
    });
  });

  describe('phaseList.findOrAdd(phaseName)', function() {
    it('should always return a phase', function() {
      var randomKey = Math.random().toString();
      var phase = phaseList.findOrAdd(randomKey);
      expect(phase.id).to.equal(randomKey);
    });
  });

  describe('phaseList.add(phaseName)', function() {
    it('should add a phase to the list', function() {
      var phase = new Phase('myPhase');
      phaseList.add(phase);
      var result = phaseList.find('myPhase');
      expect(result).to.equal(phase);
    });
    it('should create a phase and add it to the list', function() {
      phaseList.add('myPhase');
      var result = phaseList.find('myPhase');
      expect(result.id).to.equal('myPhase');
    });
    it('should create and add an array oh phases', function() {
      phaseList.add(['foo', 'bar']);
      var foo = phaseList.find('foo');
      var bar = phaseList.find('bar');
      expect(foo.id).to.equal('foo');
      expect(bar.id).to.equal('bar');
    });

    it('should throw when adding an existing phase', function() {
      phaseList.add('a-name');
      expect(function() { phaseList.add('a-name'); })
        .to.throw(/a-name/);
    });
  });

  describe('phaseList.remove(phaseName)', function() {
    it('should remove a phase from the list', function() {
      var phase = new Phase('myPhase');
      phaseList.add(phase);
      var result = phaseList.find('myPhase');
      expect(result).to.equal(phase);
      phaseList.remove(phase.id);
      expect(phaseList.find('myPhase')).to.equal(null);
    });

    it('should not remove any phase if phase is not in the list', function() {
      var phase = new Phase('myPhase');
      phaseList.add('bar');
      var result = phaseList.find('myPhase');
      expect(result).to.equal(null);
      var removed = phaseList.remove(phase.id);
      expect(removed).to.equal(null);
      expect(phaseList.getPhaseNames()).to.eql(['bar']);
    });
  });

  describe('phases.toArray()', function() {
    it('should return the list of phases as an array', function() {
      var names = ['a', 'b'];

      phaseList.add(names);

      var result = phaseList
        .toArray()
        .map(function(phase) {
          return phase.id;
        });

      expect(names).to.eql(result);
    });
  });

  describe('phaseList.run(ctx, cb)', function() {
    it('runs phases in the correct order', function(done) {
      var called = [];

      phaseList.add(['one', 'two']);

      phaseList.find('one').use(function(ctx, cb) {
        expect(ctx.hello).to.equal('world');
        setTimeout(function() {
          called.push('one');
          cb();
        }, 1);
      });

      phaseList.find('two').use(function(ctx, cb) {
        called.push('two');
        cb();
      });

      phaseList.run({ hello: 'world' }, function(err) {
        if (err) return done(err);
        expect(called).to.eql(['one', 'two']);
        done();
      });
    });
  });

  describe('phaseList.getPhaseNames()', function() {

  });

  describe('phaseList.addAt', function() {
    it('adds the phase at an expected index', function() {
      phaseList.add(['start', 'end']);
      phaseList.addAt(1, 'middle');
      expect(phaseList.getPhaseNames()).to.eql(['start', 'middle', 'end']);
    });
  });

  describe('phaseList.addAfter', function() {
    it('adds the phase at an expected position', function() {
      phaseList.add(['start', 'end']);
      phaseList.addAfter('start', 'middle');
      phaseList.addAfter('end', 'last');
      expect(phaseList.getPhaseNames())
        .to.eql(['start', 'middle', 'end', 'last']);
    });

    it('throws when the "after" phase was not found', function() {
      expect(function() { phaseList.addAfter('unknown-phase', 'a-name'); })
        .to.throw(/unknown-phase/);
    });
  });

  describe('phaseList.addBefore', function() {
    it('adds the phase at an expected position', function() {
      phaseList.add(['start', 'end']);
      phaseList.addBefore('start', 'first');
      phaseList.addBefore('end', 'middle');
      expect(phaseList.getPhaseNames())
        .to.eql(['first', 'start', 'middle', 'end']);
    });

    it('throws when the "before" phase was not found', function() {
      expect(function() { phaseList.addBefore('unknown-phase', 'a-name'); })
        .to.throw(/unknown-phase/);
    });
  });

  describe('phaseList.zipMerge(phases)', function() {
    it('merges phases preserving the order', function() {
      phaseList.add(['initial', 'session', 'auth', 'routes', 'files', 'final']);
      phaseList.zipMerge([
        'initial',
        'postinit', 'preauth', // add
        'auth', 'routes',
        'subapps', // add
        'final',
        'last' // add
      ]);

      expect(phaseList.getPhaseNames()).to.eql([
        'initial',
        'postinit', 'preauth', // new
        'session', 'auth', 'routes',
        'subapps', // new
        'files', 'final',
        'last' // new
      ]);
    });

    it('starts adding phases from the start', function() {
      phaseList.add(['start', 'end']);
      phaseList.zipMerge(['first', 'end', 'last']);
      expect(phaseList.getPhaseNames())
        .to.eql(['first', 'start', 'end', 'last']);
    });
  });
});
