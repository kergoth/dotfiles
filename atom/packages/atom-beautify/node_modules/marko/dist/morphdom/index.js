"use strict";

var specialElHandlers = require("./specialElHandlers");
var componentsUtil = require("../components/util");
var existingComponentLookup = componentsUtil.a_;
var destroyNodeRecursive = componentsUtil.c_;
var VElement = require("../runtime/vdom/vdom").am_;
var virtualizeElement = VElement.an_;
var morphAttrs = VElement.ao_;
var eventDelegation = require("../components/event-delegation");

var ELEMENT_NODE = 1;
var TEXT_NODE = 3;
var COMMENT_NODE = 8;
var COMPONENT_NODE = 2;

// var FLAG_IS_SVG = 1;
// var FLAG_IS_TEXTAREA = 2;
// var FLAG_SIMPLE_ATTRS = 4;
var FLAG_PRESERVE = 8;
// var FLAG_CUSTOM_ELEMENT = 16;

function compareNodeNames(fromEl, toEl) {
    return fromEl.ap_ === toEl.ap_;
}

function onNodeAdded(node, componentsContext) {
    if (node.nodeType === 1) {
        eventDelegation._I_(node, componentsContext);
    }
}

function insertBefore(node, referenceNode, parentNode) {
    return parentNode.insertBefore(node, referenceNode);
}

function insertAfter(node, referenceNode, parentNode) {
    return parentNode.insertBefore(node, referenceNode && referenceNode.nextSibling);
}

function morphdom(parentNode, startNode, endNode, toNode, doc, componentsContext) {
    var globalComponentsContext;
    var isRerenderInBrowser = false;

    if (componentsContext) {
        globalComponentsContext = componentsContext.P_;
        isRerenderInBrowser = globalComponentsContext.R_;
    }

    function createMarkerComment() {
        return doc.createComment("$marko");
    }

    function insertVirtualNodeBefore(vNode, key, referenceEl, parentEl, component) {
        var realNode = vNode.aq_(doc);
        insertBefore(realNode, referenceEl, parentEl);

        if (vNode.ar_ === ELEMENT_NODE) {
            if (key) {
                realNode.ah_ = key;
                component.w_[key] = realNode;
            }

            morphChildren(realNode, null, null, vNode, component);
        }

        onNodeAdded(realNode, componentsContext);
    }

    function insertVirtualComponentBefore(vComponent, referenceNode, referenceNodeParentEl, component) {
        component.h_ = component.i_ = insertBefore(createMarkerComment(), referenceNode, referenceNodeParentEl);
        morphComponent(referenceNodeParentEl, component, vComponent);
    }

    function resolveComponentEndNode(startNode, vChild, parentNode) {
        var endNode = startNode;

        // We track text nodes because multiple adjacent VText nodes should
        // be treated as a single VText node for purposes of pairing with HTML
        // that was rendered on the server since browsers will only see
        // a single text node
        var isPrevText = vChild.ar_ === TEXT_NODE;

        while (vChild = vChild.as_) {
            var nextRealNode = endNode.nextSibling;

            // We stop when there are no more corresponding real nodes or when
            // we reach the end boundary for our UI component
            if (!nextRealNode || nextRealNode.i_) {
                break;
            }
            var isText = vChild.ar_ === TEXT_NODE;
            if (isText && isPrevText) {
                // Pretend like we didn't see this VText node since it
                // the previous vnode was also a VText node
                continue;
            }
            endNode = nextRealNode;
            isPrevText = isText;
        }

        if (endNode === startNode) {
            return insertAfter(createMarkerComment(), startNode, parentNode);
        }

        return endNode;
    }

    function morphComponent(parentFromNode, component, vComponent) {
        // We create a key sequence to generate unique keys since a key
        // can be repeated
        component.x_ = globalComponentsContext._A_();

        var startNode = component.h_;
        var endNode = component.i_;
        startNode.B_ = undefined;
        endNode.i_ = undefined;

        var beforeChild = startNode.previousSibling;
        var afterChild = endNode.nextSibling;
        var tempChild;

        if (!beforeChild) {
            tempChild = beforeChild = insertBefore(createMarkerComment(), startNode, parentFromNode);
        }

        morphChildren(parentFromNode, startNode, afterChild, vComponent, component);

        endNode = undefined;

        startNode = beforeChild.nextSibling;
        if (!startNode || startNode === afterChild) {
            startNode = endNode = insertAfter(createMarkerComment(), beforeChild, parentFromNode);
        }

        if (tempChild) {
            parentFromNode.removeChild(tempChild);
        }

        if (!endNode) {
            if (afterChild) {
                endNode = afterChild.previousSibling;
            } else {
                endNode = parentFromNode.lastChild;
            }
        }

        // Make sure we don't use a detached node as the component boundary and
        // we can't use a node that is already the boundary node for another component
        if (startNode.at_ !== undefined || startNode.B_) {
            startNode = insertBefore(createMarkerComment(), startNode, parentFromNode);
        }

        if (endNode.at_ !== undefined || endNode.i_) {
            endNode = insertAfter(createMarkerComment(), endNode, parentFromNode);
        }

        startNode.B_ = component;
        endNode.i_ = true;

        component.h_ = startNode;
        component.i_ = endNode;

        component.x_ = undefined; // We don't need to track keys anymore

        return afterChild;
    }

    var detachedNodes = [];

    function detachNode(node, parentNode, component) {
        if (node.nodeType === ELEMENT_NODE) {
            detachedNodes.push(node);
            node.at_ = component || true;
        } else {
            destroyNodeRecursive(node);
            parentNode.removeChild(node);
        }
    }

    function destroyComponent(component) {
        component.destroy();
    }

    function morphChildren(parentFromNode, startNode, endNode, toNode, component) {
        var curFromNodeChild = startNode;
        var curToNodeChild = toNode.au_;

        var curToNodeKey;
        var curFromNodeKey;
        var curToNodeType;

        var fromNextSibling;
        var toNextSibling;
        var matchingFromEl;
        var matchingFromComponent;
        var curVFromNodeChild;
        var fromComponent;

        outer: while (curToNodeChild) {
            toNextSibling = curToNodeChild.as_;
            curToNodeType = curToNodeChild.ar_;

            var componentForNode = curToNodeChild._a_ || component;

            if (curToNodeType === COMPONENT_NODE) {
                if ((matchingFromComponent = existingComponentLookup[componentForNode.id]) === undefined) {
                    if (isRerenderInBrowser === true) {
                        var firstVChild = curToNodeChild.au_;
                        if (firstVChild) {
                            if (!curFromNodeChild) {
                                curFromNodeChild = insertBefore(createMarkerComment(), null, parentFromNode);
                            }

                            componentForNode.h_ = curFromNodeChild;
                            componentForNode.i_ = resolveComponentEndNode(curFromNodeChild, firstVChild, parentFromNode);
                        } else {
                            componentForNode.h_ = componentForNode.i_ = insertBefore(createMarkerComment(), curFromNodeChild, parentFromNode);
                        }

                        curFromNodeChild = morphComponent(parentFromNode, componentForNode, curToNodeChild);
                    } else {
                        insertVirtualComponentBefore(curToNodeChild, curFromNodeChild, parentFromNode, componentForNode);
                    }
                } else {
                    if (matchingFromComponent.h_ !== curFromNodeChild) {
                        if (curFromNodeChild && (fromComponent = curFromNodeChild.B_) && globalComponentsContext._z_[fromComponent.id] === undefined) {
                            // The component associated with the current real DOM node was not rendered
                            // so we should just remove it out of the real DOM by destroying it
                            curFromNodeChild = fromComponent.i_.nextSibling;
                            destroyComponent(fromComponent);
                            continue;
                        }

                        // We need to move the existing component into
                        // the correct location and preserve focus.
                        var activeElement = doc.activeElement;
                        insertBefore(matchingFromComponent.T_(), curFromNodeChild, parentFromNode);
                        // This focus patch should be a temporary fix.
                        if (activeElement !== doc.activeElement && activeElement.focus) {
                            activeElement.focus();
                        }
                    }

                    if (curToNodeChild.av_) {
                        curFromNodeChild = matchingFromComponent.i_.nextSibling;
                    } else {
                        curFromNodeChild = morphComponent(parentFromNode, componentForNode, curToNodeChild);
                    }
                }

                curToNodeChild = toNextSibling;
                continue;
            } else if (curToNodeKey = curToNodeChild.aw_) {
                curVFromNodeChild = undefined;
                curFromNodeKey = undefined;

                var keySequence = componentForNode.x_ || (componentForNode.x_ = globalComponentsContext._A_());

                // We have a keyed element. This is the fast path for matching
                // up elements
                curToNodeKey = keySequence._h_(curToNodeKey);

                if (curFromNodeChild) {
                    if (curFromNodeChild !== endNode) {
                        curFromNodeKey = curFromNodeChild.ah_;
                        curVFromNodeChild = curFromNodeChild.ai_;
                        fromNextSibling = curFromNodeChild.nextSibling;
                    }
                }

                if (curFromNodeKey === curToNodeKey) {
                    // Elements line up. Now we just have to make sure they are compatible
                    if ((curToNodeChild._e_ & FLAG_PRESERVE) === 0) {
                        // We just skip over the fromNode if it is preserved

                        if (compareNodeNames(curToNodeChild, curVFromNodeChild)) {
                            morphEl(curFromNodeChild, curVFromNodeChild, curToNodeChild, componentForNode, curToNodeKey);
                        } else {
                            // Remove the old node
                            detachNode(curFromNodeChild, parentFromNode, componentForNode);

                            // Incompatible nodes. Just move the target VNode into the DOM at this position
                            insertVirtualNodeBefore(curToNodeChild, curToNodeKey, curFromNodeChild, parentFromNode, componentForNode);
                        }
                    } else {
                        // this should be preserved.
                    }
                } else {
                    if ((matchingFromEl = componentForNode.w_[curToNodeKey]) === undefined) {
                        if (isRerenderInBrowser === true && curFromNodeChild && curFromNodeChild.nodeType === ELEMENT_NODE && curFromNodeChild.nodeName === curToNodeChild.ap_) {
                            curVFromNodeChild = virtualizeElement(curFromNodeChild);
                            curFromNodeChild.ah_ = curToNodeKey;
                            morphEl(curFromNodeChild, curVFromNodeChild, curToNodeChild, componentForNode, curToNodeKey);
                            curToNodeChild = toNextSibling;
                            curFromNodeChild = fromNextSibling;
                            continue;
                        }

                        insertVirtualNodeBefore(curToNodeChild, curToNodeKey, curFromNodeChild, parentFromNode, componentForNode);
                        fromNextSibling = curFromNodeChild;
                    } else {
                        if (matchingFromEl.at_ !== undefined) {
                            matchingFromEl.at_ = undefined;
                        }
                        curVFromNodeChild = matchingFromEl.ai_;

                        if (compareNodeNames(curVFromNodeChild, curToNodeChild)) {
                            if (fromNextSibling === matchingFromEl) {
                                // Single element removal:
                                // A <-> A
                                // B <-> C <-- We are here
                                // C     D
                                // D
                                //
                                // Single element swap:
                                // A <-> A
                                // B <-> C <-- We are here
                                // C     B

                                if (toNextSibling && toNextSibling.aw_ === curFromNodeKey) {
                                    // Single element swap

                                    // We want to stay on the current real DOM node
                                    fromNextSibling = curFromNodeChild;

                                    // But move the matching element into place
                                    insertBefore(matchingFromEl, curFromNodeChild, parentFromNode);
                                } else {
                                    // Single element removal

                                    // We need to remove the current real DOM node
                                    // and the matching real DOM node will fall into
                                    // place. We will continue diffing with next sibling
                                    // after the real DOM node that just fell into place
                                    fromNextSibling = fromNextSibling.nextSibling;

                                    if (curFromNodeChild) {
                                        detachNode(curFromNodeChild, parentFromNode, componentForNode);
                                    }
                                }
                            } else {
                                // A <-> A
                                // B <-> D <-- We are here
                                // C
                                // D

                                // We need to move the matching node into place
                                insertAfter(matchingFromEl, curFromNodeChild, parentFromNode);

                                if (curFromNodeChild) {
                                    detachNode(curFromNodeChild, parentFromNode, componentForNode);
                                }
                            }

                            if ((curToNodeChild._e_ & FLAG_PRESERVE) === 0) {
                                morphEl(matchingFromEl, curVFromNodeChild, curToNodeChild, componentForNode, curToNodeKey, curToNodeKey);
                            }
                        } else {
                            insertVirtualNodeBefore(curToNodeChild, curToNodeKey, curFromNodeChild, parentFromNode, componentForNode);
                            detachNode(matchingFromEl, parentFromNode, componentForNode);
                        }
                    }
                }

                curToNodeChild = toNextSibling;
                curFromNodeChild = fromNextSibling;
                continue;
            }

            // The know the target node is not a VComponent node and we know
            // it is also not a preserve node. Let's now match up the HTML
            // element, text node, comment, etc.
            while (curFromNodeChild && curFromNodeChild !== endNode) {
                if ((fromComponent = curFromNodeChild.B_) && fromComponent !== componentForNode) {
                    // The current "to" element is not associated with a component,
                    // but the current "from" element is associated with a component

                    // Even if we destroy the current component in the original
                    // DOM or not, we still need to skip over it since it is
                    // not compatible with the current "to" node
                    curFromNodeChild = fromComponent.i_.nextSibling;

                    if (!globalComponentsContext._z_[fromComponent.id]) {
                        destroyComponent(fromComponent);
                    }

                    continue; // Move to the next "from" node
                }

                fromNextSibling = curFromNodeChild.nextSibling;

                var curFromNodeType = curFromNodeChild.nodeType;

                var isCompatible = undefined;

                if (curFromNodeType === curToNodeType) {
                    if (curFromNodeType === ELEMENT_NODE) {
                        // Both nodes being compared are Element nodes
                        curVFromNodeChild = curFromNodeChild.ai_;
                        if (curVFromNodeChild === undefined) {
                            if (isRerenderInBrowser === true) {
                                curVFromNodeChild = virtualizeElement(curFromNodeChild);
                            } else {
                                // Skip over nodes that don't look like ours...
                                curFromNodeChild = fromNextSibling;
                                continue;
                            }
                        } else if (curFromNodeKey = curVFromNodeChild.aw_) {
                            // We have a keyed element here but our target VDOM node
                            // is not keyed so this not doesn't belong
                            isCompatible = false;
                        }

                        isCompatible = isCompatible !== false && compareNodeNames(curVFromNodeChild, curToNodeChild) === true;

                        if (isCompatible === true) {
                            // We found compatible DOM elements so transform
                            // the current "from" node to match the current
                            // target DOM node.
                            morphEl(curFromNodeChild, curVFromNodeChild, curToNodeChild, component, curToNodeKey);
                        }
                    } else if (curFromNodeType === TEXT_NODE || curFromNodeType === COMMENT_NODE) {
                        // Both nodes being compared are Text or Comment nodes
                        isCompatible = true;
                        // Simply update nodeValue on the original node to
                        // change the text value

                        var content = curFromNodeChild.nodeValue;
                        if (content == curToNodeChild.ax_) {
                            if (/^F\^/.test(content)) {
                                var closingContent = content.replace(/^F\^/, "F/");
                                while (curFromNodeChild = curFromNodeChild.nextSibling) {
                                    if (curFromNodeChild.nodeValue === closingContent) {
                                        break;
                                    }
                                }
                                while (curToNodeChild = curToNodeChild.as_) {
                                    if (curToNodeChild.ax_ === closingContent) {
                                        break;
                                    }
                                }
                                curToNodeChild = curToNodeChild.as_;
                                curFromNodeChild = curFromNodeChild === endNode ? null : curFromNodeChild.nextSibling;
                                continue outer;
                            }
                        } else {
                            curFromNodeChild.nodeValue = curToNodeChild.ax_;
                        }
                    }
                }

                if (isCompatible === true) {
                    // Advance both the "to" child and the "from" child since we found a match
                    curToNodeChild = toNextSibling;
                    curFromNodeChild = fromNextSibling;
                    continue outer;
                }

                if (curFromNodeKey) {
                    if (globalComponentsContext._x_[curFromNodeKey] === undefined) {
                        detachNode(curFromNodeChild, parentFromNode, componentForNode);
                    }
                } else {
                    detachNode(curFromNodeChild, parentFromNode, componentForNode);
                }

                curFromNodeChild = fromNextSibling;
            } // END: while (curFromNodeChild)

            // If we got this far then we did not find a candidate match for
            // our "to node" and we exhausted all of the children "from"
            // nodes. Therefore, we will just append the current "to" node
            // to the end
            insertVirtualNodeBefore(curToNodeChild, curToNodeKey, curFromNodeChild, parentFromNode, componentForNode);

            curToNodeChild = toNextSibling;
            curFromNodeChild = fromNextSibling;
        }

        // We have processed all of the "to nodes". If curFromNodeChild is
        // non-null then we still have some from nodes left over that need
        // to be removed
        while (curFromNodeChild && (endNode === null || curFromNodeChild !== endNode)) {
            fromNextSibling = curFromNodeChild.nextSibling;

            if (fromComponent = curFromNodeChild.B_) {
                if (globalComponentsContext._z_[fromComponent.id]) {
                    // Skip over this component since it was rendered in the target VDOM
                    // and will be moved into place later
                    curFromNodeChild = fromComponent.i_.nextSibling;
                    continue;
                }
            }

            curVFromNodeChild = curFromNodeChild.ai_;

            // For transcluded content, we need to check if the element belongs to a different component
            // context than the current component and ensure it gets removed from its key index.
            fromComponent = curVFromNodeChild && curVFromNodeChild._a_ || component;

            detachNode(curFromNodeChild, parentFromNode, fromComponent);

            curFromNodeChild = fromNextSibling;
        }
    }

    function morphEl(fromEl, vFromEl, toEl, component, toElKey) {
        var nodeName = toEl.ap_;

        if (isRerenderInBrowser === true && toElKey) {
            component.w_[toElKey] = fromEl;
        }

        var constId = toEl.ay_;
        if (constId !== undefined && vFromEl.ay_ === constId) {
            return;
        }

        morphAttrs(fromEl, vFromEl, toEl);

        if (toElKey && globalComponentsContext._y_[toElKey] === true) {
            // Don't morph the children since they are preserved
            return;
        }

        if (nodeName !== "TEXTAREA") {
            morphChildren(fromEl, fromEl.firstChild, null, toEl, component);
        }

        var specialElHandler = specialElHandlers[nodeName];
        if (specialElHandler !== undefined) {
            specialElHandler(fromEl, toEl);
        }
    } // END: morphEl(...)

    morphChildren(parentNode, startNode, endNode, toNode);

    detachedNodes.forEach(function (node) {
        var detachedFromComponent = node.at_;

        if (detachedFromComponent !== undefined) {
            node.at_ = undefined;

            var componentToDestroy = node.B_;
            if (componentToDestroy) {
                componentToDestroy.destroy();
            } else if (node.parentNode) {
                destroyNodeRecursive(node, detachedFromComponent !== true && detachedFromComponent);

                if (eventDelegation.A_(node) != false) {
                    node.parentNode.removeChild(node);
                }
            }
        }
    });
}

module.exports = morphdom;