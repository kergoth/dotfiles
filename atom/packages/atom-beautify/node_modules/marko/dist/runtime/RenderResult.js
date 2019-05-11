var domInsert = require("./dom-insert");

function getComponentDefs(result) {
    var componentDefs = result._r_;

    if (!componentDefs) {
        throw Error("No component");
    }
    return componentDefs;
}

function RenderResult(out) {
    this.out = this._s_ = out;
    this._r_ = undefined;
}

module.exports = RenderResult;

var proto = RenderResult.prototype = {
    getComponent: function () {
        return this.getComponents()[0];
    },
    getComponents: function (selector) {
        if (this._r_ === undefined) {
            throw Error("Not added to DOM");
        }

        var componentDefs = getComponentDefs(this);

        var components = [];

        componentDefs.forEach(function (componentDef) {
            var component = componentDef._a_;
            if (!selector || selector(component)) {
                components.push(component);
            }
        });

        return components;
    },

    afterInsert: function (doc) {
        var out = this._s_;
        var componentsContext = out._r_;
        if (componentsContext) {
            this._r_ = componentsContext._t_(doc);
        } else {
            this._r_ = null;
        }

        return this;
    },
    getNode: function (doc) {
        return this._s_.aB_(doc);
    },
    getOutput: function () {
        return this._s_.S_();
    },
    toString: function () {
        return this._s_.toString();
    },
    document: typeof document != "undefined" && document
};

// Add all of the following DOM methods to Component.prototype:
// - appendTo(referenceEl)
// - replace(referenceEl)
// - replaceChildrenOf(referenceEl)
// - insertBefore(referenceEl)
// - insertAfter(referenceEl)
// - prependTo(referenceEl)
domInsert(proto, function getEl(renderResult, referenceEl) {
    return renderResult.getNode(referenceEl.ownerDocument);
}, function afterInsert(renderResult, referenceEl) {
    var isShadow = typeof ShadowRoot === "function" && referenceEl instanceof ShadowRoot;
    return renderResult.afterInsert(isShadow ? referenceEl : referenceEl.ownerDocument);
});