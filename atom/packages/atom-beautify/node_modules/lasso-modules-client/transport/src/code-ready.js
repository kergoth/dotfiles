function readyCode(options) {
    var modulesRuntimeGlobal = (options && options.modulesRuntimeGlobal) || '$_mod';
    return modulesRuntimeGlobal + '.ready();';
}

module.exports = readyCode;