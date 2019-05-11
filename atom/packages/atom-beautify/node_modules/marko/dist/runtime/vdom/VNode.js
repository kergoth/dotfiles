/* jshint newcap:false */
function VNode() {}

VNode.prototype = {
    bh_: function (finalChildCount) {
        this.bs_ = finalChildCount;
        this.bt_ = 0;
        this.bl_ = null;
        this.bu_ = null;
        this.bi_ = null;
        this.bj_ = null;
    },

    _a_: null,

    get au_() {
        var firstChild = this.bl_;

        if (firstChild && firstChild.bk_) {
            var nestedFirstChild = firstChild.au_;
            // The first child is a DocumentFragment node.
            // If the DocumentFragment node has a first child then we will return that.
            // Otherwise, the DocumentFragment node is not *really* the first child and
            // we need to skip to its next sibling
            return nestedFirstChild || firstChild.as_;
        }

        return firstChild;
    },

    get as_() {
        var nextSibling = this.bj_;

        if (nextSibling) {
            if (nextSibling.bk_) {
                var firstChild = nextSibling.au_;
                return firstChild || nextSibling.as_;
            }
        } else {
            var parentNode = this.bi_;
            if (parentNode && parentNode.bk_) {
                return parentNode.as_;
            }
        }

        return nextSibling;
    },

    aY_: function (child) {
        this.bt_++;

        if (this.bp_ === true) {
            if (child.bv_) {
                var childValue = child.ax_;
                this.bo_ = (this.bo_ || "") + childValue;
            } else {
                throw TypeError();
            }
        } else {
            var lastChild = this.bu_;

            child.bi_ = this;

            if (lastChild) {
                lastChild.bj_ = child;
            } else {
                this.bl_ = child;
            }

            this.bu_ = child;
        }

        return child;
    },

    bq_: function finishChild() {
        if (this.bt_ === this.bs_ && this.bi_) {
            return this.bi_.bq_();
        } else {
            return this;
        }
    }

    // ,toJSON: function() {
    //     var clone = Object.assign({
    //         nodeType: this.nodeType
    //     }, this);
    //
    //     for (var k in clone) {
    //         if (k.startsWith('_')) {
    //             delete clone[k];
    //         }
    //     }
    //     delete clone._nextSibling;
    //     delete clone._lastChild;
    //     delete clone.parentNode;
    //     return clone;
    // }
};

module.exports = VNode;