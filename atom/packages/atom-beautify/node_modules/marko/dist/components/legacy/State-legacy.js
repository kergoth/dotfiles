var extend = require("raptor-util/extend");

function ensure(state, propertyName) {
    var proto = state.constructor.prototype;
    if (!(propertyName in proto)) {
        Object.defineProperty(proto, propertyName, {
            get: function () {
                return this.V_[propertyName];
            },
            set: function (value) {
                if (value === undefined) {
                    // Don't store state properties with an undefined or null value
                    delete this.V_[name];
                } else {
                    // Otherwise, store the new value in the component state
                    this.V_[name] = value;
                }
            }
        });
    }
}

function State(component) {
    this._a_ = component;
    this.V_ = {};

    this.t_ = false;
    this.L_ = null;
    this.K_ = null;
    this._E_ = null; // An object that we use to keep tracking of state properties that were forced to be dirty
}

State.prototype = {
    e_: function () {
        var self = this;

        self.t_ = false;
        self.L_ = null;
        self.K_ = null;
        self._E_ = null;
    },

    E_: function (newState) {
        var state = this;
        var key;

        var rawState = this.V_;

        for (key in rawState) {
            if (!(key in newState)) {
                state.G_(key, undefined, false /* ensure:false */
                , false /* forceDirty:false */
                );
            }
        }

        for (key in newState) {
            state.G_(key, newState[key], true /* ensure:true */
            , false /* forceDirty:false */
            );
        }
    },
    G_: function (name, value, shouldEnsure, forceDirty) {
        var rawState = this.V_;

        if (shouldEnsure) {
            ensure(this, name);
        }

        if (forceDirty) {
            var forcedDirtyState = this._E_ || (this._E_ = {});
            forcedDirtyState[name] = true;
        } else if (rawState[name] === value) {
            return;
        }

        if (!this.t_) {
            // This is the first time we are modifying the component state
            // so introduce some properties to do some tracking of
            // changes to the state
            this.t_ = true; // Mark the component state as dirty (i.e. modified)
            this.L_ = rawState;
            this.V_ = rawState = extend({}, rawState);
            this.K_ = {};
            this._a_.F_();
        }

        this.K_[name] = value;

        if (value === undefined) {
            // Don't store state properties with an undefined or null value
            delete rawState[name];
        } else {
            // Otherwise, store the new value in the component state
            rawState[name] = value;
        }
    },
    toJSON: function () {
        return this.V_;
    }
};

module.exports = State;