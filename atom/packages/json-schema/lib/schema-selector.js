var rx_1 = require("rx");
var schema_selector_view_1 = require('./schema-selector-view');
var React = require('react');
var omni_1 = require("./omni");
var schema_provider_1 = require("./schema-provider");
var SchemaSelector = (function () {
    function SchemaSelector() {
        this._active = false;
    }
    SchemaSelector.prototype.activate = function () {
        this.disposable = new rx_1.CompositeDisposable();
    };
    SchemaSelector.prototype.setup = function (statusBar) {
        this.statusBar = statusBar;
        if (this._active) {
            this._attach();
        }
    };
    SchemaSelector.prototype.attach = function () {
        if (this.statusBar) {
            this._attach();
        }
        this._active = true;
    };
    SchemaSelector.prototype._attach = function () {
        var _this = this;
        this.view = document.createElement("span");
        this.view.classList.add('inline-block');
        this.view.classList.add('schema-selector');
        this.view.style.display = 'none';
        var alignLeft = !atom.config.get('grammar-selector.showOnRightSideOfStatusBar');
        if (!alignLeft) {
            var tile = this.statusBar.addRightTile({
                item: this.view,
                priority: 9
            });
        }
        else {
            var tile = this.statusBar.addLeftTile({
                item: this.view,
                priority: 11
            });
        }
        this._component = React.render(React.createElement(schema_selector_view_1.SelectorComponent, { alignLeft: alignLeft }), this.view);
        this.disposable.add(rx_1.Disposable.create(function () {
            React.unmountComponentAtNode(_this.view);
            tile.destroy();
            _this.view.remove();
        }));
        this.disposable.add(omni_1.omni.activeEditor
            .where(function (z) { return !z; })
            .subscribe(function () { return _this.view.style.display = 'none'; }));
        this.disposable.add(omni_1.omni.activeEditor
            .where(function (z) { return !!z; })
            .subscribe(function () { return _this.view.style.display = ''; }));
        this.disposable.add(omni_1.omni.activeEditor
            .flatMapLatest(function (editor) { return schema_provider_1.schemaProvider.getSchemaForEditor(editor); })
            .defaultIfEmpty({})
            .subscribe(function (activeSchema) {
            omni_1.omni.activeSchema = activeSchema;
            _this._component.setState({ activeSchema: activeSchema });
        }));
    };
    SchemaSelector.prototype.dispose = function () {
        this.disposable.dispose();
    };
    SchemaSelector.prototype.setActiveSchema = function (activeSchema) {
        omni_1.omni.activeSchema = activeSchema;
        this._component.setState({ activeSchema: activeSchema });
    };
    return SchemaSelector;
})();
exports.schemaSelector = new SchemaSelector;
