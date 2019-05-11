function registerMainCode(path, main, options) {
    var modulesRuntimeGlobal = (options && options.modulesRuntimeGlobal) || '$_mod';


    var code = modulesRuntimeGlobal + '.main(' + JSON.stringify(path) + ', ' +
        JSON.stringify(main) + ');';
    return code;
}

module.exports = registerMainCode;