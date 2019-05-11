function registerRemapCode(from, to, options) {
    var modulesRuntimeGlobal = (options && options.modulesRuntimeGlobal) || '$_mod';

    var code = modulesRuntimeGlobal + '.remap(' +
        JSON.stringify(from) + ', ' +
        JSON.stringify(to) +
        ');';

    return code;
}

module.exports = registerRemapCode;