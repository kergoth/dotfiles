var tokenizer = require('./util/tokenizer').create([
        {
            name: 'useStrict',
            pattern: /'use strict'\s*(?:[;]|\n)/,
        },
        {
            name: 'useStrict',
            pattern: /"use strict"\s*(?:[;]|\n)/,
        },
        {
            name: 'stringDouble',
            pattern: /"(?:[^"]|\\")*"/,
        },
        {
            name: 'stringSingle',
            pattern: /'(?:[^']|\\')*'/
        },
        {
            name: 'singleLineComment',
            pattern: /\/\/.*/
        },
        {
            name: 'multiLineComment',
            pattern: /\/\*(?:[\s\S]*?)\*\//
        },
        {
            name: 'whitespace',
            pattern: /\s+/
        },
        {
            pattern: /./,
            stop: true
        }
    ]);

function defineCode(path, code, options) {
    var result = '';
    var isObject = false;
    var additionalVars = null;
    var globals = null;
    var wait = true;

    if (options) {
        isObject = options.object === true;
        additionalVars = options.additionalVars;
        globals = options.globals;
        wait = options.wait !== false;
    }

    if (code == null) {
        throw new Error('"code" argument is required');
    }

    var modulesRuntimeGlobal = (options && options.modulesRuntimeGlobal) || '$_mod';


    result += modulesRuntimeGlobal + '.def(';
    result += JSON.stringify(path);

    if (isObject) {
        result += ', ';
    } else {
        result += ', function(require, exports, module, __filename, __dirname) { ';
        if (additionalVars && additionalVars.length) {
            var additionalVarsString = 'var ' + additionalVars.join(', ') + '; ';

            var useStrictToken = null;

            tokenizer.forEachToken(code, function(token) {
                if (token.name === 'useStrict') {
                    useStrictToken = token;
                }
            });

            if (useStrictToken) {
                code = code.substring(0, useStrictToken.end) + additionalVarsString + code.substring(useStrictToken.end);
            } else {
                code = additionalVarsString + code;
            }
        }
    }


    result += code;

    if (!isObject) {
        result += '\n}'; // End the function wrapper
    }

    if (globals || (wait === false)) {

        var defOptions = {};
        if (globals) {
            if (!Array.isArray(globals)) {
                globals = [globals];
            }

            defOptions.globals = globals;
        }

        if (wait === false) {
            defOptions.wait = false;
        }

        result += ',' + JSON.stringify(defOptions);
    }


    result += ');'; // End the function call
    return result;
}

module.exports = defineCode;