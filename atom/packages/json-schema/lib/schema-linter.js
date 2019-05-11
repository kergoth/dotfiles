var validator;
(function () {
    var loophole = require("loophole");
    function allowUnsafe(fn) {
        return loophole.allowUnsafeEval(function () { return loophole.allowUnsafeNewFunction(function () { return fn(); }); });
    }
    allowUnsafe(function () { return validator = require('is-my-json-valid'); });
})();
var Range = require('atom').Range;
var _ = require('lodash');
var schema_provider_1 = require("./schema-provider");
var get_ranges_1 = require("./helpers/get-ranges");
function getWordAt(str, pos) {
    var wordLocation = {
        start: pos,
        end: pos
    };
    if (str === undefined) {
        return wordLocation;
    }
    while (pos < str.length && /\W/.test(str[pos])) {
        ++pos;
    }
    var left = str.slice(0, pos + 1).search(/\W(?!.*\W)/);
    var right = str.slice(pos).search(/(\W|$)/);
    wordLocation.start = left + 1;
    wordLocation.end = wordLocation.start + right;
    return wordLocation;
}
function mapValues(editor, ranges, error) {
    var range = ranges[error.field.replace('data.', '')];
    if (!range) {
        // TODO:  Should try and figure out some of these failures
        return null;
    }
    var line = range.section.start[0];
    var column = range.section.start[1];
    var text = editor.lineTextForBufferRow(line);
    var level = 'error';
    return {
        type: level,
        text: error.field + " - " + error.message,
        filePath: editor.getPath(),
        line: line + 1,
        col: column + 1,
        range: new Range(range.value.start, range.value.end)
    };
}
var makeValidator = _.memoize(function (schema) {
    if (_.isEmpty(schema))
        return null;
    return validator(schema);
});
exports.provider = [
    {
        grammarScopes: ['source.json'],
        scope: 'file',
        lintOnFly: true,
        lint: function (editor) {
            return schema_provider_1.schemaProvider
                .getSchemaForEditor(editor)
                .flatMap(function (schema) { return schema.content; })
                .map(function (schema) { return makeValidator(schema); })
                .map(function (validate) {
                var ranges = get_ranges_1.getRanges(editor).ranges;
                try {
                    var text = editor.getText().replace(/\n/g, '').replace(/\r/g, '').replace(/\t/g, '').trim();
                    var data = JSON.parse(text);
                }
                catch (e) {
                    // TODO: Should return a validation error that json is invalid?
                    return [];
                }
                var result = validate(data, { greedy: true });
                if (validate.errors && validate.errors.length) {
                    return validate.errors.map(function (error) { return mapValues(editor, ranges, error); }).filter(function (z) { return !!z; });
                }
                return [];
            })
                .defaultIfEmpty([])
                .toPromise();
        }
    }
];
