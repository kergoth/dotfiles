var _ = require("lodash");
var fetch = require('node-fetch');
var rx_1 = require("rx");
var Schema = (function () {
    function Schema(header) {
        this.name = header.name;
        this.description = header.description;
        this.fileMatch = header.fileMatch || [];
        this.url = header.url;
    }
    Object.defineProperty(Schema.prototype, "content", {
        get: function () {
            if (!this._content)
                this._content = rx_1.Observable.fromPromise(fetch(this.url).then(function (res) { return res.json(); })).shareReplay(1);
            return this._content;
        },
        enumerable: true,
        configurable: true
    });
    return Schema;
})();
var SchemaProvider = (function () {
    function SchemaProvider() {
        this._schemas = new Map();
        this._schemas.set('JSON', {
            name: 'none',
            description: 'none',
            fileMatch: [],
            url: 'none',
            content: rx_1.Observable.just({})
        });
    }
    Object.defineProperty(SchemaProvider.prototype, "schemas", {
        get: function () {
            if (!this._schemasObservable) {
                this._schemasObservable = this.getSchemas().shareReplay(1);
            }
            return this._schemasObservable;
        },
        enumerable: true,
        configurable: true
    });
    SchemaProvider.prototype.getSchemas = function () {
        var _this = this;
        //http://schemastore.org/api/json/catalog.json
        return rx_1.Observable.fromPromise(fetch('http://schemastore.org/api/json/catalog.json')
            .then(function (res) { return res.json(); }))
            .map(function (_a) {
            var schemas = _a.schemas;
            _.each(schemas, function (schema) {
                _this.addSchema(schema);
            });
            var iterator = _this._schemas.values();
            var result = iterator.next();
            var items = [];
            while (!result.done) {
                items.push(result.value);
                result = iterator.next();
            }
            return items;
        });
    };
    SchemaProvider.prototype.addSchema = function (header) {
        this._schemas.set(header.name, new Schema(header));
    };
    SchemaProvider.prototype.getSchemaForEditor = function (editor) {
        if (!editor)
            return rx_1.Observable.just({ content: {} });
        if (_.has(editor, '__json__schema__')) {
            if (editor['__json__schema__']) {
                return rx_1.Observable.just(editor['__json__schema__']);
            }
            else {
                return rx_1.Observable.empty();
            }
        }
        var fileName = editor.getBuffer().getBaseName();
        return this.schemas
            .flatMap(function (schemas) { return rx_1.Observable.from(schemas); })
            .firstOrDefault(function (schema) { return _.any(schema.fileMatch, function (match) { return fileName === match; }); }, null)
            .tapOnNext(function (schema) { return editor['__json__schema__'] = schema; })
            .where(function (z) { return !!z; });
    };
    return SchemaProvider;
})();
exports.schemaProvider = new SchemaProvider();
