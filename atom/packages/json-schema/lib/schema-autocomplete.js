var _ = require('lodash');
var Promise = require('bluebird');
//var escape = require("escape-html");
var filter = require('fuzzaldrin').filter;
var get_ranges_1 = require("./helpers/get-ranges");
var schema_provider_1 = require("./schema-provider");
function fixSnippet(snippet, options, type) {
    var t = _.trim(snippet);
    if (_.startsWith(t, '{') || _.startsWith(t, '"') || _.endsWith(t, '}') || _.endsWith(t, '"') || _.endsWith(t, ','))
        return snippet;
    if (!options.hasLeadingQuote)
        snippet = '"' + snippet;
    if (!options.hasTrailingQuote && !_.endsWith(snippet, '.'))
        snippet = snippet + '"';
    if (type === "string") {
        snippet = snippet += ': ""';
    }
    else if (type === "object") {
        snippet = snippet += ': {}';
    }
    else if (type === "array") {
        snippet = snippet += ': []';
    }
    return snippet;
}
function makeSuggestion(item, options) {
    var description = item.description, leftLabel = item.type.substr(0, 1), type = 'variable';
    return {
        _search: item.key,
        text: item.key,
        snippet: fixSnippet(item.key, options, item.type),
        type: type,
        displayText: item.key,
        className: 'autocomplete-json-schema',
        description: description
    };
}
function renderReturnType(returnType) {
    if (returnType === null) {
        return;
    }
    return "Returns: " + returnType;
}
function schemaGet(schema, path) {
    // ignore .data
    var p = (path || '').split('/');
    var rootSchema = schema;
    while (p.length) {
        var s = p.shift();
        if (schema.properties && schema.properties[s]) {
            schema = schema.properties[s];
        }
        else if (schema.additionalProperties) {
            schema = schema.additionalProperties;
        }
        if (schema.$ref) {
            // This is the most common def case, may not always work
            var childPath = _.trim(schema.$ref, '/#').split('/').join('.');
            schema = _.get(rootSchema, childPath);
        }
    }
    return schema;
}
function getSuggestions(options) {
    /*var buffer = options.editor.getBuffer();
    var end = options.bufferPosition.column;
    var data = buffer.getLines()[options.bufferPosition.row].substring(0, end + 1);
    var lastCharacterTyped = data[end - 1];

    if (!/[A-Z_0-9.]+/i.test(lastCharacterTyped)) {
        return;
    }*/
    var line = options.editor.getBuffer().getLines()[options.bufferPosition.row];
    var hasLeadingQuote = false;
    for (var i = options.bufferPosition.column; i >= 0; i--) {
        var char = line[i];
        if (char === ',' || char === '}' || char === ':') {
            break;
        }
        if (char === '"') {
            hasLeadingQuote = true;
            break;
        }
    }
    var hasTrailingQuote = false;
    for (var i = options.bufferPosition.column; i < line.length; i++) {
        var char = line[i];
        if (char === ':' || char === '}' || char === ',' || char === '{') {
            break;
        }
        if (char === '"') {
            hasTrailingQuote = true;
            break;
        }
    }
    var prefix = options.prefix;
    try {
        var cursor = options.editor.getLastCursor();
        var editor = options.editor;
        prefix = editor.getTextInBufferRange(cursor.getCurrentWordBufferRange({ wordRegex: /^[\t ]*$|[^\s\/\\\(\)"':,\;<>~!@#\$%\^&\*\|\+=\[\]\{\}`\?]+|[\/\\\(\)"':,\;<>~!@#\$%\^&\*\|\+=\[\]\{\}`\?]+/ }));
    }
    catch (e) { }
    prefix = _.trim(prefix, ':{}," ');
    var context = get_ranges_1.getPath(options.editor, function (line, column) {
        return options.bufferPosition.row === line && options.bufferPosition.column === column + 1;
    });
    var _a = get_ranges_1.getRanges(options.editor), ranges = _a.ranges, objectPaths = _a.objectPaths;
    var existingKeys = _(ranges).keys()
        .filter(function (z) { return _.startsWith(z + '/', context.path); })
        .filter(function (z) { return z && z.indexOf('/') === -1; })
        .value();
    var p = schema_provider_1.schemaProvider
        .getSchemaForEditor(options.editor)
        .flatMap(function (schema) { return schema.content; })
        .map(function (schema) {
        // ignore .data
        var p = (context.path || '').split('/');
        var rootSchema = schema;
        var parentSchema;
        while (p.length) {
            var lastSchema = schema;
            var s = p.shift();
            if (schema.properties && schema.properties[s]) {
                schema = schema.properties[s];
            }
            else if (schema.additionalProperties) {
                schema = schema.additionalProperties;
            }
            else if (schema !== rootSchema) {
                schema = {};
            }
            if (schema.$ref) {
                // This is the most common def case, may not always work
                var childPath = _.trim(schema.$ref, '/#').split('/').join('.');
                schema = _.get(rootSchema, childPath);
            }
        }
        var inferedType = "";
        if (typeof schema.type === "string" && schema.type === "object") {
            inferedType = "object";
        }
        var objectPath = _.find(objectPaths, function (value, key) { return key === context.path; });
        if (objectPath && _.isArray(schema.type) && _.contains(schema.type, "object") && (options.bufferPosition.row == objectPath.line && options.bufferPosition.column + 1 > objectPath.column || options.bufferPosition.row > objectPath.line)) {
            inferedType = "object";
        }
        if (schema.enum && schema.enum.length) {
            return schema.enum.map(function (property) { return ({ key: property, type: 'enum', description: '' }); });
        }
        if (inferedType === "object" && schema.properties && _.any(schema.properties)) {
            return _.keys(schema.properties)
                .filter(function (z) { return !_.contains(existingKeys, z); })
                .map(function (property) {
                var propertySchema = schema.properties[property];
                return { key: property, type: typeof propertySchema.type === "string" ? propertySchema.type : 'property', description: propertySchema.description };
            });
        }
        var types = [];
        if (typeof schema.type === "string") {
            types = [schema.type];
        }
        else if (_.isArray(types)) {
            types = schema.type || [];
        }
        if (types.length > 1) {
            return _.map(types, function (type) {
                if (type === "string") {
                    return { key: '""', type: "value", description: '' };
                }
                else if (type === "object") {
                    var res = {};
                    _.each(schema.properties, function (value, key) {
                        if (value.type === "string")
                            res[key] = value.default || '';
                    });
                    return { key: JSON.stringify(res, null, options.editor.getTabLength()), type: "value", description: '' };
                }
            });
        }
        return [];
    })
        .defaultIfEmpty([])
        .toPromise();
    var search = prefix;
    if (search === ".")
        search = "";
    //options.prefix = prefix;
    if (search)
        p = p.then(function (s) {
            return filter(s, search, { key: 'key' });
        });
    var baseSuggestions = p.then(function (response) { return response.map(function (s) { return makeSuggestion(s, { replacementPrefix: prefix, hasLeadingQuote: hasLeadingQuote, hasTrailingQuote: hasTrailingQuote }); }); });
    if (providers.length) {
        var workingOptions = _.defaults({ prefix: prefix, replacementPrefix: prefix }, context, options);
        var workingProviders = _.filter(providers, function (z) {
            return _.contains(z.fileMatchs, options.editor.getBuffer().getBaseName()) && z.pathMatch(context.path);
        })
            .map(function (z) { return z.getSuggestions(workingOptions).then(function (suggestions) {
            return _.each(suggestions, function (s) { return s.snippet = fixSnippet(s.snippet, { hasLeadingQuote: hasLeadingQuote, hasTrailingQuote: hasTrailingQuote }, 'other'); });
        }); });
        if (workingProviders.length) {
            return Promise.all(workingProviders.concat([baseSuggestions]))
                .then(function (items) {
                return _.flatten(items);
            });
        }
    }
    return baseSuggestions;
}
var providers = [].concat(require('./providers/npm-provider')).concat(require('./providers/bower-provider'));
exports.CompletionProvider = {
    selector: '.source.json',
    inclusionPriority: 2,
    excludeLowerPriority: false,
    getSuggestions: getSuggestions,
    registerProvider: function (provider) {
        providers.push(provider);
    },
    onDidInsertSuggestion: function (_a) {
        var editor = _a.editor, suggestion = _a.suggestion;
        if (_.endsWith(suggestion.text, '.')) {
            _.defer(function () { return atom.commands.dispatch(atom.views.getView(editor), "autocomplete-plus:activate"); });
        }
    },
    dispose: function () { }
};
