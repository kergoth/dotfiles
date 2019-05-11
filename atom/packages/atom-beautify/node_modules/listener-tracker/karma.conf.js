module.exports = function(config) {
    config.set({
        frameworks: ['lasso', 'mocha', 'chai'],

        files: [
            './test/browser/*.js'
        ],

        lasso: {
            plugins: [],
            minify: false,
            bundlingEnabled: false,
            resolveCssUrls: true,
            cacheProfile: 'development',
            tempdir: './.test'
        },

        reporters: ['mocha'],

        plugins: [
            'karma-chai',
            'karma-lasso',
            'karma-mocha',
            'karma-mocha-reporter',
            'karma-phantomjs-launcher'
        ],

        browsers: [
            'PhantomJS'
        ],

        singleRun: true
    });
};