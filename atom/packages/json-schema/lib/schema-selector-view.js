var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var atom_space_pen_views_1 = require('atom-space-pen-views');
var rx_1 = require("rx");
var _ = require('lodash');
var React = require('react');
var omni_1 = require("./omni");
var schema_provider_1 = require("./schema-provider");
var $ = require('jquery');
var SelectorComponent = (function (_super) {
    __extends(SelectorComponent, _super);
    function SelectorComponent(props, context) {
        _super.call(this, props, context);
        this.disposable = new rx_1.CompositeDisposable();
        this.state = { schemas: [], activeSchema: {} };
    }
    SelectorComponent.prototype.componentWillMount = function () {
        this.disposable = new rx_1.CompositeDisposable();
    };
    SelectorComponent.prototype.componentDidMount = function () {
        var _this = this;
        this.disposable.add(schema_provider_1.schemaProvider.schemas.subscribe(function (s) { return _this.setState({ schemas: s, activeSchema: s[0] }); }));
    };
    SelectorComponent.prototype.componentWillUnmount = function () {
        this.disposable.dispose();
    };
    SelectorComponent.prototype.render = function () {
        var _this = this;
        return React.DOM.a({
            href: '#',
            onClick: function (e) {
                if (e.target !== e.currentTarget)
                    return;
                var view = new FrameworkSelectorSelectListView(atom.workspace.getActiveTextEditor(), {
                    attachTo: '.schema-selector',
                    alignLeft: _this.props.alignLeft,
                    items: _this.state.schemas,
                    save: function (framework) {
                        omni_1.omni.activeSchema = framework;
                        view.hide();
                    }
                });
                view.appendTo(atom.views.getView(atom.workspace));
                view.setItems();
                view.show();
            }
        }, this.state.activeSchema.name);
    };
    return SelectorComponent;
})(React.Component);
exports.SelectorComponent = SelectorComponent;
var FrameworkSelectorSelectListView = (function (_super) {
    __extends(FrameworkSelectorSelectListView, _super);
    function FrameworkSelectorSelectListView(editor, options) {
        _super.call(this);
        this.editor = editor;
        this.options = options;
        this.$.addClass('code-actions-overlay');
        this.filterEditorView.model.placeholderText = 'Filter list';
    }
    Object.defineProperty(FrameworkSelectorSelectListView.prototype, "$", {
        get: function () {
            return this;
        },
        enumerable: true,
        configurable: true
    });
    FrameworkSelectorSelectListView.prototype.setItems = function () {
        atom_space_pen_views_1.SelectListView.prototype.setItems.call(this, this.options.items);
    };
    FrameworkSelectorSelectListView.prototype.confirmed = function (item) {
        this.cancel(); //will close the view
        this.options.save(item);
        return null;
    };
    FrameworkSelectorSelectListView.prototype.show = function () {
        var _this = this;
        this.storeFocusedElement();
        setTimeout(function () { return _this.focusFilterEditor(); }, 100);
        var width = 320;
        var node = this[0];
        var attachTo = $(document.querySelectorAll(this.options.attachTo));
        var offset = attachTo.offset();
        if (offset) {
            if (this.options.alignLeft) {
                $(node).css({
                    position: 'fixed',
                    top: offset.top - node.clientHeight - 18,
                    left: offset.left,
                    width: width
                });
            }
            else {
                $(node).css({
                    position: 'fixed',
                    top: offset.top - node.clientHeight - 18,
                    left: offset.left - width + attachTo[0].clientWidth,
                    width: width
                });
            }
        }
    };
    FrameworkSelectorSelectListView.prototype.hide = function () {
        this.restoreFocus();
        this.remove();
    };
    FrameworkSelectorSelectListView.prototype.cancelled = function () {
        this.hide();
    };
    FrameworkSelectorSelectListView.prototype.getFilterKey = function () { return 'Name'; };
    FrameworkSelectorSelectListView.prototype.viewForItem = function (item) {
        if (!item) {
        }
        return atom_space_pen_views_1.$$(function () {
            var _this = this;
            return this.li({
                "class": 'event',
                'data-event-name': item.name
            }, function () {
                return _this.span(_.trunc(item.name + " - " + item.description, 50), {
                    title: item.name + " - " + item.description
                });
            });
        });
    };
    return FrameworkSelectorSelectListView;
})(atom_space_pen_views_1.SelectListView);
