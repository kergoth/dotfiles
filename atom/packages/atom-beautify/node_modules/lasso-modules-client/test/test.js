'use strict';

var chai = require('chai');
chai.config.includeStack = true;
var expect = chai.expect;
var assert = chai.assert;

describe('lasso-modules-client' , function() {

    beforeEach(function(done) {
        for (var k in require.cache) {
            if (require.cache[k]) {
                delete require.cache[k];
            }
        }
        done();
    });

    it('should throw error if trying to resolve target that is falsey', function() {
        var clientImpl = require('../');

        clientImpl.ready();

        clientImpl.def('/app$1.0.0/launch/index', function(require, exports, module, __filename, __dirname) {
            try {
                require.resolve('', '/some/module');
                assert(false, 'Exception should have been thrown');
            } catch(err) {
                expect(err.code).to.equal('MODULE_NOT_FOUND');
            }

            try {
                require.resolve(null, '/some/module');
                assert(false, 'Exception should have been thrown');
            } catch(err) {
                expect(err.code).to.equal('MODULE_NOT_FOUND');
            }

            try {
                require.resolve(undefined, '/some/module');
                assert(false, 'Exception should have been thrown');
            } catch(err) {
                expect(err.code).to.equal('MODULE_NOT_FOUND');
            }

            try {
                require.resolve(0, '/some/module');
                assert(false, 'Exception should have been thrown');
            } catch(err) {
                expect(err.code).to.equal('MODULE_NOT_FOUND');
            }
        });

        clientImpl.run('/app$1.0.0/launch/index');
    });

    it('should resolve modules using search path', function(done) {
        var clientImpl = require('../');

        // define a module for a given real path
        clientImpl.def('/baz$3.0.0/lib/index', function(require, exports, module, __filename, __dirname) {
            module.exports.test = true;
        });

        // Module "foo" requires "baz" 3.0.0
        clientImpl.installed('foo$1.0.0', 'baz', '3.0.0');


        var resolved;

        // Make sure that if we try to resolve "baz/lib/index" from within some module
        // located at "/$/foo" then we should get back "/$/foo/$/baz"
        resolved = clientImpl.resolve('baz/lib/index', '/foo$1.0.0');
        expect(resolved[0]).to.equal('/baz$3.0.0/lib/index');

        // A module further nested under foo should also resolve to the same
        // logical path
        resolved = clientImpl.resolve('baz/lib/index', '/foo$1.0.0/some/other/module');
        expect(resolved[0]).to.equal('/baz$3.0.0/lib/index');

        // Code at under "/some/module" doesn't know about baz
        resolved = clientImpl.resolve('baz/lib/index', '/hello$1.0.0/some/module');
        expect(resolved).to.equal(undefined);

        done();
    });

    it('should resolve absolute paths not containing installed modules', function(done) {
        var clientImpl = require('../');
        clientImpl.ready();

        var resolved;

        // define a module for a given real path
        clientImpl.def('/my-app$1.0.0/util', function(require, exports, module, __filename, __dirname) {
            module.exports.test = true;
        });

        resolved = clientImpl.resolve(
            '/my-app$1.0.0/util' /* target is absolute path to specific version of module */,
            '/my-app$1.0.0/whatever' /* from is ignored if target is absolute path */);

        expect(resolved[0]).to.equal('/my-app$1.0.0/util');

        done();
    });

    it('should resolve absolute paths containing installed modules', function() {

        var clientImpl = require('../');
        clientImpl.ready();

        var resolved;

        // define a module for a given real path
        clientImpl.def('/baz$3.0.0/lib/index', function(require, exports, module, __filename, __dirname) {
            module.exports.test = true;
        });

        // Module "foo" requires "baz" 3.0.0
        // This will create the following link:
        // /$/foo/$/baz --> baz$3.0.0
        clientImpl.installed('foo$1.0.0', 'baz', '3.0.0');

        clientImpl.ready();

        resolved = clientImpl.resolve(
            '/baz$3.0.0/lib/index' /* target is absolute path to specific version of module */,
            'whatever' /* from is ignored if target is absolute path */);

        expect(resolved[0]).to.equal('/baz$3.0.0/lib/index');

        clientImpl.def('/app$1.0.0/launch/index', function(require, exports, module, __filename, __dirname) {
            expect(function() {
                // Without registering "main", "/baz$3.0.0" will not be known
                resolved = require.resolve('/baz$3.0.0', '/some/module');
            }).to.throw(Error);
        });

        clientImpl.run('/app$1.0.0/launch/index');
    });

    it('should instantiate modules', function(done) {
        var clientImpl = require('../');
        clientImpl.ready();

        var instanceCount = 0;

        // define a module for a given real path
        clientImpl.def('/baz$3.0.0/lib/index', function(require, exports, module, __filename, __dirname) {
            instanceCount++;

            expect(module.id).to.equal('/baz$3.0.0/lib/index');
            expect(module.filename).to.equal('/baz$3.0.0/lib/index');

            module.exports = {
                __filename: __filename,
                __dirname: __dirname
            };
        });

        // Module "foo" requires "baz" 3.0.0
        // This will create the following link:
        // /$/foo/$/baz --> baz$3.0.0
        clientImpl.installed('foo$1.0.0', 'baz', '3.0.0');

        var baz = clientImpl.require('baz/lib/index', '/foo$1.0.0/hello');

        expect(instanceCount).to.equal(1);

        expect(baz.__filename).to.equal('/baz$3.0.0/lib/index');
        expect(baz.__dirname).to.equal('/baz$3.0.0/lib');

        clientImpl.require('baz/lib/index', '/foo$1.0.0/hello');

        expect(instanceCount).to.equal(1);

        done();
    });

    it('should instantiate multiple instances of module if loaded from separate logical paths', function(done) {
        var clientImpl = require('../');
        clientImpl.ready();

        var instanceCount = 0;

        // define a module for a given real path
        clientImpl.def('/baz$3.0.0/lib/index', function(require, exports, module, __filename, __dirname) {
            instanceCount++;

            module.exports = {
                __filename: __filename,
                __dirname: __dirname,
                moduleId: module.id,
                moduleFilename: module.filename
            };
        });

        // Module "foo" requires "baz" 3.0.0
        // This will create the following link:
        // /$/foo/$/baz --> baz$3.0.0
        clientImpl.installed('foo$1.0.0', 'baz', '3.0.0');

        // Module "foo" requires "baz" 3.0.0
        // This will create the following link:
        // /$/bar/$/baz --> baz$3.0.0
        clientImpl.installed('bar$2.0.0', 'baz', '3.0.0');

        var bazFromFoo = clientImpl.require('baz/lib/index', '/foo$1.0.0');
        expect(bazFromFoo.moduleId).to.equal('/baz$3.0.0/lib/index');
        expect(bazFromFoo.moduleFilename).to.equal('/baz$3.0.0/lib/index');

        expect(instanceCount).to.equal(1);

        var bazFromBar = clientImpl.require('baz/lib/index', '/bar$2.0.0');
        expect(bazFromBar.moduleId).to.equal('/baz$3.0.0/lib/index');
        expect(bazFromBar.moduleFilename).to.equal('/baz$3.0.0/lib/index');

        expect(instanceCount).to.equal(1);

        done();
    });

    it('should throw exception if required module is not found', function(done) {

        var clientImpl = require('../');
        clientImpl.ready();

        // define a module for a given real path
        clientImpl.def('/foo$1.0.0/lib/index', function(require, exports, module, __filename, __dirname) {
            expect(function() {
                require('something/that/does/not/exist');
            }).to.throw('Cannot find module "something/that/does/not/exist" from "/foo$1.0.0/lib"');
        });


        clientImpl.require('/foo$1.0.0/lib/index', 'whatever');

        done();
    });

    it('should load modules that are objects', function(done) {
        var clientImpl = require('../');
        clientImpl.ready();

        // define a module for a given real path
        clientImpl.def('/baz$3.0.0/lib/index', {
            test: true
        });

        // Module "foo" requires "baz" 3.0.0
        // This will create the following link:
        // /$/foo/$/baz --> baz$3.0.0
        clientImpl.installed('foo$1.0.0', 'baz', '3.0.0');

        var baz = clientImpl.require('baz/lib/index', '/foo$1.0.0');

        expect(baz.test).to.equal(true);

        done();
    });

    it('should run modules', function(done) {
        var clientImpl = require('../');
        clientImpl.ready();
        var instanceCount = 0;

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/launch/index', function(require, exports, module, __filename, __dirname) {
            instanceCount++;
            module.exports = {
                __filename: __filename,
                __dirname: __dirname
            };
        });

        clientImpl.run('/app$1.0.0/launch/index');

        // run will define the instance and automatically load it
        expect(instanceCount).to.equal(1);

        // you can also require the instance again if you really want to
        var launch = clientImpl.require('/app$1.0.0/launch/index', 'whatever');

        expect(instanceCount).to.equal(1);

        expect(launch.__filename).to.equal('/app$1.0.0/launch/index');
        expect(launch.__dirname).to.equal('/app$1.0.0/launch');

        // use a relative path to require it as well
        launch = clientImpl.require('./index', '/app$1.0.0/launch');

        expect(launch.__filename).to.equal('/app$1.0.0/launch/index');
        expect(launch.__dirname).to.equal('/app$1.0.0/launch');

        expect(instanceCount).to.equal(1);

        done();
    });

    it('should provide require function to module', function(done) {
        var clientImpl = require('../');
        clientImpl.ready();

        clientImpl.def('/app$1.0.0/launch/util', function(require, exports, module, __filename, __dirname) {
            module.exports.sayHello = function() {
                return 'Hello!';
            };
        });

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/launch/index', function(require, exports, module, __filename, __dirname) {

            var util;

            // test requesting
            util = require('./util');
            expect(Object.keys(util)).to.deep.equal(['sayHello']);

            // test requiring something via absolute path
            util = require('/app$1.0.0/launch/util');
            expect(Object.keys(util)).to.deep.equal(['sayHello']);

            module.exports = {
                greeting: util.sayHello()
            };
        });

        clientImpl.run('/app$1.0.0/launch/index');

        // you can also require the instance again if you really want to
        var launch = clientImpl.require('/app$1.0.0/launch/index', 'whatever');

        expect(launch.greeting).to.equal('Hello!');

        done();
    });

    it('should provide require function that has a resolve property', function(done) {

        var clientImpl = require('../');
        clientImpl.ready();

        clientImpl.def('/app$1.0.0/launch/util', function(require, exports, module, __filename, __dirname) {
            module.exports.sayHello = function() {
                return 'Hello!';
            };
        });

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/launch/index', function(require, exports, module, __filename, __dirname) {

            expect(require('./util')).to.equal(require(require.resolve('./util')));

            var util = require('./util');

            module.exports = {
                greeting: util.sayHello()
            };
        });

        clientImpl.run('/app$1.0.0/launch/index');

        done();

    });

    it('should not instantiate during require.resolve(target) call', function(done) {

        var clientImpl = require('../');
        clientImpl.ready();

        var instanceCount = 0;

        clientImpl.def('/app$1.0.0/launch/util', function(require, exports, module, __filename, __dirname) {
            instanceCount++;

            module.exports.sayHello = function() {
                return 'Hello!';
            };
        });

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/launch/index', function(require, exports, module, __filename, __dirname) {

            var path = require.resolve('./util');

            expect(path).to.equal('/app$1.0.0/launch/util');
            expect(instanceCount).to.equal(0);
        });

        clientImpl.run('/app$1.0.0/launch/index');

        done();

    });

    it('should allow factory to provide new exports', function(done) {

        var clientImpl = require('../');
        clientImpl.ready();

        clientImpl.def('/app$1.0.0/launch/util', function(require, exports, module, __filename, __dirname) {
            module.exports = {
                greeting: 'Hello!'
            };
        });

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/launch/index', function(require, exports, module, __filename, __dirname) {
            var util = require('./util');
            expect(util.greeting).to.equal('Hello!');
        });

        clientImpl.run('/app$1.0.0/launch/index');

        done();

    });

    it('should allow factory to add properties to export', function(done) {

        var clientImpl = require('../');
        clientImpl.ready();

        clientImpl.def('/app$1.0.0/launch/util', function(require, exports, module, __filename, __dirname) {
            module.exports.greeting = 'Hello!';
        });

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/launch/index', function(require, exports, module, __filename, __dirname) {
            var util = require('./util');
            expect(util.greeting).to.equal('Hello!');
        });

        clientImpl.run('/app$1.0.0/launch/index');

        done();
    });

    it('should allow factory to be an object', function(done) {

        var clientImpl = require('../');
        clientImpl.ready();

        clientImpl.def('/app$1.0.0/launch/util', {
            greeting: 'Hello!'
        });

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/launch/index', function(require, exports, module, __filename, __dirname) {
            var util = require('./util');
            expect(util.greeting).to.equal('Hello!');
        });

        clientImpl.run('/app$1.0.0/launch/index');

        done();
    });

    it('should allow factory to be null object', function(done) {

        /*
         * NOTE: Using null doesn't provide much value but it is an object
         * so we'll just return null as the exports. We will however, treat
         * undefined specially.
         */
        var clientImpl = require('../');
        clientImpl.ready();

        clientImpl.def('/app$1.0.0/launch/util', null);

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/launch/index', function(require, exports, module, __filename, __dirname) {
            var util = require('./util');
            expect(util).to.equal(null);
        });

        clientImpl.run('/app$1.0.0/launch/util');

        done();
    });

    it('should allow factory to be undefined object', function(done) {

        var clientImpl = require('../');
        clientImpl.ready();

        // An undefined value as factory will remove the definition and make it
        // appear as though the module does not exist
        clientImpl.def('/app$1.0.0/launch/util', undefined);

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/launch/index', function(require, exports, module, __filename, __dirname) {
            expect(function() {
                require('./util');
            }).to.throw(Error);
        });

        clientImpl.run('/app$1.0.0/launch/index');

        done();
    });

    it('should find targets with or without ".js" extension', function(done) {

        var clientImpl = require('../');
        clientImpl.ready();

        var instanceCount = 0;

        clientImpl.def('/app$1.0.0/launch/util', function(require, exports, module, __filename, __dirname) {
            instanceCount++;
            module.exports.greeting = 'Hello!';
        });

        clientImpl.def('/app$1.0.0/launch/index', function(require, exports, module, __filename, __dirname) {
            var util0 = require('./util.js');
            var util1 = require('./util');

            expect(instanceCount).to.equal(1);
            expect(util0).to.equal(util1);
            expect(util0.greeting).to.equal('Hello!');
        });

        // define a module for a given real path
        clientImpl.run('/app$1.0.0/launch/index');

        done();
    });

    it('should resolve targets with or without ".js" extension', function(done) {

        var clientImpl = require('../');
        clientImpl.ready();

        var instanceCount = 0;

        clientImpl.def('/app$1.0.0/launch/util', function(require, exports, module, __filename, __dirname) {
            instanceCount++;
            module.exports.greeting = 'Hello!';
        });

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/launch/index', function(require, exports, module, __filename, __dirname) {

            expect(require.resolve('./util.js')).to.equal('/app$1.0.0/launch/util');
            expect(require.resolve('./util')).to.equal('/app$1.0.0/launch/util');

            expect(instanceCount).to.equal(0);
        });

        clientImpl.run('/app$1.0.0/launch/index');

        done();
    });

    it('should find targets when definition includes extension', function(done) {

        var clientImpl = require('../');
        clientImpl.ready();

        var instanceCount = 0;

        clientImpl.def('/app$1.0.0/launch/do.something', function(require, exports, module, __filename, __dirname) {
            instanceCount++;
            module.exports.greeting = 'Hello!';
        });

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/launch/index', function(require, exports, module, __filename, __dirname) {
            var util0 = require('./do.something.js');
            var util1 = require('./do.something');

            expect(instanceCount).to.equal(1);
            expect(util0).to.equal(util1);
            expect(util0.greeting).to.equal('Hello!');
        });

        clientImpl.run('/app$1.0.0/launch/index');

        done();
    });

    it('should allow main file to be specified for any directory', function(done) {

        var clientImpl = require('../');
        clientImpl.ready();

        var instanceCount = 0;

        clientImpl.def('/app$1.0.0/lib/index', function(require, exports, module, __filename, __dirname) {
            instanceCount++;

            expect(__dirname).to.equal('/app$1.0.0/lib');
            expect(__filename).to.equal('/app$1.0.0/lib/index');

            module.exports.greeting = 'Hello!';
        });

        clientImpl.main('/app$1.0.0', 'lib/index');

        var resolved;

        resolved = clientImpl.resolve('../../lib/index', '/app$1.0.0/lib/launch');
        expect(resolved[0]).to.equal('/app$1.0.0/lib/index');

        resolved = clientImpl.resolve('../../', '/app$1.0.0/lib/launch');
        expect(resolved[0]).to.equal('/app$1.0.0/lib/index');

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/lib/launch', function(require, exports, module, __filename, __dirname) {

            expect(__dirname).to.equal('/app$1.0.0/lib');
            expect(__filename).to.equal('/app$1.0.0/lib/launch');

            // all of the follow require statements are equivalent to require('/app/lib/index')
            var app0 = require('../');
            var app1 = require('/app$1.0.0');
            var app2 = require('/app$1.0.0/lib/index');
            var app3 = require('/app$1.0.0/lib/index.js');
            var app4 = require('./index');
            var app5 = require('./index.js');

            expect(instanceCount).to.equal(1);

            expect(app0.greeting).to.equal('Hello!');

            assert(app1 === app0 &&
                   app2 === app0 &&
                   app3 === app0 &&
                   app4 === app0 &&
                   app5 === app0, 'All instances are not equal to each other');
        });

        clientImpl.run('/app$1.0.0/lib/launch');

        done();
    });

    it('should allow main file to be specified for a module', function(done) {

        var clientImpl = require('../');
        clientImpl.ready();

        var instanceCount = 0;

        clientImpl.def('/streams$1.0.0/lib/index', function(require, exports, module, __filename, __dirname) {
            instanceCount++;

            expect(__dirname).to.equal('/streams$1.0.0/app/lib');
            expect(__filename).to.equal('/streams$1.0.0/app/lib/index');

            module.exports.greeting = 'Hello!';
        });

        clientImpl.main('/streams$1.0.0', 'lib/index');

        clientImpl.installed('app$1.0.0', 'streams', '1.0.0');
        clientImpl.installed('app$2.0.0', 'streams', '1.0.0');

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/launch', function(require, exports, module, __filename, __dirname) {

            expect(__dirname).to.equal('/app$1.0.0');
            expect(__filename).to.equal('/app$1.0.0/launch');

            expect(require.resolve('streams')).to.equal('/streams$1.0.0/lib/index');
        });

        clientImpl.run('/app$1.0.0/launch');

        // define a module for a given real path
        clientImpl.def('/app$2.0.0/launch', function(require, exports, module, __filename, __dirname) {

            expect(__dirname).to.equal('/app$2.0.0');
            expect(__filename).to.equal('/app$2.0.0/launch');

            expect(require.resolve('streams')).to.equal('/streams$1.0.0/lib/index');
            expect(require.resolve('streams/lib/index')).to.equal('/streams$1.0.0/lib/index');
        });

        clientImpl.run('/app$2.0.0/launch');

        done();
    });

    it('should handle remapping individual files', function(done) {

        var clientImpl = require('../');
        clientImpl.ready();

        clientImpl.def('/universal$1.0.0/lib/index', function(require, exports, module, __filename, __dirname) {
            module.exports = {
                name: 'default'
            };
        });

        clientImpl.def('/universal$1.0.0/lib/browser/index', function(require, exports, module, __filename, __dirname) {
            module.exports = {
                name: 'browser'
            };
        });

        clientImpl.main('/universal$1.0.0', 'lib/index');

        clientImpl.installed('app$1.0.0', 'universal', '1.0.0');

        // require "universal" before it is remapped
        var runtime0 = clientImpl.require('universal', '/app$1.0.0/lib');
        expect(runtime0.name).to.equal('default');
        expect(clientImpl.require('universal/lib/index', '/app$1.0.0/lib')).to.equal(runtime0);

        clientImpl.remap(
            // choose a specific "file" to remap
            '/universal$1.0.0/lib/index',
            // following path is relative to /universal$1.0.0/lib
            '/universal$1.0.0/lib/browser/index');

        // require "universal" after it is remapped
        var runtime1 = clientImpl.require('universal', '/app$1.0.0/lib');
        expect(runtime1.name).to.equal('browser');
        expect(clientImpl.require('universal/lib/index', '/app$1.0.0/lib')).to.equal(runtime1);

        done();
    });

    it('should handle remapping entire modules to shim modules', function(done) {
        var clientImpl = require('../');
        clientImpl.ready();

        clientImpl.def('/streams-browser$2.0.0/lib/index', function(require, exports, module, __filename, __dirname) {

            expect(__dirname).to.equal('/streams-browser$2.0.0/lib');
            expect(__filename).to.equal('/streams-browser$2.0.0/lib/index');

            module.exports = {
                name: 'browser'
            };
        });

        clientImpl.main('/streams$1.0.0', 'lib/index');

        clientImpl.installed('app$1.0.0', 'streams', '1.0.0');
        clientImpl.installed('app$1.0.0', 'streams-browser', '2.0.0');

        clientImpl.remap('/streams$1.0.0/lib/index', '/streams-browser$2.0.0/lib/index');

        //clientImpl.remap('streams', 'streams-browser', '/abc');

        // requiring "streams" effectively a require on "streams-browser";
        var streams1 = clientImpl.require('streams', '/app$1.0.0/lib/index');
        var streams2 = clientImpl.require('/streams$1.0.0/lib/index', '/app$1.0.0/lib/index');

        expect(streams1).to.equal(streams2);

        expect(streams1.name).to.equal('browser');

        done();
    });

    it('should join relative paths', function(done) {
        // NOTE: Second argument to join should start with "." or "..".
        //       I don't care about joining an absolute path, empty string
        //       or even a "module name" because these are handled specially
        //       in the resolve method.
        var clientImpl = require('../');
        clientImpl.ready();

        expect(clientImpl.join('/foo/baz', './abc.js')).to.equal('/foo/baz/abc.js');
        expect(clientImpl.join('/foo/baz', '../abc.js')).to.equal('/foo/abc.js');
        expect(clientImpl.join('/foo', '..')).to.equal('/');
        expect(clientImpl.join('/foo', '../..')).to.equal('');
        expect(clientImpl.join('foo', '..')).to.equal('');
        expect(clientImpl.join('foo/bar', '../test.js')).to.equal('foo/test.js');
        expect(clientImpl.join('abc/def', '.')).to.equal('abc/def');
        expect(clientImpl.join('/', '.')).to.equal('/');
        expect(clientImpl.join('/', '.')).to.equal('/');
        expect(clientImpl.join('/app/lib/launch', '../../')).to.equal('/app');
        expect(clientImpl.join('/app/lib/launch', '../..')).to.equal('/app');
        expect(clientImpl.join('/app/lib/launch', './../..')).to.equal('/app');
        expect(clientImpl.join('/app/lib/launch', './../.././././')).to.equal('/app');
        done();
    });

    it('should run module from root', function(done) {
        var clientImpl = require('../');
        clientImpl.ready();

        /*
        TEST SETUP:

        Call require('raptor-util') from within the following file:
        /node_modules/marko-widgets/lib/index.js

        'raptor-util' is installed as a dependency for the top-level 'raptor-modules' module
        */


        var widgetsModule = null;
        // var raptorUtilModule = null;
        clientImpl.installed('marko-widgets$0.1.0', 'raptor-util', '0.1.0');
        clientImpl.main('/raptor-util$0.1.0', 'lib/index');
        clientImpl.def('/raptor-util$0.1.0/lib/index', function(require, exports, module, __filename, __dirname) {
            exports.filename = __filename;
        });

        clientImpl.installed('app$1.0.0', 'marko-widgets', '0.1.0');
        clientImpl.main('/marko-widgets$0.1.0', 'lib/index');
        clientImpl.main('/marko-widgets$0.1.0/lib', 'index');

        clientImpl.def('/marko-widgets$0.1.0/lib/index', function(require, exports, module, __filename, __dirname) {
            exports.filename = __filename;
            exports.raptorUtil = require('raptor-util');
        });

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/index', function(require, exports, module, __filename, __dirname) {
            widgetsModule = require('marko-widgets');
        });

        clientImpl.run('/app$1.0.0/index');

        // run will define the instance and automatically load it
        expect(widgetsModule.filename).to.equal('/marko-widgets$0.1.0/lib/index');
        expect(widgetsModule.raptorUtil.filename).to.equal('/raptor-util$0.1.0/lib/index');

        done();
    });

    it('should allow main with a relative path', function(done) {
        var clientImpl = require('../');
        clientImpl.ready();

        // /$/foo depends on bar$0.1.0
        clientImpl.installed('foo$0.1.0', 'bar', '0.1.0');

        // Requiring "/$/foo/$/bar/Baz" should actually resolve to "/$/foo/$/bar/lib/Baz"
        clientImpl.main('/bar$0.1.0/Baz', '../lib/Baz');

        // Define the bar/lib/Baz module
        clientImpl.def('/bar$0.1.0/lib/Baz', function(require, exports, module, __filename, __dirname) {
            exports.isBaz = true;
        });

        // Add dependency /$/foo --> /foo$0.1.0
        clientImpl.installed('bar$0.1.0', 'foo', '0.1.0');

        // Requiring "/$/foo" should actually resolve to  "/$/foo/lib/index"
        clientImpl.main('/foo$0.1.0', 'lib/index');

        // Define foo/lib/index
        clientImpl.def('/foo$0.1.0/lib/index', function(require, exports, module, __filename, __dirname) {
            expect(module.id).to.equal('/foo$0.1.0/lib/index');

            exports.Baz = require('bar/Baz');

            // make sure that "bar/Baz" resolves to "bar/lib/Baz"
            expect(require('bar/lib/Baz')).to.equal(require('bar/Baz'));
        });

        var Baz = null;
        clientImpl.def('/bar$0.1.0/index', function(require, exports, module, __filename, __dirname) {
            var foo = require('foo');
            Baz = foo.Baz;

        });

        clientImpl.run('/bar$0.1.0/index');

        expect(Baz.isBaz).to.equal(true);

        done();
    });

    it('should handle browser overrides', function() {
        var clientImpl = require('../');
        clientImpl.ready();


        clientImpl.main('/events$0.0.1', 'lib/index');

        clientImpl.installed('async-writer$0.1.0', 'events', '0.0.1');
        clientImpl.remap('/events$0.0.1/lib/index', '/events-browserify$0.0.1/events');
        clientImpl.main('/events-browserify$0.0.1', 'events');

        clientImpl.def('/events-browserify$0.0.1/events', function(require, exports, module, __filename, __dirname) {
            exports.EVENTS_BROWSERIFY = true;
        });


        clientImpl.installed('app$1.0.0', 'async-writer', '0.1.0');
        clientImpl.main('/async-writer$0.1.0', 'lib/async-writer');


        clientImpl.def('/async-writer$0.1.0/lib/async-writer', function(require, exports, module, __filename, __dirname) {
            exports.ASYNC_WRITER = true;
            exports.events = require('events');
        });

        var asyncWriter = null;
        clientImpl.def('/app$1.0.0/index', function(require, exports, module, __filename, __dirname) {
            asyncWriter = require('async-writer');
        });

        clientImpl.run('/app$1.0.0/index');

        expect(asyncWriter.ASYNC_WRITER).to.equal(true);
        expect(asyncWriter.events.EVENTS_BROWSERIFY).to.equal(true);
    });

    it('should handle browser override for main', function() {
        var clientImpl = require('../');
        clientImpl.ready();

        var processModule = null;

        clientImpl.def('/process$0.6.0/browser', function(require, exports, module, __filename, __dirname) {
            exports.PROCESS = true;
        });


        clientImpl.installed('app$1.0.0', 'process', '0.6.0');
        clientImpl.main('/process$0.6.0', 'index');
        clientImpl.remap('/process$0.6.0/index', '/process$0.6.0/browser');

        clientImpl.def('/app$1.0.0/index', function(require, exports, module, __filename, __dirname) {
            processModule = require('process');
        });

        clientImpl.run('/app$1.0.0/index');

        expect(processModule.PROCESS).to.equal(true);
    });

    it('should handle nested dependencies', function() {
        var clientImpl = require('../');
        clientImpl.ready();

        var markoModule = null;

        clientImpl.def('/marko$0.1.0/runtime/lib/marko', function(require, exports, module, __filename, __dirname) {
            exports.MARKO = true;
            exports.asyncWriter = require('async-writer');
        });

        // install dependency /$/marko (version 0.1.0)
        clientImpl.installed('app$1.0.0', 'marko', '0.1.0');

        // If something like "/$/marko" is required then
        // use "/$/marko/runtime/lib/marko"
        clientImpl.main('/marko$0.1.0', 'runtime/lib/marko');

        clientImpl.def('/async-writer$0.1.0/lib/async-writer', function(require, exports, module, __filename, __dirname) {
            exports.ASYNC_WRITER = true;
        });

        clientImpl.main('/async-writer$0.1.0', 'lib/async-writer');

        // install dependency /$/marko/$/async-writer (version 0.1.0)
        clientImpl.installed('marko$0.1.0', 'async-writer', '0.1.0');

        clientImpl.def('/app$1.0.0/index', function(require, exports, module, __filename, __dirname) {
            markoModule = require('marko');
        });

        clientImpl.run('/app$1.0.0/index');

        expect(markoModule.MARKO).to.equal(true);
        expect(markoModule.asyncWriter.ASYNC_WRITER).to.equal(true);

    });

    it('should allow a module to be mapped to a global', function(done) {
        var clientImpl = require('../');

        // define a module for a given real path
        clientImpl.def('/jquery$1.0.0/lib/index', function(require, exports, module, __filename, __dirname) {
            exports.jquery = true;
        }, {'globals': ['$']});

        expect(global.$.jquery).to.equal(true);

        done();
    });

    it('should allow search paths', function() {
        var clientImpl = require('../');

        clientImpl.ready();

        clientImpl.searchPath('/app$1.0.0/src/');

        // define a module for a given real path
        clientImpl.def('/app$1.0.0/src/my-module', function(require, exports, module, __filename, __dirname) {
            module.exports.test = true;
        });

        var myModule;

        clientImpl.def('/app$1.0.0/main', function(require, exports, module, __filename, __dirname) {
            myModule = require('my-module');
        });

        clientImpl.run('/app$1.0.0/main');

        expect(myModule).to.not.equal(undefined);
        expect(myModule.test).to.equal(true);
    });

    it('should run installed modules', function(done) {
        var clientImpl = require('../');
        var initModule = null;

        clientImpl.def("/require-run$1.0.0/foo", function(require, exports, module, __filename, __dirname) {
            module.exports = {
                __filename: __filename,
                __dirname: __dirname
            };
        });
        clientImpl.installed("/app$1.0.0", "require-run", "1.0.0");
        clientImpl.def("/require-run$1.0.0/init", function(require, exports, module, __filename, __dirname) {
            var foo = require('./foo');
            initModule = {
                foo: foo,
                __filename: __filename,
                __dirname: __dirname
            };
        });
        clientImpl.run("/require-run$1.0.0/init", {"wait":false});


        // run will define the instance and automatically load it

        expect(initModule.__dirname).to.equal('/require-run$1.0.0');
        expect(initModule.__filename).to.equal('/require-run$1.0.0/init');
        expect(initModule.foo.__dirname).to.equal('/require-run$1.0.0');
        expect(initModule.foo.__filename).to.equal('/require-run$1.0.0/foo');

        done();
    });

    it('should run installed modules from app module', function(done) {
        var clientImpl = require('../');

        var initModule = null;

        clientImpl.def("/require-run$1.0.0/foo", function(require, exports, module, __filename, __dirname) {
            module.exports = {
                __filename: __filename,
                __dirname: __dirname
            };
        });
        clientImpl.installed("/app$1.0.0", "require-run", "1.0.0");
        clientImpl.def("/require-run$1.0.0/init", function(require, exports, module, __filename, __dirname) {
            var foo = require('./foo');
            initModule = {
                foo: foo,
                __filename: __filename,
                __dirname: __dirname
            };
        });
        clientImpl.run("/require-run$1.0.0/init", {"wait":false});


        // run will define the instance and automatically load it

        expect(initModule.__dirname).to.equal('/require-run$1.0.0');
        expect(initModule.__filename).to.equal('/require-run$1.0.0/init');
        expect(initModule.foo.__dirname).to.equal('/require-run$1.0.0');
        expect(initModule.foo.__filename).to.equal('/require-run$1.0.0/foo');

        done();
    });

    it('should only load one instance of a module with globals', function() {
        var clientImpl = require('../');
        clientImpl.ready();

        var jQueryLoadCounter = 0;
        var mainJquery;

        clientImpl.def("/jquery$1.11.3/dist/jquery", function(require, exports, module, __filename, __dirname) {
            exports.isJquery = true;

            jQueryLoadCounter++;

        },{"globals":["$","jQuery"]});

        var mainDidRun = false;

        clientImpl.def("/app$1.0.0/jquery-main", function(require, exports, module, __filename, __dirname) {
            mainDidRun = true;
            mainJquery = require('jquery');
        });

        clientImpl.main("/jquery$1.11.3", "dist/jquery");
        clientImpl.installed("app$1.0.0", "jquery", "1.11.3");
        clientImpl.run('/app$1.0.0/jquery-main');

        expect(mainDidRun).to.equal(true);

        expect(mainJquery.isJquery).to.equal(true);

        expect(jQueryLoadCounter).to.equal(1);
        expect(mainJquery).to.equal(global.$);
    });

    it('should handle root paths correctly', function() {
        var clientImpl = require('../');
        clientImpl.ready();

        var libIndex = null;

        clientImpl.main("/app$1.0.0", "lib/index");

        clientImpl.def('/app$1.0.0/lib/index', function(require, exports, module, __filename, __dirname) {
            exports.LIB_INDEX = true;
        });

        clientImpl.def('/app$1.0.0/main/index', function(require, exports, module, __filename, __dirname) {
            libIndex = require('../');
        });

        clientImpl.run('/app$1.0.0/main/index');

        expect(libIndex.LIB_INDEX).to.equal(true);
    });

    it('should handle scoped modules', function(done) {
        var clientImpl = require('../');
        clientImpl.ready();

        var instanceCount = 0;

        // define a module for a given real path
        clientImpl.def('/@foo/bar$3.0.0/lib/index', function(require, exports, module, __filename, __dirname) {
            instanceCount++;
            module.exports = {
                __filename: __filename,
                __dirname: __dirname
            };
        });

        // Module "foo" requires "baz" 3.0.0
        // This will create the following link:
        // /$/foo/$/baz --> baz$3.0.0
        clientImpl.installed('app$1.0.0', '@foo/bar', '3.0.0');

        var fooBar = clientImpl.require('@foo/bar/lib/index', '/app$1.0.0/index');

        expect(instanceCount).to.equal(1);

        expect(fooBar.__filename).to.equal('/@foo/bar$3.0.0/lib/index');
        expect(fooBar.__dirname).to.equal('/@foo/bar$3.0.0/lib');

        done();
    });
});
