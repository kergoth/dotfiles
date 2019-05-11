'use strict';
require('../'); // Load the module
var chai = require('chai');
chai.config.includeStack = true;
var expect = require('chai').expect;

var transport = require('../');

describe('lasso-modules-client/transport/codeGenerators/installed' , function() {


    it('should generate correct dependency code for top-level dependency', function() {
        var code = transport.codeGenerators.installed('/app$1.0.0', 'foo', '1.0.0');
        expect(code).to.equal('$_mod.installed("app$1.0.0", "foo", "1.0.0");');
    });
});

