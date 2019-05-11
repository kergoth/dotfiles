var markoUID = window.$MUID || (window.$MUID = { i: 0 });
var runtimeId = markoUID.i++;

var componentLookup = {};

var defaultDocument = document;
var EMPTY_OBJECT = {};

function getComponentForEl(el, doc) {
    if (el) {
        var node = typeof el == "string" ? (doc || defaultDocument).getElementById(el) : el;
        if (node) {
            return node.B_;
        }
    }
}

var lifecycleEventMethods = {};

["create", "render", "update", "mount", "destroy"].forEach(function (eventName) {
    lifecycleEventMethods[eventName] = "on" + eventName[0].toUpperCase() + eventName.substring(1);
});

/**
 * This method handles invoking a component's event handler method
 * (if present) while also emitting the event through
 * the standard EventEmitter.prototype.emit method.
 *
 * Special events and their corresponding handler methods
 * include the following:
 *
 * beforeDestroy --> onBeforeDestroy
 * destroy       --> onDestroy
 * beforeUpdate  --> onBeforeUpdate
 * update        --> onUpdate
 * render        --> onRender
 */
function emitLifecycleEvent(component, eventType, eventArg1, eventArg2) {
    var listenerMethod = component[lifecycleEventMethods[eventType]];

    if (listenerMethod !== undefined) {
        listenerMethod.call(component, eventArg1, eventArg2);
    }

    component.emit(eventType, eventArg1, eventArg2);
}

function destroyComponentForNode(node) {
    var componentToDestroy = node.B_;
    if (componentToDestroy) {
        componentToDestroy.z_();
        delete componentLookup[componentToDestroy.id];
    }
}
function destroyNodeRecursive(node, component) {
    if (node.nodeType === 1) {
        var key;

        if (component && (key = node.ah_)) {
            if (node === component.w_[key]) {
                delete component.w_[key];
            }
        }

        var curChild = node.firstChild;
        while (curChild) {
            destroyComponentForNode(curChild);
            destroyNodeRecursive(curChild, component);
            curChild = curChild.nextSibling;
        }
    }
}

function nextComponentId() {
    // Each component will get an ID that is unique across all loaded
    // marko runtimes. This allows multiple instances of marko to be
    // loaded in the same window and they should all place nice
    // together
    return "c" + markoUID.i++;
}

function nextComponentIdProvider() {
    return nextComponentId;
}

function attachBubblingEvent(componentDef, handlerMethodName, isOnce, extraArgs) {
    if (handlerMethodName) {
        var componentId = componentDef.id;
        if (extraArgs) {
            return [handlerMethodName, componentId, isOnce, extraArgs];
        } else {
            return [handlerMethodName, componentId, isOnce];
        }
    }
}

function getMarkoPropsFromEl(el) {
    var vElement = el.ai_;
    var virtualProps;

    if (vElement) {
        virtualProps = vElement.aj_;
    } else {
        virtualProps = el.ak_;
        if (!virtualProps) {
            virtualProps = el.getAttribute("data-marko");
            el.ak_ = virtualProps = virtualProps ? JSON.parse(virtualProps) : EMPTY_OBJECT;
        }
    }

    return virtualProps;
}

exports._J_ = runtimeId;
exports.a_ = componentLookup;
exports._N_ = getComponentForEl;
exports.b_ = emitLifecycleEvent;
exports.al_ = destroyComponentForNode;
exports.c_ = destroyNodeRecursive;
exports._w_ = nextComponentIdProvider;
exports.Z_ = attachBubblingEvent;
exports._K_ = getMarkoPropsFromEl;