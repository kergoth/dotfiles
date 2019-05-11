'use strict';

var nodePath = require('path');
var chai = require('chai');
chai.config.includeStack = true;
var expect = require('chai').expect;

var getClientPath = require('../').getClientPath;

describe('getClientPath' , function() {

    it('should resolve path info correctly for top-level installed modules', function() {
        var path = nodePath.join(__dirname, "fixtures/test-project/node_modules/foo/lib/index.js");
        var clientPath = getClientPath(path);
        expect(clientPath).to.equal('/foo$1.0.0/lib/index');
    });

    it('should resolve path info correctly for directories', function() {
        var path;
        var clientPath;

        path = nodePath.join(__dirname, "fixtures/test-project/node_modules/foo");
        clientPath = getClientPath(path);
        expect(clientPath).to.equal('/foo$1.0.0');

        path = nodePath.join(__dirname, "fixtures/test-project/node_modules/bar");
        clientPath = getClientPath(path);
        expect(clientPath).to.equal('/bar$2.0.0');

        path = nodePath.join(__dirname, "fixtures/test-project/src/hello-world");
        clientPath = getClientPath(path);
        expect(clientPath).to.equal('/test-project$0.0.0/src/hello-world');
    });

    it('should resolve path info correctly for second-level installed modules', function() {
        var path = nodePath.join(__dirname, "fixtures/test-project/node_modules/foo/node_modules/baz/lib/index.js");
        var clientPath = getClientPath(path);
        expect(clientPath).to.equal('/baz$3.0.0/lib/index');
    });

    it('should resolve path info correctly for application modules', function() {
        var path = nodePath.join(__dirname, "fixtures/test-project/src/hello-world/index.js");
        var clientPath = getClientPath(path);
        expect(clientPath).to.equal('/test-project$0.0.0/src/hello-world/index');
    });

    it('should handle scoped packages', function() {
        var clientPath = getClientPath(nodePath.join(__dirname, 'fixtures/test-project/node_modules/@foo/bar/lib/index.js'));

        expect(clientPath).to.equal("/@foo/bar$3.0.0/lib/index");
    });

    it('should handle modules in a custom search path', function() {
        var clientPath = getClientPath(nodePath.join(__dirname, 'fixtures/test-project/app_modules/bar/index.js'));
        expect(clientPath).to.equal('/bar$1.2.0/index');
    });


});

