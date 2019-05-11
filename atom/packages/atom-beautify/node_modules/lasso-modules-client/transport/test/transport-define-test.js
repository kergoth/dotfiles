'use strict';
require('../'); // Load the module
var nodePath = require('path');
var chai = require('chai');
chai.config.includeStack = true;
var expect = require('chai').expect;
var fs = require('fs');

var transport = require('../');

describe('lasso-modules-client/transport/codeGenerators/define' , function() {


    it('should handle String argument for factory function code', function() {
        var code = transport.codeGenerators.define('/some/path', 'exports.test=true;');
        expect(code).to.equal('$_mod.def("/some/path", function(require, exports, module, __filename, __dirname) { exports.test=true;\n});');
    });

    it('should handle String argument for object code', function() {
        var code = transport.codeGenerators.define('/some/path', '{ "hello": "world" }', {object: true});
        expect(code).to.equal('$_mod.def("/some/path", { "hello": "world" });');
    });

    it('should handle String argument for factory function code', function() {
        var moduleCode = fs.readFileSync(nodePath.join(__dirname, 'fixtures/test.js'), {encoding: 'utf8'});
        var code = transport.codeGenerators.define('/some/path', moduleCode);
        expect(code).to.equal('$_mod.def("/some/path", function(require, exports, module, __filename, __dirname) { exports.test=true;\n});');
    });

    it('should handle Stream argument for object code', function() {
        var objectCode = fs.readFileSync(nodePath.join(__dirname, 'fixtures/test.json'), {encoding: 'utf8'});
        var code = transport.codeGenerators.define('/some/path', objectCode, {object: true});
        expect(code).to.equal('$_mod.def("/some/path", { "hello": "world" });');
    });

    it('should support "globalName" option', function() {
        var code = transport.codeGenerators.define('/some/path', 'exports.test=true;', {globals: ['$']});
        expect(code).to.equal('$_mod.def("/some/path", function(require, exports, module, __filename, __dirname) { exports.test=true;\n},{"globals":["$"]});');
    });

    it('should allow additional vars (no "use strict")', function() {
        var code = transport.codeGenerators.define('/some/path', 'exports.test=true;', {
            additionalVars: [
                'foo="bar"'
            ]
        });

        expect(code).to.equal('$_mod.def("/some/path", function(require, exports, module, __filename, __dirname) { var foo="bar"; exports.test=true;\n});');
    });

    it('should allow additional vars ("use strict";)', function() {
        var code = transport.codeGenerators.define('/some/path', '"use strict";\nexports.test=true;', {
            additionalVars: [
                'foo="bar"'
            ]
        });

        expect(code).to.equal('$_mod.def("/some/path", function(require, exports, module, __filename, __dirname) { "use strict";var foo="bar"; \nexports.test=true;\n});');
    });

    it('should allow additional vars (\'use strict\';)', function() {
        var code = transport.codeGenerators.define('/some/path', '\'use strict\';\nexports.test=true;', {
            additionalVars: [
                'foo="bar"'
            ]
        });

        expect(code).to.equal('$_mod.def("/some/path", function(require, exports, module, __filename, __dirname) { \'use strict\';var foo="bar"; \nexports.test=true;\n});');
    });

    it('should allow additional vars ("use strict", no semicolon)', function() {
        var code = transport.codeGenerators.define('/some/path', '"use strict" \nexports.test=true;', {
            additionalVars: [
                'foo="bar"'
            ]
        });

        expect(code).to.equal('$_mod.def("/some/path", function(require, exports, module, __filename, __dirname) { "use strict" \nvar foo="bar"; exports.test=true;\n});');
    });

    it('should allow additional vars ("use strict", after multiline comment)', function() {
        var code = transport.codeGenerators.define('/some/path', '/* hello world */\n/*more comments*/\n// Test comment\n   \n"use strict" \nexports.test=true;', {
            additionalVars: [
                'foo="bar"'
            ]
        });

        expect(code).to.equal('$_mod.def("/some/path", function(require, exports, module, __filename, __dirname) { /* hello world */\n/*more comments*/\n// Test comment\n   \n"use strict" \nvar foo=\"bar\"; exports.test=true;\n});');
    });

});

