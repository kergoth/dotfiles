var path = require("path");
var defaultResolveFrom = require("resolve-from");
var env = process.env.NODE_ENV;
var production = !env || env !== "development";

function getRootDeps(template, context) {
    if (production && template._U_) {
        return template._U_;
    }

    attachDepsAndComponentsToTemplate(template, context);

    var deps = template._U_ = Object.keys(template._V_).map(key => template._V_[key]);
    var initModule = getInitModule(template.path, template._r_);

    if (initModule) deps.push(initModule);

    deps.push({
        type: "require",
        path: require.resolve("../../boot"),
        run: true
    });

    // these dependencies should be last
    deps.concat = function () {
        var result = [];
        result = result.concat.apply(result, arguments);
        result.push.apply(result, this);
        return result;
    };

    return deps;
}

function attachDepsAndComponentsToTemplate(target, context) {
    var template;

    if (!target.meta && target.template) {
        template = target.template;
    } else {
        template = target;
    }

    if (typeof template.createOut !== "function") return;
    if (production && target._V_) return;

    var deps = target._V_ = {};
    var components = target._r_ = {};

    if (!template.meta) {
        // eslint-disable-next-line no-console
        console.warn("Metadata not set for template at ", template.path);
        return;
    }

    var meta = template.meta;
    var root = path.dirname(template.path);

    if (meta.deps) {
        meta.deps.forEach(dep => {
            dep = resolveDep(dep, root, context);
            deps[dep.virtualPath || dep.path] = dep;
        });
    }

    if (meta.id && meta.component) {
        var resolveFrom = context && context.resolveFrom || defaultResolveFrom;
        components[meta.id] = {
            id: meta.id,
            path: resolveFrom(root, meta.component)
        };
    }

    if (meta.tags) {
        meta.tags.forEach(tagPath => {
            var resolveFrom = context.resolveFrom || defaultResolveFrom;
            var tag = resolveFrom(root, tagPath);
            var ext = path.extname(tag);
            var req = context.require || require;

            try {
                tag = req.resolve(tag.slice(0, 0 - ext.length) + ".js");
            } catch (e) {
                /* ignore error */
            }

            tag = req(tag);

            attachDepsAndComponentsToTemplate(tag, context);

            if (tag._V_) Object.assign(deps, tag._V_);
            if (tag._r_) Object.assign(components, tag._r_);
        });
    }
}

function getInitModule(path, components) {
    var module = null;

    if (components) {
        components = Object.keys(components).map(key => components[key]);

        if (components.length) {
            var virtualPath = path + ".init.js";
            var registrations = components.map(component => `components.register('${component.id}', require('${component.path}'));`);
            var code = `
                var components = require('marko/components');
                ${registrations.join("\n")}
            `;

            module = {
                type: "require",
                run: true,
                virtualModule: {
                    path: virtualPath,
                    read: function (_, callback) {
                        // TODO: Check if read can just return string in lasso 2
                        if (callback) {
                            callback(null, code);
                        } else {
                            return code;
                        }
                    }
                }
            };
        }
    }

    return module;
}

function resolveDep(dep, root, context) {
    if (typeof dep === "string") {
        dep = parseDependencyString(dep);
    }

    if (dep.path) {
        var resolveFrom = context && context.resolveFrom || defaultResolveFrom;
        dep.path = resolveFrom(root, dep.path);

        if (dep.path && !dep.type) {
            dep.type = dep.path.slice(dep.path.lastIndexOf(".") + 1);
        }
    }

    if (dep.virtualPath) {
        dep.virtualPath = path.resolve(root, dep.virtualPath);
    }

    if (dep.type === "js") {
        dep.type = "require";
        dep.run = true;
    }

    return dep;
}

function parseDependencyString(string) {
    var match = /^(?:([\w-]+)(?::\s*|\s+))?(.*?(?:\.(\w+))?)$/.exec(string);
    return {
        type: match[1] || match[3],
        path: match[2]
    };
}

function patch(Template) {
    Template.prototype.getDependencies = function (context) {
        context = context || {};

        return getRootDeps(this, context);
    };
}

exports.getDeps = getRootDeps;
exports.resolveDep = resolveDep;
exports.patch = patch;