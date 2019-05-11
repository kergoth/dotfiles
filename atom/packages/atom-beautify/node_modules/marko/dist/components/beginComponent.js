"use strict";

const ComponentDef = require("./ComponentDef");

var FLAG_WILL_RERENDER_IN_BROWSER = 1;
// var FLAG_HAS_BODY_EL = 2;
// var FLAG_HAS_HEAD_EL = 4;

module.exports = function beginComponent(componentsContext, component, isSplitComponent, parentComponentDef, isImplicitComponent) {
    var globalContext = componentsContext.P_;

    var componentId = component.id;

    var componentDef = componentsContext._p_ = new ComponentDef(component, componentId, globalContext);

    // On the server
    if (parentComponentDef && parentComponentDef._e_ & FLAG_WILL_RERENDER_IN_BROWSER) {
        componentDef._e_ |= FLAG_WILL_RERENDER_IN_BROWSER;
        return componentDef;
    }

    if (isImplicitComponent === true) {
        // We don't mount implicit components rendered on the server
        // unless the implicit component is nested within a UI component
        // that will re-render in the browser
        return componentDef;
    }

    componentsContext._r_.push(componentDef);

    let out = componentsContext._s_;

    componentDef._d_ = true;

    if (isSplitComponent === false && out.global.noBrowserRerender !== true) {
        componentDef._e_ |= FLAG_WILL_RERENDER_IN_BROWSER;
        out.w("<!--M#" + componentId + "-->");
    } else {
        out.w("<!--M^" + componentId + "-->");
    }

    return componentDef;
};