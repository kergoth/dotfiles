/* jshint newcap:false */
var VNode = require("./VNode");
var inherit = require("raptor-util/inherit");
var NS_XLINK = "http://www.w3.org/1999/xlink";
var ATTR_XLINK_HREF = "xlink:href";
var xmlnsRegExp = /^xmlns(:|$)/;

var toString = String;

var FLAG_IS_SVG = 1;
var FLAG_IS_TEXTAREA = 2;
var FLAG_SIMPLE_ATTRS = 4;
// var FLAG_PRESERVE = 8;
var FLAG_CUSTOM_ELEMENT = 16;

var defineProperty = Object.defineProperty;

var ATTR_HREF = "href";
var EMPTY_OBJECT = Object.freeze({});

function convertAttrValue(type, value) {
    if (value === true) {
        return "";
    } else if (type == "object") {
        return JSON.stringify(value);
    } else {
        return toString(value);
    }
}

function setAttribute(el, namespaceURI, name, value) {
    if (namespaceURI === null) {
        el.setAttribute(name, value);
    } else {
        el.setAttributeNS(namespaceURI, name, value);
    }
}

function removeAttribute(el, namespaceURI, name) {
    if (namespaceURI === null) {
        el.removeAttribute(name);
    } else {
        el.removeAttributeNS(namespaceURI, name);
    }
}

function VElementClone(other) {
    this.bl_ = other.bl_;
    this.bi_ = null;
    this.bj_ = null;

    this.aw_ = other.aw_;
    this.bm_ = other.bm_;
    this.aj_ = other.aj_;
    this.bn_ = other.bn_;
    this.ap_ = other.ap_;
    this._e_ = other._e_;
    this.bo_ = other.bo_;
    this.ay_ = other.ay_;
    this.bp_ = other.bp_;
}

function VElement(tagName, attrs, key, component, childCount, flags, props) {
    this.bh_(childCount);

    var constId;
    var namespaceURI;
    var isTextArea;

    if (props) {
        constId = props.i;
    }

    if (this._e_ = flags || 0) {
        if (flags & FLAG_IS_SVG) {
            namespaceURI = "http://www.w3.org/2000/svg";
        }
        if (flags & FLAG_IS_TEXTAREA) {
            isTextArea = true;
        }
    }

    this.aw_ = key;
    this._a_ = component;
    this.bm_ = attrs || EMPTY_OBJECT;
    this.aj_ = props || EMPTY_OBJECT;
    this.bn_ = namespaceURI;
    this.ap_ = tagName;
    this.bo_ = null;
    this.ay_ = constId;
    this.bp_ = isTextArea;
}

VElement.prototype = {
    ar_: 1,

    ba_: function () {
        return new VElementClone(this);
    },

    /**
     * Shorthand method for creating and appending an HTML element
     *
     * @param  {String} tagName    The tag name (e.g. "div")
     * @param  {int|null} attrCount  The number of attributes (or `null` if not known)
     * @param  {int|null} childCount The number of child nodes (or `null` if not known)
     */
    e: function (tagName, attrs, key, component, childCount, flags, props) {
        var child = this.aY_(new VElement(tagName, attrs, key, component, childCount, flags, props));

        if (childCount === 0) {
            return this.bq_();
        } else {
            return child;
        }
    },

    /**
     * Shorthand method for creating and appending an HTML element with a dynamic namespace
     *
     * @param  {String} tagName    The tag name (e.g. "div")
     * @param  {int|null} attrCount  The number of attributes (or `null` if not known)
     * @param  {int|null} childCount The number of child nodes (or `null` if not known)
     */
    ed: function (tagName, attrs, key, component, childCount, flags, props) {
        var child = this.aY_(VElement.b__(tagName, attrs, key, component, childCount, flags, props));

        if (childCount === 0) {
            return this.bq_();
        } else {
            return child;
        }
    },

    /**
     * Shorthand method for creating and appending a static node. The provided node is automatically cloned
     * using a shallow clone since it will be mutated as a result of setting `nextSibling` and `parentNode`.
     *
     * @param  {String} value The value for the new Comment node
     */
    n: function (node, component) {
        node = node.ba_();
        node._a_ = component;
        this.aY_(node);
        return this.bq_();
    },

    aq_: function (doc) {
        var namespaceURI = this.bn_;
        var tagName = this.ap_;

        var attributes = this.bm_;
        var flags = this._e_;

        var el = namespaceURI !== undefined ? doc.createElementNS(namespaceURI, tagName) : doc.createElement(tagName);

        if (flags & FLAG_CUSTOM_ELEMENT) {
            Object.assign(el, attributes);
        } else {
            for (var attrName in attributes) {
                var attrValue = attributes[attrName];

                if (attrValue !== false && attrValue != null) {
                    var type = typeof attrValue;

                    if (type !== "string") {
                        // Special attributes aren't copied to the real DOM. They are only
                        // kept in the virtual attributes map
                        attrValue = convertAttrValue(type, attrValue);
                    }

                    if (attrName == ATTR_XLINK_HREF) {
                        setAttribute(el, NS_XLINK, ATTR_HREF, attrValue);
                    } else {
                        el.setAttribute(attrName, attrValue);
                    }
                }
            }

            if (flags & FLAG_IS_TEXTAREA) {
                el.value = this.az_;
            }
        }

        el.ai_ = this;

        return el;
    },

    aA_: function (name) {
        // We don't care about the namespaces since the there
        // is no chance that attributes with the same name will have
        // different namespaces
        var value = this.bm_[name];
        return value != null && value !== false;
    }
};

inherit(VElement, VNode);

var proto = VElementClone.prototype = VElement.prototype;

["checked", "selected", "disabled"].forEach(function (name) {
    defineProperty(proto, name, {
        get: function () {
            var value = this.bm_[name];
            return value !== false && value != null;
        }
    });
});

defineProperty(proto, "az_", {
    get: function () {
        var value = this.bo_;
        if (value == null) {
            value = this.bm_.value;
        }
        return value != null ? toString(value) : "";
    }
});

VElement.b__ = function (tagName, attrs, key, component, childCount, flags, props) {
    var namespace = attrs && attrs.xmlns;
    tagName = namespace ? tagName : tagName.toUpperCase();
    var element = new VElement(tagName, attrs, key, component, childCount, flags, props);
    element.bn_ = namespace;
    return element;
};

VElement.br_ = function (attrs) {
    // By default this static method is a no-op, but if there are any
    // compiled components that have "no-update" attributes then
    // `preserve-attrs.js` will be imported and this method will be replaced
    // with a method that actually does something
    return attrs;
};

function virtualizeElement(node, virtualizeChildNodes) {
    var attributes = node.attributes;
    var attrCount = attributes.length;

    var attrs;

    if (attrCount) {
        attrs = {};
        for (var i = 0; i < attrCount; i++) {
            var attr = attributes[i];
            var attrName = attr.name;
            if (!xmlnsRegExp.test(attrName) && attrName !== "data-marko") {
                var attrNamespaceURI = attr.namespaceURI;
                if (attrNamespaceURI === NS_XLINK) {
                    attrs[ATTR_XLINK_HREF] = attr.value;
                } else {
                    attrs[attrName] = attr.value;
                }
            }
        }
    }

    var flags = 0;

    var tagName = node.nodeName;
    if (tagName === "TEXTAREA") {
        flags |= FLAG_IS_TEXTAREA;
    }

    var vdomEl = new VElement(tagName, attrs, null /*key*/
    , null /*component*/
    , 0 /*child count*/
    , flags, null /*props*/
    );
    if (node.namespaceURI !== "http://www.w3.org/1999/xhtml") {
        vdomEl.bn_ = node.namespaceURI;
    }

    if (vdomEl.bp_) {
        vdomEl.bo_ = node.value;
    } else {
        if (virtualizeChildNodes) {
            virtualizeChildNodes(node, vdomEl);
        }
    }

    return vdomEl;
}

VElement.an_ = virtualizeElement;

VElement.ao_ = function (fromEl, vFromEl, toEl) {
    var removePreservedAttributes = VElement.br_;

    var fromFlags = vFromEl._e_;
    var toFlags = toEl._e_;

    fromEl.ai_ = toEl;

    var attrs = toEl.bm_;
    var props = toEl.aj_;

    if (toFlags & FLAG_CUSTOM_ELEMENT) {
        return Object.assign(fromEl, attrs);
    }

    var attrName;

    // We use expando properties to associate the previous HTML
    // attributes provided as part of the VDOM node with the
    // real VElement DOM node. When diffing attributes,
    // we only use our internal representation of the attributes.
    // When diffing for the first time it's possible that the
    // real VElement node will not have the expando property
    // so we build the attribute map from the expando property

    var oldAttrs = vFromEl.bm_;

    if (oldAttrs) {
        if (oldAttrs === attrs) {
            // For constant attributes the same object will be provided
            // every render and we can use that to our advantage to
            // not waste time diffing a constant, immutable attribute
            // map.
            return;
        } else {
            oldAttrs = removePreservedAttributes(oldAttrs, props);
        }
    }

    var attrValue;

    if (toFlags & FLAG_SIMPLE_ATTRS && fromFlags & FLAG_SIMPLE_ATTRS) {
        if (oldAttrs["class"] !== (attrValue = attrs["class"])) {
            fromEl.className = attrValue;
        }
        if (oldAttrs.id !== (attrValue = attrs.id)) {
            fromEl.id = attrValue;
        }
        if (oldAttrs.style !== (attrValue = attrs.style)) {
            fromEl.style.cssText = attrValue;
        }
        return;
    }

    // In some cases we only want to set an attribute value for the first
    // render or we don't want certain attributes to be touched. To support
    // that use case we delete out all of the preserved attributes
    // so it's as if they never existed.
    attrs = removePreservedAttributes(attrs, props, true);

    var namespaceURI;

    // Loop over all of the attributes in the attribute map and compare
    // them to the value in the old map. However, if the value is
    // null/undefined/false then we want to remove the attribute
    for (attrName in attrs) {
        attrValue = attrs[attrName];
        namespaceURI = null;

        if (attrName === ATTR_XLINK_HREF) {
            namespaceURI = NS_XLINK;
            attrName = ATTR_HREF;
        }

        if (attrValue == null || attrValue === false) {
            removeAttribute(fromEl, namespaceURI, attrName);
        } else if (oldAttrs[attrName] !== attrValue) {
            var type = typeof attrValue;

            if (type !== "string") {
                attrValue = convertAttrValue(type, attrValue);
            }

            setAttribute(fromEl, namespaceURI, attrName, attrValue);
        }
    }

    // If there are any old attributes that are not in the new set of attributes
    // then we need to remove those attributes from the target node
    //
    // NOTE: We can skip this if the the element is keyed because if the element
    //       is keyed then we know we already processed all of the attributes for
    //       both the target and original element since target VElement nodes will
    //       have all attributes declared. However, we can only skip if the node
    //       was not a virtualized node (i.e., a node that was not rendered by a
    //       Marko template, but rather a node that was created from an HTML
    //       string or a real DOM node).
    if (toEl.aw_ === null) {
        for (attrName in oldAttrs) {
            if (!(attrName in attrs)) {
                if (attrName === ATTR_XLINK_HREF) {
                    fromEl.removeAttributeNS(ATTR_XLINK_HREF, ATTR_HREF);
                } else {
                    fromEl.removeAttribute(attrName);
                }
            }
        }
    }
};

module.exports = VElement;