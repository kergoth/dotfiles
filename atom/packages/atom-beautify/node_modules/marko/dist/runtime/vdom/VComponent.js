var VNode = require("./VNode");
var inherit = require("raptor-util/inherit");

function VComponent(component, preserve) {
    this.bh_(null /* childCount */);
    this._a_ = component;
    this.av_ = preserve;
}

VComponent.prototype = {
    ar_: 2
};

inherit(VComponent, VNode);

module.exports = VComponent;