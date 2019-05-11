var componentsUtil = require("./util");
var initComponents = require("./init-components");
var registry = require("./registry");

require("./ComponentsContext")._u_ = initComponents._u_;

exports.getComponentForEl = componentsUtil._N_;
exports.init = window.$initComponents = initComponents._O_;

exports.register = function (id, component) {
    registry._M_(id, function () {
        return component;
    });
};