function installedCode(parentPath, childName, childVersion, options) {
    var modulesRuntimeGlobal = (options && options.modulesRuntimeGlobal) || '$_mod';

    if (parentPath === '/') {
        parentPath = '';
    }

    if (parentPath.charAt(0) === '/') {
        parentPath = parentPath.substring(1);
    }

    var code = modulesRuntimeGlobal + '.installed(' + JSON.stringify(parentPath) + ', ' +
        JSON.stringify(childName) + ', ' +
        JSON.stringify(childVersion);

    code += ');';
    return code;
}

module.exports = installedCode;