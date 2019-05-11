var VNode = require("./VNode");
var inherit = require("raptor-util/inherit");
var extend = require("raptor-util/extend");

function VDocumentFragmentClone(other) {
    extend(this, other);
    this.bi_ = null;
    this.bj_ = null;
}

function VDocumentFragment(out) {
    this.bh_(null /* childCount */);
    this._s_ = out;
}

VDocumentFragment.prototype = {
    ar_: 11,

    bk_: true,

    ba_: function () {
        return new VDocumentFragmentClone(this);
    },

    aq_: function (doc) {
        return doc.createDocumentFragment();
    }
};

inherit(VDocumentFragment, VNode);

VDocumentFragmentClone.prototype = VDocumentFragment.prototype;

module.exports = VDocumentFragment;