"use strict";

module.exports = function endComponent(out, componentDef) {
    if (componentDef._d_) {
        out.w("<!--M/" + componentDef.id + "-->");
    }
};