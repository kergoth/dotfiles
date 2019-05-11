'use strict';
var chai = require('chai');
chai.config.includeStack = true;
var expect = require('chai').expect;

var transport = require('../');

describe('lasso-modules-client/transport/codeGenerators/run' , function() {


    it('should handle run code for some path', function() {
        var code = transport.codeGenerators.run('/some/path');
        expect(code).to.equal('$_mod.run("/some/path");');
    });

});

