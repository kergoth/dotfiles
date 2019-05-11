var nextComponentIdProvider = require("./util")._w_;
var KeySequence = require("./KeySequence");

function GlobalComponentsContext(out) {
    this._x_ = {};
    this._y_ = {};
    this._z_ = {};
    this.Q_ = undefined;
    this._k_ = nextComponentIdProvider(out);
}

GlobalComponentsContext.prototype = {
    _A_: function () {
        return new KeySequence();
    }
};

module.exports = GlobalComponentsContext;