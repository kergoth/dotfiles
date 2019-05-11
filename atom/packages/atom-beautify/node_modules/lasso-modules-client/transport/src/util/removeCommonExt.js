var nodePath = require('path');

function removeCommonExt(path) {
    var basename = nodePath.basename(path);
    var ext = nodePath.extname(basename);

    if (ext === '.js' || ext === '.json' || ext === '.es6') {
        return path.slice(0, 0-ext.length);
    } else {
        return path;
    }
}

module.exports = removeCommonExt;