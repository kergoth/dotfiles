function doGetRanges(editor, predicate) {
    var doc = editor.getText();
    var token_regex = /"([-a-zA-Z0-9+\._]+)"[\s]*:$/;
    var open = [];
    var depth = 1;
    var line = 0;
    var lineStart = 0;
    var tokens = [];
    var start = [];
    var valueStart = [];
    var current = null;
    var isArray = false;
    var isString = false;
    if (!predicate) {
        var objectPaths = {};
        var results = {};
    }
    for (var index = doc.indexOf('{') + 1; index < doc.lastIndexOf('}'); index++) {
        var char = doc[index];
        if (char === '\n') {
            line += 1;
            if (doc[index + 1] === '\r') {
                lineStart = index + 2;
            }
            else {
                lineStart = index + 1;
            }
        }
        if ((isString || isArray) && predicate && predicate(line, index - lineStart)) {
            if (char === '}' || char === ',')
                open.pop();
            return {
                path: open.join('/')
            };
        }
        if (isString && char !== '"' && doc[index - 1] !== "\\") {
            continue;
        }
        if (isString && char === '"') {
            isString = false;
        }
        else if (!isString && char === '"') {
            isString = true;
        }
        if (isArray && char !== ']') {
            continue;
        }
        if (char === '[') {
            isArray = true;
        }
        if (char === ']') {
            isArray = false;
        }
        if (char === '{') {
            depth += 1;
            tokens.push(open[open.length - 1]);
            start.push(start[start.length - 1]);
            if (objectPaths) {
                objectPaths[tokens.join('/')] = {
                    line: line,
                    column: index - lineStart
                };
            }
            valueStart.push(valueStart[valueStart.length - 1]);
        }
        if (char === ':' && !(isString || isArray)) {
            var match = doc.substr(0, index + 1).match(token_regex);
            if (match) {
                open.push(match[1]);
                start.push([line, index - match[0].length - lineStart]);
                valueStart.push([line, index - lineStart + 1]);
            }
        }
        if (predicate && predicate(line, index - lineStart)) {
            if (char === '}' || char === ',')
                open.pop();
            return {
                path: open.join('/')
            };
        }
        if (open.length && (char === '}' || (!isArray && char === ','))) {
            var path = tokens.concat([open.pop()]).join('/');
            if (results) {
                results[path] = {
                    path: path,
                    section: {
                        start: start.pop(),
                        end: [line, index + 1 - lineStart]
                    },
                    value: {
                        start: valueStart.pop(),
                        end: [line, index - lineStart]
                    }
                };
                open.pop();
            }
        }
        if (char === '}') {
            depth -= 1;
            var path = tokens.join('/');
            if (results) {
                results[path] = {
                    path: path,
                    section: {
                        start: start.pop(),
                        end: [line, index - lineStart]
                    },
                    value: {
                        start: valueStart.pop(),
                        end: [line, index - 1 - lineStart]
                    }
                };
                tokens.pop();
            }
        }
    }
    return { ranges: results, objectPaths: objectPaths };
}
function getRanges(editor) {
    return doGetRanges(editor, undefined);
}
exports.getRanges = getRanges;
function getPath(editor, predicate) {
    return doGetRanges(editor, predicate);
}
exports.getPath = getPath;
