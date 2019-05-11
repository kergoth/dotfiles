var _ = require("lodash");
var rx_1 = require("rx");
var fetch = require('node-fetch');
var filter = require('fuzzaldrin').filter;
//https://skimdb.npmjs.com/registry/_design/app/_view/browseAll?group_level=1
function search(text) {
    return rx_1.Observable.fromPromise(fetch("https://skimdb.npmjs.com/registry/_design/app/_view/browseAll?group_level=1&limit=100&start_key=%5B%22" + encodeURIComponent(text) + "%22,%7B%7D%5D&end_key=%5B%22" + encodeURIComponent(text) + "z%22,%7B%7D%5D")
        .then(function (res) { return res.json(); }))
        .flatMap(function (z) {
        return rx_1.Observable.from(z.rows);
    });
}
//http://registry.npmjs.org/gulp/latest
function searchPackage(text, name) {
    return rx_1.Observable.fromPromise(fetch("http://registry.npmjs.org/" + name + "/latest")
        .then(function (res) { return res.json(); }));
}
function makeSuggestion(item) {
    var type = 'package';
    return {
        _search: item.key,
        text: item.key,
        snippet: item.key,
        type: type,
        displayText: item.key,
        className: 'autocomplete-json-schema'
    };
}
var packageName = {
    getSuggestions: function (options) {
        if (!options.replacementPrefix)
            return Promise.resolve([]);
        return search(options.replacementPrefix)
            .map(makeSuggestion)
            .toArray()
            .toPromise();
    },
    fileMatchs: ['package.json'],
    pathMatch: function (path) {
        return path === "dependencies" || path === "devDependencies";
    },
    dispose: function () { }
};
var packageVersion = {
    getSuggestions: function (options) {
        var name = options.path.split('/');
        return searchPackage(options.replacementPrefix, name[name.length - 1])
            .map(function (z) { return ({ key: "^" + z.version }); })
            .map(makeSuggestion)
            .toArray()
            .toPromise();
    },
    fileMatchs: ['package.json'],
    pathMatch: function (path) {
        return _.startsWith(path, "dependencies/") || _.startsWith(path, "devDependencies/");
    },
    dispose: function () { }
};
var providers = [packageName, packageVersion];
module.exports = providers;
