"use strict";

var repeatedRegExp = /\[\]$/;
var componentUtil = require("./util");
var attachBubblingEvent = componentUtil.Z_;
var extend = require("raptor-util/extend");
var KeySequence = require("./KeySequence");

var FLAG_WILL_RERENDER_IN_BROWSER = 1;
/*
var FLAG_HAS_BODY_EL = 2;
var FLAG_HAS_HEAD_EL = 4;
*/

/**
 * A ComponentDef is used to hold the metadata collected at runtime for
 * a single component and this information is used to instantiate the component
 * later (after the rendered HTML has been added to the DOM)
 */
function ComponentDef(component, componentId, globalComponentsContext) {
    this.___ = globalComponentsContext; // The AsyncWriter that this component is associated with
    this._a_ = component;
    this.id = componentId;

    this._b_ = undefined; // An array of DOM events that need to be added (in sets of three)

    this._c_ = false;

    this._d_ = false;
    this._e_ = 0;

    this._f_ = 0; // The unique integer to use for the next scoped ID

    this.x_ = null;

    this._g_ = null;
}

ComponentDef.prototype = {
    _h_: function (key) {
        var keySequence = this.x_ || (this.x_ = new KeySequence());
        return keySequence._h_(key);
    },

    _i_: function (key, bodyOnly) {
        var lookup = this._g_ || (this._g_ = {});
        lookup[key] = bodyOnly ? 2 : 1;
    },

    /**
     * This helper method generates a unique and fully qualified DOM element ID
     * that is unique within the scope of the current component. This method prefixes
     * the the nestedId with the ID of the current component. If nestedId ends
     * with `[]` then it is treated as a repeated ID and we will generate
     * an ID with the current index for the current nestedId.
     * (e.g. "myParentId-foo[0]", "myParentId-foo[1]", etc.)
     */
    elId: function (nestedId) {
        var id = this.id;
        if (nestedId == null) {
            return id;
        } else {
            if (typeof nestedId == "string" && repeatedRegExp.test(nestedId)) {
                return this.___._j_(id, nestedId);
            } else {
                return id + "-" + nestedId;
            }
        }
    },
    /**
     * Registers a DOM event for a nested HTML element associated with the
     * component. This is only done for non-bubbling events that require
     * direct event listeners to be added.
     * @param  {String} type The DOM event type ("mouseover", "mousemove", etc.)
     * @param  {String} targetMethod The name of the method to invoke on the scoped component
     * @param  {String} elId The DOM element ID of the DOM element that the event listener needs to be added too
     */
    e: function (type, targetMethod, elId, isOnce, extraArgs) {
        if (targetMethod) {
            // The event handler method is allowed to be conditional. At render time if the target
            // method is null then we do not attach any direct event listeners.
            (this._b_ || (this._b_ = [])).push([type, targetMethod, elId, isOnce, extraArgs]);
        }
    },
    /**
     * Returns the next auto generated unique ID for a nested DOM element or nested DOM component
     */
    _k_: function () {
        return this.id + "-c" + this._f_++;
    },

    d: function (handlerMethodName, isOnce, extraArgs) {
        return attachBubblingEvent(this, handlerMethodName, isOnce, extraArgs);
    },

    get _l_() {
        return this._a_._l_;
    }
};

ComponentDef._m_ = function (o, types, global, registry) {
    var id = o[0];
    var typeName = types[o[1]];
    var input = o[2];
    var extra = o[3];

    var isLegacy = extra.l;
    var state = extra.s;
    var componentProps = extra.w;
    var flags = extra.f;

    var component = typeName /* legacy */ && registry._n_(typeName, id, isLegacy);

    // Prevent newly created component from being queued for update since we area
    // just building it from the server info
    component.s_ = true;

    if (flags & FLAG_WILL_RERENDER_IN_BROWSER) {
        if (component.onCreate) {
            component.onCreate(input, { global: global });
        }
        if (component.onInput) {
            input = component.onInput(input, { global: global }) || input;
        }
    } else {
        if (state) {
            var undefinedPropNames = extra.u;
            if (undefinedPropNames) {
                undefinedPropNames.forEach(function (undefinedPropName) {
                    state[undefinedPropName] = undefined;
                });
            }
            // We go through the setter here so that we convert the state object
            // to an instance of `State`
            component.state = state;
        }

        if (componentProps) {
            extend(component, componentProps);
        }
    }

    component.o_ = input;

    if (extra.b) {
        component.l_ = extra.b;
    }

    var scope = extra.p;
    var customEvents = extra.e;
    if (customEvents) {
        component.W_(customEvents, scope);
    }

    component.q_ = global;

    return {
        id: id,
        _a_: component,
        _o_: extra.r,
        _b_: extra.d,
        _e_: extra.f || 0
    };
};

module.exports = ComponentDef;