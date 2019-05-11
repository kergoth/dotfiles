"use strict";

class ServerComponent {
    constructor(id, input, out, typeName, customEvents, scope) {
        this.id = id;
        this.m_ = customEvents;
        this.d_ = scope;
        this._C_ = undefined;
        this.o_ = undefined;
        this.g_ = undefined;
        this.typeName = typeName;
        this.l_ = undefined; // Used to keep track of bubbling DOM events for components rendered on the server
        this._D_ = 0;

        if (this.onCreate !== undefined) {
            this.onCreate(input, out);
        }

        if (this.onInput !== undefined) {
            var updatedInput = this.onInput(input, out) || input;

            if (this.o_ === undefined) {
                this.o_ = updatedInput;
            }

            this._C_ = updatedInput;
        } else {
            this.o_ = this._C_ = input;
        }

        if (this.onRender !== undefined) {
            this.onRender(out);
        }
    }

    set input(newInput) {
        this.o_ = newInput;
    }

    get input() {
        return this.o_;
    }

    set state(newState) {
        this.g_ = newState;
    }

    get state() {
        return this.g_;
    }

    get U_() {
        return this.g_;
    }

    elId(scopedId, index) {
        var id = this.id;

        var elId = scopedId != null ? id + "-" + scopedId : id;

        if (index != null) {
            elId += "[" + index + "]";
        }

        return elId;
    }
}

ServerComponent.prototype.getElId = ServerComponent.prototype.elId;

module.exports = ServerComponent;