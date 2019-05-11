/**
 * Dependencies.
 */

var assert = require('assert');
var remoting = require('strong-remoting');
var jutil = require('loopback-datasource-juggler/lib/jutil');
var RelationMixin = require('./relations');

/**
 * Export the RemoteConnector class.
 */

module.exports = RemoteConnector;

/**
 * Create an instance of the connector with the given `settings`.
 */

function RemoteConnector(settings) {
  assert(typeof settings ===
    'object',
    'cannot initiaze RemoteConnector without a settings object');
  this.client = settings.client;
  this.adapter = settings.adapter || 'rest';
  this.protocol = settings.protocol || 'http'
  this.root = settings.root || '';
  this.host = settings.host || 'localhost';
  this.port = settings.port || 3000;
  this.remotes = remoting.create();
  this.name = 'remote-connector';

  if (settings.url) {
    this.url = settings.url;
  } else {
    this.url = this.protocol + '://' + this.host + ':' + this.port + this.root;
  }

  // handle mixins in the define() method
  var DAO = this.DataAccessObject = function() {
  };
}

RemoteConnector.prototype.connect = function() {
  this.remotes.connect(this.url, this.adapter);
};

RemoteConnector.initialize = function(dataSource, callback) {
  var connector = dataSource.connector =
    new RemoteConnector(dataSource.settings);
  connector.connect();
  process.nextTick(callback);
};

RemoteConnector.prototype.define = function(definition) {
  var Model = definition.model;
  var remotes = this.remotes;

  assert(Model.sharedClass,
      'cannot attach ' +
      Model.modelName +
      ' to a remote connector without a Model.sharedClass');

  jutil.mixin(Model, RelationMixin);
  remotes.addClass(Model.sharedClass);
  this.resolve(Model);
};

RemoteConnector.prototype.resolve = function(Model) {
  var remotes = this.remotes;

  Model.sharedClass.methods().forEach(function(remoteMethod) {
    if (remoteMethod.name !== 'Change' && remoteMethod.name !== 'Checkpoint') {
      createProxyMethod(Model, remotes, remoteMethod);
    }
  });
};

function createProxyMethod(Model, remotes, remoteMethod) {
  var scope = remoteMethod.isStatic ? Model : Model.prototype;
  var original = scope[remoteMethod.name];

  scope[remoteMethod.name] = function remoteMethodProxy() {
    var args = Array.prototype.slice.call(arguments);
    var lastArgIsFunc = typeof args[args.length - 1] === 'function';
    var callback;
    if (lastArgIsFunc) {
      callback = args.pop();
    }

    if (remoteMethod.isStatic) {
      return remotes.invoke(remoteMethod.stringName, args, callback);
    }

    var ctorArgs = [this.id];
    return remotes.invoke(remoteMethod.stringName, ctorArgs, args, callback);
  }
}

function noop() {
}
