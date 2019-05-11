module.exports = function defineWidget(def, renderer) {
    if (def.y_) {
        return def;
    }

    if (renderer) {
        return {
            y_: true,
            renderer: renderer,
            render: renderer.render,
            renderSync: renderer.renderSync,
            template: renderer.template
        };
    } else {
        return { y_: true };
    }
};