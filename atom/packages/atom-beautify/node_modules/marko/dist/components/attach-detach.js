var eventDelegation = require("./event-delegation");
var delegateEvent = eventDelegation._F_;
var getEventFromEl = eventDelegation._G_;

// var componentsUtil = require('./util');
// var destroyNodeRecursive = componentsUtil.___destroyNodeRecursive;
// var destroyComponentForNode = componentsUtil.___destroyComponentForNode;

function handleNodeAttach(node, componentsContext) {
    if (node.nodeType === 1) {
        var eventName = "onattach";
        var target = getEventFromEl(node, eventName);
        if (target) {
            var out = componentsContext._s_;
            var data = out.data;

            var attachTargets = data._H_;
            if (!attachTargets) {
                attachTargets = data._H_ = [];
                out.on("_v_", function () {
                    for (var i = 0; i < attachTargets.length; i += 2) {
                        var node = attachTargets[i];
                        var target = attachTargets[i + 1];
                        delegateEvent(node, eventName, target, {});
                    }
                });
            }

            attachTargets.push(node);
            attachTargets.push(target);
        }
    }
}

function handleNodeDetach(node) {
    if (node.nodeType === 1) {
        var eventName = "ondetach";
        var target = getEventFromEl(node, eventName);
        if (target) {
            var allowDetach;

            delegateEvent(node, eventName, target, {
                preventDefault: function () {
                    allowDetach = false;
                },
                detach: function () {
                    var parentNode = node.parentNode;
                    if (parentNode) {
                        parentNode.removeChild(node);
                    }
                }
            });

            return allowDetach;
        }
    }
}

eventDelegation._I_ = handleNodeAttach;
eventDelegation.A_ = handleNodeDetach;