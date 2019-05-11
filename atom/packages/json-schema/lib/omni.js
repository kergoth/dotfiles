var rx_1 = require("rx");
var Omni = (function () {
    function Omni() {
        this.disposable = new rx_1.CompositeDisposable();
        this._editor = new rx_1.ReplaySubject(1);
        this._editorObservable = this._editor.asObservable();
    }
    Omni.prototype.activate = function () {
        this.setupEditorObservable();
    };
    Omni.prototype.dispose = function () {
        this.disposable.dispose();
    };
    Object.defineProperty(Omni.prototype, "activeEditor", {
        get: function () { return this._editorObservable; },
        enumerable: true,
        configurable: true
    });
    Omni.prototype.setupEditorObservable = function () {
        var _this = this;
        this.disposable.add(atom.workspace.observeActivePaneItem(function (pane) {
            if (pane && pane.getGrammar) {
                var grammar = pane.getGrammar();
                if (grammar) {
                    var grammarName = grammar.name;
                    if (grammarName === 'JSON') {
                        _this._editor.onNext(pane);
                        return;
                    }
                }
            }
            // This will tell us when the editor is no longer an appropriate editor
            _this._editor.onNext(null);
        }));
    };
    Object.defineProperty(Omni.prototype, "activeSchema", {
        get: function () { return this._schema; },
        set: function (value) {
            this._schema = value;
            this._editorObservable.take(1).where(function (z) { return !!z; }).subscribe(function (editor) { return editor['__json__schema__'] = value; });
        },
        enumerable: true,
        configurable: true
    });
    return Omni;
})();
exports.omni = new Omni;
