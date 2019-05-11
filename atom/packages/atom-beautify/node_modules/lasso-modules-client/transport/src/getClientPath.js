require('raptor-polyfill/string/startsWith');
require('raptor-polyfill/string/endsWith');

var nodePath = require('path');
var ok = require('assert').ok;
var lassoPackageRoot = require('lasso-package-root');
var removeCommonExt = require('./util/removeCommonExt');
var sep = nodePath.sep;

function getClientPath(path, options) {
    ok(typeof path === 'string', 'path should be a string');
    options = options || {};

    var normalizedPath = nodePath.resolve(process.cwd(), path);
    var removeExt = options.removeExt !== false;

    var name;
    var version;

    var moduleRootPkg = lassoPackageRoot.getRootPackage(normalizedPath);
    if (!moduleRootPkg) {
        return '$/' + nodePath.relative(process.cwd(), path);
    }
    name = moduleRootPkg.name;
    version = moduleRootPkg.version || '0';

    var packageId = '/' + name + '$' + version;
    var subPath = normalizedPath.substring(moduleRootPkg.__dirname.length);
    var clientPath = packageId + subPath;

    if (sep !== '/') {
        clientPath = clientPath.replace(/[\\]/g, '/');
    }

    if (clientPath.endsWith('/')) {
        clientPath = clientPath.slice(0, -1);
    }


    if (removeExt) {
        clientPath = removeCommonExt(clientPath);
    }

    return clientPath;
}

module.exports = getClientPath;
