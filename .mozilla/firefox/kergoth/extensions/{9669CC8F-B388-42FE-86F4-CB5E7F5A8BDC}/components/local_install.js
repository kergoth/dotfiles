function AboutAbout() {
}
AboutAbout.prototype = {
  ioService: null,
  classID: Components.ID("{AA5558E1-1E7B-4653-8152-FD98FD3DE455}"),
  contractID: "@mozilla.org/network/protocol/about;1?what=about",
  classDescription: "Local Install about:about implementation component",

  // nsIAboutModule
  newChannel: function(aURI) {
		//if (!this.ioService)
			this.ioService = Components.classes["@mozilla.org/network/io-service;1"]
							.getService(Components.interfaces.nsIIOService);
		return this.ioService.newChannel("chrome://local_install/content/about_about.html", null, aURI);
  },

  // nsISupports
  QueryInterface: function(aIID) {
    if(!aIID.equals(CI.nsISupports) && !aIID.equals(CI.nsIAboutModule))
      throw CR.NS_ERROR_NO_INTERFACE;
    return this;
  }
};

function AboutMyConfig() {
}
AboutMyConfig.prototype = {
  ioService: null,
  classID: Components.ID("{AD9035B1-B10A-4D3E-9C99-87B277A06BA2}"),
  contractID: "@mozilla.org/network/protocol/about;1?what=myconfig",
  classDescription: "Local Install about:myconfig implementation component",

  // nsIAboutModule
  newChannel: function(aURI) {
		//if (!this.ioService)
			this.ioService = Components.classes["@mozilla.org/network/io-service;1"]
							.getService(Components.interfaces.nsIIOService);
		return this.ioService.newChannel("chrome://local_install/content/infolister.xul", null, aURI);
  },

  // nsISupports
  QueryInterface: function(aIID) {
    if(!aIID.equals(CI.nsISupports) && !aIID.equals(CI.nsIAboutModule))
      throw CR.NS_ERROR_NO_INTERFACE;
    return this;
  }
};

function AboutKitchenSink() {
}
AboutKitchenSink.prototype = {
  ioService: null,
  classID: Components.ID("{A5318560-A2A4-4F2B-9D1F-FFE37F6B4558}"),
  contractID: "@mozilla.org/network/protocol/about;1?what=kitchensink",
  classDescription: "Local Install about:kitchensink implementation component",

  // nsIAboutModule
  newChannel: function(aURI) {
		//if (!this.ioService)
			this.ioService = Components.classes["@mozilla.org/network/io-service;1"]
							.getService(Components.interfaces.nsIIOService);
		return this.ioService.newChannel("https://bugzilla.mozilla.org/attachment.cgi?id=114919", null, aURI);
  },

  // nsISupports
  QueryInterface: function(aIID) {
    if(!aIID.equals(CI.nsISupports) && !aIID.equals(CI.nsIAboutModule))
      throw CR.NS_ERROR_NO_INTERFACE;
    return this;
  }
};

// constructors for objects we want to XPCOMify
var objects = [AboutAbout,AboutMyConfig,AboutKitchenSink];

/* Common registration code. */
const CI = Components.interfaces, CC = Components.classes, CR = Components.results;

function FactoryHolder(aObj) {
  this.CID        = aObj.prototype.classID;
  this.contractID = aObj.prototype.contractID;
  this.className  = aObj.prototype.classDescription;
  this.factory = {
    createInstance: function(aOuter, aIID) {
      if(aOuter)
        throw CR.NS_ERROR_NO_AGGREGATION;

      // Load common helpers as soon as any object from this module is
      // instantiated -- most of our code relies on those.
      //requires("chrome://local_install/content/local_install.js");
      return (new this.constructor).QueryInterface(aIID);
    }
  };
  this.factory.constructor = aObj;
}

var gModule = {
  registerSelf: function (aComponentManager, aFileSpec, aLocation, aType) {
    aComponentManager.QueryInterface(CI.nsIComponentRegistrar);
    for (var key in this._objects) {
      var obj = this._objects[key];
      aComponentManager.registerFactoryLocation(obj.CID, obj.className,
        obj.contractID, aFileSpec, aLocation, aType);
    }
  },

  unregisterSelf: function(aCompMgr, aFileSpec, aLocation) {
    aComponentManager.QueryInterface(CI.nsIComponentRegistrar);
    for (var key in this._objects) {
      var obj = this._objects[key];
      aComponentManager.unregisterFactoryLocation(obj.CID, aFileSpec);
    }
  },

  getClassObject: function(aComponentManager, aCID, aIID) {
    if (!aIID.equals(CI.nsIFactory)) throw CR.NS_ERROR_NOT_IMPLEMENTED;

    for (var key in this._objects) {
      if (aCID.equals(this._objects[key].CID))
        return this._objects[key].factory;
    }

    throw CR.NS_ERROR_NO_INTERFACE;
  },

  canUnload: function(aComponentManager) {
    return true;
  },

  _objects: {} //FactoryHolder
};

function NSGetModule(compMgr, fileSpec) {
  for(var i in objects)
    gModule._objects[i] = new FactoryHolder(objects[i]);
  return gModule;
}
