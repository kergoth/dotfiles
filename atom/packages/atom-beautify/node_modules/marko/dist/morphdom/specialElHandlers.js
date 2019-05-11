function syncBooleanAttrProp(fromEl, toEl, name) {
    if (fromEl[name] !== toEl[name]) {
        fromEl[name] = toEl[name];
        if (fromEl[name]) {
            fromEl.setAttribute(name, "");
        } else {
            fromEl.removeAttribute(name, "");
        }
    }
}

// We use a JavaScript class to benefit from fast property lookup
function SpecialElHandlers() {}
SpecialElHandlers.prototype = {
    /**
     * Needed for IE. Apparently IE doesn't think that "selected" is an
     * attribute when reading over the attributes using selectEl.attributes
     */
    OPTION: function (fromEl, toEl) {
        syncBooleanAttrProp(fromEl, toEl, "selected");
    },
    /**
     * The "value" attribute is special for the <input> element since it sets
     * the initial value. Changing the "value" attribute without changing the
     * "value" property will have no effect since it is only used to the set the
     * initial value.  Similar for the "checked" attribute, and "disabled".
     */
    INPUT: function (fromEl, toEl) {
        syncBooleanAttrProp(fromEl, toEl, "checked");
        syncBooleanAttrProp(fromEl, toEl, "disabled");

        if (fromEl.value != toEl.az_) {
            fromEl.value = toEl.az_;
        }

        if (!toEl.aA_("value")) {
            fromEl.removeAttribute("value");
        }
    },

    TEXTAREA: function (fromEl, toEl) {
        var newValue = toEl.az_;
        if (fromEl.value != newValue) {
            fromEl.value = newValue;
        }

        var firstChild = fromEl.firstChild;
        if (firstChild) {
            // Needed for IE. Apparently IE sets the placeholder as the
            // node value and vise versa. This ignores an empty update.
            var oldValue = firstChild.nodeValue;

            if (oldValue == newValue || !newValue && oldValue == fromEl.placeholder) {
                return;
            }

            firstChild.nodeValue = newValue;
        }
    },
    SELECT: function (fromEl, toEl) {
        if (!toEl.aA_("multiple")) {
            var i = -1;
            var curChild = toEl.au_;
            while (curChild) {
                if (curChild.ap_ == "OPTION") {
                    i++;
                    if (curChild.aA_("selected")) {
                        break;
                    }
                }
                curChild = curChild.as_;
            }

            fromEl.selectedIndex = i;
        }
    }
};

module.exports = new SpecialElHandlers();