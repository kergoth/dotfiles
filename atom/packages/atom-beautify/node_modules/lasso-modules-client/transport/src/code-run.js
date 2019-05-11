function runCode(path, runOptions, options) {
    var modulesRuntimeGlobal = (options && options.modulesRuntimeGlobal) || '$_mod';
    return modulesRuntimeGlobal + '.run(' + JSON.stringify(path) +
        (runOptions ? (',' + JSON.stringify(runOptions)) : '') + ');';
}

module.exports = runCode;