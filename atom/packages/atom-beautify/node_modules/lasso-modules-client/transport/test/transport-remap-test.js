'use strict';
require('../'); // Load the module
var chai = require('chai');
chai.config.includeStack = true;
var expect = require('chai').expect;

var transport = require('../');

describe('lasso-modules-client/transport/codeGenerators/remap' , function() {
    it('should generate correct code', function() {
        var code = transport.codeGenerators.remap('/foo$1.0.0/lib/index', '/foo$1.0.0/lib/index-browser');
        expect(code).to.equal('$_mod.remap("/foo$1.0.0/lib/index", "/foo$1.0.0/lib/index-browser");');
    });
});

