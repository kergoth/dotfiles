

function addSearchPathsCode(paths, options) {
    var modulesRuntimeGlobal = (options && options.modulesRuntimeGlobal) || '$_mod';

    var code = '';

    for (var i = 0; i < paths.length; i++) {
        var path = paths[i];

        if (path.charAt(path.length - 1) !== '/') {
            path = path + '/';
        }

        code += modulesRuntimeGlobal + '.searchPath(' + JSON.stringify(path) + ');';
    }

    return code;
}

module.exports = addSearchPathsCode;