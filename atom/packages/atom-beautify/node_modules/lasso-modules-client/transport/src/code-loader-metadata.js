module.exports = function(loaderMetadata, lassoContext, options) {
    var modulesRuntimeGlobal = (options && options.modulesRuntimeGlobal) || '$_mod';
    return modulesRuntimeGlobal + '.loaderMetadata(' +
        JSON.stringify(loaderMetadata.toObject(lassoContext)) +
        ');';
};