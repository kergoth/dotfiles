function StylishStartup() {
}
StylishStartup.prototype = {
  classID: Components.ID("{a0029965-c87c-486b-b721-94c965622004}"),
  contractID: "@stylish/startup;1",
  classDescription: "Stylish Startup",

  QueryInterface: function(aIID) {
    if(!aIID.equals(CI.nsISupports) && !aIID.equals(CI.nsIObserver))
      throw CR.NS_ERROR_NO_INTERFACE;
    return this;
  },

  observe: function(aSubject, aTopic, aData) {
    switch(aTopic) {
      case "xpcom-startup":
        // this is run very early, right after XPCOM is initialized, but before
        // user profile information is applied. Register ourselves as an observer
        // for 'profile-after-change' and 'quit-application'.
        var obsSvc = CC["@mozilla.org/observer-service;1"].getService(CI.nsIObserverService);
        obsSvc.addObserver(this, "profile-after-change", false);
        obsSvc.addObserver(this, "quit-application", false);
        break;

      case "profile-after-change":
        // This happens after profile has been loaded and user preferences have been read.
        // startup code here
				var sss = Components.classes["@mozilla.org/content/style-sheet-service;1"]
			  	                  .getService(Components.interfaces.nsIStyleSheetService);
				var ios = Components.classes["@mozilla.org/network/io-service;1"]
        				            .getService(Components.interfaces.nsIIOService);
				var rdfService = Components.classes["@mozilla.org/rdf/rdf-service;1"].getService(Components.interfaces.nsIRDFService);
				var ds = rdfService.GetDataSourceBlocking(this.getDatasourceURI());
				var rdfContainerUtils = Components.classes["@mozilla.org/rdf/container-utils;1"].getService(Components.interfaces.nsIRDFContainerUtils);
				var container = rdfContainerUtils.MakeSeq(ds, rdfService.GetResource("urn:stylish:userstyles"));
				var children = container.GetElements();
				var enabledPredicate = rdfService.GetResource("urn:stylish#enabled");
				var codePredicate = rdfService.GetResource("urn:stylish#code");
				while (children.hasMoreElements()) {
					var current = children.getNext();
					var enabledNode = ds.GetTarget(current, enabledPredicate, true)
					if (enabledNode) {
						var enabled = enabledNode.QueryInterface(Components.interfaces.nsIRDFLiteral).Value;
						if (enabled == "true") {
							var cssNode = ds.GetTarget(current, codePredicate, true);
							if (cssNode) {
								var css = cssNode.QueryInterface(Components.interfaces.nsIRDFLiteral).Value;
								var u = ios.newURI("data:text/css," + css, null, null);
								sss.loadAndRegisterSheet(u, sss.USER_SHEET);
							}
						}
					}
				}
        break;

      case "quit-application":
        // shutdown code here
        break;

      default:
        throw Components.Exception("Unknown topic: " + aTopic);
    }
  },

	getDatasourceURI: function() {
		var prefs = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
		var prefPath = prefs.getCharPref("extensions.stylish.fileURL");
		if (prefPath.length > 0) {
			return prefPath;
		}
		var file = Components.classes["@mozilla.org/file/directory_service;1"].getService(Components.interfaces.nsIProperties).get("ProfD", Components.interfaces.nsIFile);
		file.append("stylish.rdf");
		var ioService = Components.classes["@mozilla.org/network/io-service;1"].getService(Components.interfaces.nsIIOService);
		if (!file.exists()) {
			//either this is the first run or the user deleted his file (the bastard)

			//read the default file's contents (courtesy Torisugari <http://forums.mozillazine.org/viewtopic.php?p=921150#921150>)
			var scriptableStream = Components.classes["@mozilla.org/scriptableinputstream;1"].getService(Components.interfaces.nsIScriptableInputStream);
			var channel = ioService.newChannel("chrome://stylish/content/stylish-default.rdf", null, null);
			var input = channel.open();
			scriptableStream.init(input);
			var data = scriptableStream.read(input.available());
			scriptableStream.close();
			input.close();

			//write the contents to the profile file
			var foStream = Components.classes["@mozilla.org/network/file-output-stream;1"].createInstance(Components.interfaces.nsIFileOutputStream);
			foStream.init(file, 0x02 | 0x08 | 0x20, 0664, 0); // write, create, truncate
			foStream.write(data, data.length);
			foStream.close();
		}
		return ioService.newFileURI(file).spec;
	}
};


// constructors for objects we want to XPCOMify
var objects = [StylishStartup];

/*
 * Registration code.
 *
 */

const CI = Components.interfaces, CC = Components.classes, CR = Components.results;

const MY_OBSERVER_NAME = "StylishStartup";

function FactoryHolder(aObj) {
  this.CID        = aObj.prototype.classID;
  this.contractID = aObj.prototype.contractID;
  this.className  = aObj.prototype.classDescription;
  this.factory = {
    createInstance: function(aOuter, aIID) {
      if(aOuter)
        throw CR.NS_ERROR_NO_AGGREGATION;
      return (new this.constructor).QueryInterface(aIID);
    }
  };
  this.factory.constructor = aObj;
}

var gModule = {
  registerSelf: function (aComponentManager, aFileSpec, aLocation, aType)
  {
    aComponentManager.QueryInterface(CI.nsIComponentRegistrar);
    for (var key in this._objects) {
      var obj = this._objects[key];
      aComponentManager.registerFactoryLocation(obj.CID, obj.className,
        obj.contractID, aFileSpec, aLocation, aType);
    }

    var catman = CC["@mozilla.org/categorymanager;1"].getService(CI.nsICategoryManager);
    catman.addCategoryEntry("xpcom-startup", MY_OBSERVER_NAME,
      StylishStartup.prototype.contractID, true, true);
    catman.addCategoryEntry("xpcom-shutdown", MY_OBSERVER_NAME,
      StylishStartup.prototype.contractID, true, true);
  },

  unregisterSelf: function(aCompMgr, aFileSpec, aLocation) {
    var catman = CC["@mozilla.org/categorymanager;1"].getService(CI.nsICategoryManager);
    catman.deleteCategoryEntry("xpcom-startup", MY_OBSERVER_NAME, true);

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

function NSGetModule(compMgr, fileSpec)
{
  for(var i in objects)
    gModule._objects[i] = new FactoryHolder(objects[i]);
  return gModule;
} 
