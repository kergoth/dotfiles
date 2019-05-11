"use strict";

var GlobalComponentsContext = require("./GlobalComponentsContext");

function ComponentsContext(out, parentComponentsContext) {
    var globalComponentsContext;
    var componentDef;

    if (parentComponentsContext) {
        globalComponentsContext = parentComponentsContext.P_;
        componentDef = parentComponentsContext._p_;

        var nestedContextsForParent;
        if (!(nestedContextsForParent = parentComponentsContext._q_)) {
            nestedContextsForParent = parentComponentsContext._q_ = [];
        }

        nestedContextsForParent.push(this);
    } else {
        globalComponentsContext = out.global._r_;
        if (globalComponentsContext === undefined) {
            out.global._r_ = globalComponentsContext = new GlobalComponentsContext(out);
        }
    }

    this.P_ = globalComponentsContext;
    this._r_ = [];
    this._s_ = out;
    this._p_ = componentDef;
    this._q_ = undefined;
}

ComponentsContext.prototype = {
    _t_: function (doc) {
        var componentDefs = this._r_;

        ComponentsContext._u_(componentDefs, doc);

        this._s_.emit("_v_");

        // Reset things stored in global since global is retained for
        // future renders
        this._s_.global._r_ = undefined;

        return componentDefs;
    }
};

function getComponentsContext(out) {
    return out._r_ || (out._r_ = new ComponentsContext(out));
}

module.exports = exports = ComponentsContext;

exports.__ = getComponentsContext;