var _ = require("lodash");
var rx_1 = require("rx");
var fetch = require('node-fetch');
function search(text) {
    var $get = fetch("https://bower.herokuapp.com/packages/search/" + text);
    return rx_1.Observable
        .fromPromise($get.then(function (res) { return res.json(); }))
        .flatMap(rx_1.Observable.fromArray);
}
function searchPackage(text, name) {
    var $get = fetch("https://bower.herokuapp.com/packages/" + name);
    var toJson = function (res) { return res.json(); };
    var getReleases = function (res) {
        if (!_.contains(res.url, 'github')) {
            return;
        }
        var url = res.url.replace('.git', '/tags').replace('git://github.com/', 'https://api.github.com/repos/');
        return fetch(url);
    };
    var getTags = function (rel) { return rel.name.replace('v', ''); };
    return rx_1.Observable
        .fromPromise($get.then(toJson).then(getReleases).then(function (res) { return res.json(); }))
        .flatMap(rx_1.Observable.fromArray)
        .map(getTags);
}
function makeSuggestion(item) {
    var type = 'package';
    return {
        _search: item.name,
        snippet: item.name,
        type: type,
        displayText: item.name,
        className: 'autocomplete-json-schema'
    };
}
var packageName = {
    getSuggestions: function (options) {
        return search(options.replacementPrefix)
            .filter(function (r) { return _.contains(r.name, options.replacementPrefix); })
            .map(makeSuggestion)
            .toArray()
            .toPromise();
    },
    fileMatchs: ['bower.json'],
    pathMatch: function (path) { return path === "dependencies"; },
    dispose: function () { }
};
var packageVersion = {
    getSuggestions: function (options) {
        var name = options.path.split('/');
        return searchPackage(options.replacementPrefix, name[name.length - 1])
            .map(function (tag) { return ({ name: "^" + tag }); })
            .map(makeSuggestion)
            .toArray()
            .toPromise();
    },
    fileMatchs: ['bower.json'],
    pathMatch: function (path) { return _.startsWith(path, "dependencies/"); },
    dispose: function () { }
};
var providers = [packageName, packageVersion];
module.exports = providers;
