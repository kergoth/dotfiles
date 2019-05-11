var path = require('path');
var removeCommonExt = require('./util/removeCommonExt');

function normalizeMain(dir, main) {
    var relativePath = path.relative(dir, main);
    relativePath = removeCommonExt(relativePath);

    if (relativePath === 'index') {
        return '';
    }

    return relativePath;
}

module.exports = normalizeMain;
