'use strict';

var chai = require('chai');
chai.config.includeStack = true;
var expect = require('chai').expect;

var transport = require('../');

describe('lasso-modules-client/transport/codeGenerators/main' , function() {

    it('should generate correct code', function() {
        var code = transport.codeGenerators.main('/foo$1.0.0', 'lib/index');
        expect(code).to.equal('$_mod.main("/foo$1.0.0", "lib/index");');
    });
});

