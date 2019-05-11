var VNode = require("./VNode");
var inherit = require("raptor-util/inherit");

function VComment(value) {
    this.bh_(-1 /* no children */);
    this.ax_ = value;
}

VComment.prototype = {
    ar_: 8,

    aq_: function (doc) {
        var nodeValue = this.ax_;
        return doc.createComment(nodeValue);
    },

    ba_: function () {
        return new VComment(this.ax_);
    }
};

inherit(VComment, VNode);

module.exports = VComment;