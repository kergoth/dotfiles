"use strict";
/* jshint newcap:false */

var complain;

var domInsert = require("../runtime/dom-insert");
var defaultCreateOut = require("../runtime/createOut");
var getComponentsContext = require("./ComponentsContext").__;
var componentsUtil = require("./util");
var componentLookup = componentsUtil.a_;
var emitLifecycleEvent = componentsUtil.b_;
var destroyNodeRecursive = componentsUtil.c_;
var EventEmitter = require("events-light");
var RenderResult = require("../runtime/RenderResult");
var SubscriptionTracker = require("listener-tracker");
var inherit = require("raptor-util/inherit");
var updateManager = require("./update-manager");
var morphdom = require("../morphdom");
var eventDelegation = require("./event-delegation");

var slice = Array.prototype.slice;

var COMPONENT_SUBSCRIBE_TO_OPTIONS;
var NON_COMPONENT_SUBSCRIBE_TO_OPTIONS = {
    addDestroyListener: false
};

var emit = EventEmitter.prototype.emit;
var ELEMENT_NODE = 1;

function removeListener(removeEventListenerHandle) {
    removeEventListenerHandle();
}

function handleCustomEventWithMethodListener(component, targetMethodName, args, extraArgs) {
    // Remove the "eventType" argument
    args.push(component);

    if (extraArgs) {
        args = extraArgs.concat(args);
    }

    var targetComponent = componentLookup[component.d_];
    var targetMethod = targetComponent[targetMethodName];
    if (!targetMethod) {
        throw Error("Method not found: " + targetMethodName);
    }

    targetMethod.apply(targetComponent, args);
}

function resolveKeyHelper(key, index) {
    return index ? key + "_" + index : key;
}

function resolveComponentIdHelper(component, key, index) {
    return component.id + "-" + resolveKeyHelper(key, index);
}

/**
 * This method is used to process "update_<stateName>" handler functions.
 * If all of the modified state properties have a user provided update handler
 * then a rerender will be bypassed and, instead, the DOM will be updated
 * looping over and invoking the custom update handlers.
 * @return {boolean} Returns true if if the DOM was updated. False, otherwise.
 */
function processUpdateHandlers(component, stateChanges, oldState) {
    var handlerMethod;
    var handlers;

    for (var propName in stateChanges) {
        if (stateChanges.hasOwnProperty(propName)) {
            var handlerMethodName = "update_" + propName;

            handlerMethod = component[handlerMethodName];
            if (handlerMethod) {
                (handlers || (handlers = [])).push([propName, handlerMethod]);
            } else {
                // This state change does not have a state handler so return false
                // to force a rerender
                return;
            }
        }
    }

    // If we got here then all of the changed state properties have
    // an update handler or there are no state properties that actually
    // changed.
    if (handlers) {
        // Otherwise, there are handlers for all of the changed properties
        // so apply the updates using those handlers

        handlers.forEach(function (handler) {
            var propertyName = handler[0];
            handlerMethod = handler[1];

            var newValue = stateChanges[propertyName];
            var oldValue = oldState[propertyName];
            handlerMethod.call(component, newValue, oldValue);
        });

        emitLifecycleEvent(component, "update");

        component.e_();
    }

    return true;
}

function checkInputChanged(existingComponent, oldInput, newInput) {
    if (oldInput != newInput) {
        if (oldInput == null || newInput == null) {
            return true;
        }

        var oldKeys = Object.keys(oldInput);
        var newKeys = Object.keys(newInput);
        var len = oldKeys.length;
        if (len !== newKeys.length) {
            return true;
        }

        for (var i = 0; i < len; i++) {
            var key = oldKeys[i];
            if (oldInput[key] !== newInput[key]) {
                return true;
            }
        }
    }

    return false;
}

function getNodes(component) {
    var nodes = [];
    component.f_(nodes.push.bind(nodes));
    return nodes;
}

var componentProto;

/**
 * Base component type.
 *
 * NOTE: Any methods that are prefixed with an underscore should be considered private!
 */
function Component(id) {
    EventEmitter.call(this);
    this.id = id;
    this.g_ = null;
    this.h_ = null;
    this.i_ = null;
    this.j_ = null;
    this.k_ = null;
    this.l_ = null; // Used to keep track of bubbling DOM events for components rendered on the server
    this.m_ = null;
    this.d_ = null;
    this.n_ = null;
    this.o_ = undefined;
    this.p_ = false;
    this.q_ = undefined;

    this.r_ = false;
    this.s_ = false;
    this.t_ = false;
    this.u_ = false;

    this.v_ = undefined;

    this.w_ = {};
    this.x_ = undefined;
}

Component.prototype = componentProto = {
    y_: true,

    subscribeTo: function (target) {
        if (!target) {
            throw TypeError();
        }

        var subscriptions = this.j_ || (this.j_ = new SubscriptionTracker());

        var subscribeToOptions = target.y_ ? COMPONENT_SUBSCRIBE_TO_OPTIONS : NON_COMPONENT_SUBSCRIBE_TO_OPTIONS;

        return subscriptions.subscribeTo(target, subscribeToOptions);
    },

    emit: function (eventType) {
        var customEvents = this.m_;
        var target;

        if (customEvents && (target = customEvents[eventType])) {
            var targetMethodName = target[0];
            var isOnce = target[1];
            var extraArgs = target[2];
            var args = slice.call(arguments, 1);

            handleCustomEventWithMethodListener(this, targetMethodName, args, extraArgs);

            if (isOnce) {
                delete customEvents[eventType];
            }
        }

        if (this.listenerCount(eventType)) {
            return emit.apply(this, arguments);
        }
    },
    getElId: function (key, index) {
        return resolveComponentIdHelper(this, key, index);
    },
    getEl: function (key, index) {
        if (key) {
            return this.w_[resolveKeyHelper(key, index)];
        } else {
            return this.h_;
        }
    },
    getEls: function (key) {
        key = key + "[]";

        var els = [];
        var i = 0;
        var el;
        while (el = this.getEl(key, i)) {
            els.push(el);
            i++;
        }
        return els;
    },
    getComponent: function (key, index) {
        return componentLookup[resolveComponentIdHelper(this, key, index)];
    },
    getComponents: function (key) {
        key = key + "[]";

        var components = [];
        var i = 0;
        var component;
        while (component = componentLookup[resolveComponentIdHelper(this, key, i)]) {
            components.push(component);
            i++;
        }
        return components;
    },
    destroy: function () {
        if (this.r_) {
            return;
        }

        var nodes = getNodes(this);

        this.z_();

        nodes.forEach(function (node) {
            destroyNodeRecursive(node);

            if (eventDelegation.A_(node) !== false) {
                node.parentNode.removeChild(node);
            }
        });

        delete componentLookup[this.id];
    },

    z_: function () {
        if (this.r_) {
            return;
        }

        emitLifecycleEvent(this, "destroy");
        this.r_ = true;

        this.h_.B_ = undefined;

        this.h_ = this.i_ = null;

        // Unsubscribe from all DOM events
        this.C_();

        var subscriptions = this.j_;
        if (subscriptions) {
            subscriptions.removeAllListeners();
            this.j_ = null;
        }
    },

    isDestroyed: function () {
        return this.r_;
    },
    get state() {
        return this.g_;
    },
    set state(newState) {
        var state = this.g_;
        if (!state && !newState) {
            return;
        }

        if (!state) {
            state = this.g_ = new this.D_(this);
        }

        state.E_(newState || {});

        if (state.t_) {
            this.F_();
        }

        if (!newState) {
            this.g_ = null;
        }
    },
    setState: function (name, value) {
        var state = this.g_;

        if (typeof name == "object") {
            // Merge in the new state with the old state
            var newState = name;
            for (var k in newState) {
                if (newState.hasOwnProperty(k)) {
                    state.G_(k, newState[k], true /* ensure:true */);
                }
            }
        } else {
            state.G_(name, value, true /* ensure:true */);
        }
    },

    setStateDirty: function (name, value) {
        var state = this.g_;

        if (arguments.length == 1) {
            value = state[name];
        }

        state.G_(name, value, true /* ensure:true */
        , true /* forceDirty:true */
        );
    },

    replaceState: function (newState) {
        this.g_.E_(newState);
    },

    get input() {
        return this.o_;
    },
    set input(newInput) {
        if (this.u_) {
            this.o_ = newInput;
        } else {
            this.H_(newInput);
        }
    },

    H_: function (newInput, onInput, out) {
        onInput = onInput || this.onInput;
        var updatedInput;

        var oldInput = this.o_;
        this.o_ = undefined;

        if (onInput) {
            // We need to set a flag to preview `this.input = foo` inside
            // onInput causing infinite recursion
            this.u_ = true;
            updatedInput = onInput.call(this, newInput || {}, out);
            this.u_ = false;
        }

        newInput = this.n_ = updatedInput || newInput;

        if (this.t_ = checkInputChanged(this, oldInput, newInput)) {
            this.F_();
        }

        if (this.o_ === undefined) {
            this.o_ = newInput;
            if (newInput && newInput.$global) {
                this.q_ = newInput.$global;
            }
        }

        return newInput;
    },

    forceUpdate: function () {
        this.t_ = true;
        this.F_();
    },

    F_: function () {
        if (!this.s_) {
            this.s_ = true;
            updateManager.I_(this);
        }
    },

    update: function () {
        if (this.r_ === true || this.J_ === false) {
            return;
        }

        var input = this.o_;
        var state = this.g_;

        if (this.t_ === false && state !== null && state.t_ === true) {
            if (processUpdateHandlers(this, state.K_, state.L_, state)) {
                state.t_ = false;
            }
        }

        if (this.J_ === true) {
            // The UI component is still dirty after process state handlers
            // then we should rerender

            if (this.shouldUpdate(input, state) !== false) {
                this.M_(false);
            }
        }

        this.e_();
    },

    get J_() {
        return this.t_ === true || this.g_ !== null && this.g_.t_ === true;
    },

    e_: function () {
        this.t_ = false;
        this.s_ = false;
        this.n_ = null;
        var state = this.g_;
        if (state) {
            state.e_();
        }
    },

    shouldUpdate: function () {
        return true;
    },

    b_: function (eventType, eventArg1, eventArg2) {
        emitLifecycleEvent(this, eventType, eventArg1, eventArg2);
    },

    M_: function (isRerenderInBrowser) {
        var self = this;
        var renderer = self.N_;

        if (!renderer) {
            throw TypeError();
        }

        var startNode = this.h_;
        var endNodeNextSibling = this.i_.nextSibling;

        var doc = self.v_;
        var input = this.n_ || this.o_;
        var globalData = this.q_;

        updateManager.O_(function () {
            var createOut = renderer.createOut || defaultCreateOut;
            var out = createOut(globalData);
            out.sync();
            out.v_ = self.v_;

            var componentsContext = getComponentsContext(out);
            var globalComponentsContext = componentsContext.P_;
            globalComponentsContext.Q_ = self;
            globalComponentsContext.R_ = isRerenderInBrowser;

            renderer(input, out);

            var result = new RenderResult(out);

            var targetNode = out.S_();

            morphdom(startNode.parentNode, startNode, endNodeNextSibling, targetNode, doc, componentsContext);

            result.afterInsert(doc);
        });

        this.e_();
    },

    T_: function () {
        var fragment = this.v_.createDocumentFragment();
        this.f_(fragment.appendChild.bind(fragment));
        return fragment;
    },

    f_: function (callback) {
        var currentNode = this.h_;
        var endNode = this.i_;

        for (;;) {
            var nextSibling = currentNode.nextSibling;
            callback(currentNode);
            if (currentNode == endNode) {
                break;
            }
            currentNode = nextSibling;
        }
    },

    C_: function () {
        var eventListenerHandles = this.k_;
        if (eventListenerHandles) {
            eventListenerHandles.forEach(removeListener);
            this.k_ = null;
        }
    },

    get U_() {
        var state = this.g_;
        return state && state.V_;
    },

    W_: function (customEvents, scope) {
        var finalCustomEvents = this.m_ = {};
        this.d_ = scope;

        customEvents.forEach(function (customEvent) {
            var eventType = customEvent[0];
            var targetMethodName = customEvent[1];
            var isOnce = customEvent[2];
            var extraArgs = customEvent[3];

            finalCustomEvents[eventType] = [targetMethodName, isOnce, extraArgs];
        });
    },

    get el() {
        var el = this.h_;
        // eslint-disable-next-line no-constant-condition

        while (el) {
            if (el.nodeType === ELEMENT_NODE) return el;
            if (el === this.i_) return;
            el = el.nextSibling;
        }
    },

    get els() {
        return getNodes(this).filter(function (el) {
            return el.nodeType === ELEMENT_NODE;
        });
        // eslint-disable-next-line no-constant-condition
    }
};

componentProto.elId = componentProto.getElId;
componentProto.X_ = componentProto.update;
componentProto.Y_ = componentProto.destroy;

// Add all of the following DOM methods to Component.prototype:
// - appendTo(referenceEl)
// - replace(referenceEl)
// - replaceChildrenOf(referenceEl)
// - insertBefore(referenceEl)
// - insertAfter(referenceEl)
// - prependTo(referenceEl)
domInsert(componentProto, function getEl(component) {
    return component.T_();
}, function afterInsert(component) {
    return component;
});

inherit(Component, EventEmitter);

module.exports = Component;