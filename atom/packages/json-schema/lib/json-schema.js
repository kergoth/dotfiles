var _ = require('lodash');
var rx_1 = require("rx");
var omni_1 = require("./omni");
var JsonSchema = (function () {
    function JsonSchema() {
        this.disposable = new rx_1.CompositeDisposable();
    }
    JsonSchema.prototype.activate = function (state) {
        omni_1.omni.activate();
        this.disposable.add(omni_1.omni);
        var schemaSelector = require('./schema-selector').schemaSelector;
        this.disposable.add(schemaSelector);
        //var {schemaPrSelector} = require('./schema-selector');
        //this.disposable.add(schemaSelector);
        schemaSelector.activate();
        schemaSelector.attach();
    };
    JsonSchema.prototype.deactivate = function () {
        this.disposable.dispose();
    };
    JsonSchema.prototype.consumeStatusBar = function (statusBar) {
        var schemaSelector = require('./schema-selector').schemaSelector;
        schemaSelector.setup(statusBar);
    };
    JsonSchema.prototype.consumeProvider = function (providers) {
        if (!providers)
            return;
        if (!_.isArray(providers))
            providers = [providers];
        var cd = new rx_1.CompositeDisposable();
        var CompletionProvider = require("./schema-autocomplete").CompletionProvider;
        _.each(providers, CompletionProvider.registerProvider);
        return cd;
    };
    JsonSchema.prototype.provideAutocomplete = function () {
        var CompletionProvider = require("./schema-autocomplete").CompletionProvider;
        //this.disposable.add(CompletionProvider);
        return CompletionProvider;
    };
    JsonSchema.prototype.provideLinter = function (linter) {
        var LinterProvider = require("./schema-linter");
        return LinterProvider.provider;
    };
    return JsonSchema;
})();
var instance = new JsonSchema;
module.exports = instance;
