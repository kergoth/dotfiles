var ComponentDef = require("./ComponentDef");

module.exports = function beginComponent(componentsContext, component) {
    var componentId = component.id;

    var globalContext = componentsContext.P_;
    var componentDef = componentsContext._p_ = new ComponentDef(component, componentId, globalContext);
    globalContext._z_[componentId] = true;
    componentsContext._r_.push(componentDef);

    var out = componentsContext._s_;
    out.bc(component);
    return componentDef;
};