"use strict";

module.exports = {
    render: function (input, out) {
        var cacheKey = input.cacheKey;
        if (!cacheKey) {
            throw new Error("cache-key is required for <cached-fragment>");
        }

        var cacheManager = input.cacheManager;

        var cache = cacheManager.getCache(input.cacheName || "marko/cached-fragment");

        var asyncOut = out.beginAsync();

        cache.get(cacheKey, {
            builder: function (callback) {
                var nestedOut = out.createOut();

                if (input.renderBody) {
                    input.renderBody(nestedOut);
                }

                nestedOut.on("error", callback).on("finish", function (result) {
                    callback(null, result.getOutput());
                });

                nestedOut.end();
            }
        }, function (err, result) {
            if (err) {
                return asyncOut.error(err);
            }

            if (result.ba_) {
                var curChild = result.au_;
                while (curChild) {
                    asyncOut.node(curChild.ba_());
                    curChild = curChild.as_;
                }
                asyncOut.end();
            } else {
                asyncOut.end(result);
            }
        });
    }
};