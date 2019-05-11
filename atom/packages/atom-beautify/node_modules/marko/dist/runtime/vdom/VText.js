var VNode = require("./VNode");
var inherit = require("raptor-util/inherit");

function VText(value) {
    this.bh_(-1 /* no children */);
    this.ax_ = value;
}

VText.prototype = {
    bv_: true,

    ar_: 3,

    aq_: function (doc) {
        return doc.createTextNode(this.ax_);
    },

    ba_: function () {
        return new VText(this.ax_);
    }
};

inherit(VText, VNode);

module.exports = VText;