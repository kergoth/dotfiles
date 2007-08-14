const Cc = Components.classes;
const Ci = Components.interfaces;
const Cr = Components.results;

const report = Components.utils.reportError;

var SessionManagerHelperComponent = {
	mCID: Components.ID("{5714d620-47ce-11db-b0de-0800200c9a66}"),
	mContractID: "@zeniko/sessionmanager-helper;1",
	mClassName: "Session Manager Helper Component",
	mCategory: "a-sessionmanagerhelpher",

/* ........ nsIModule .............. */

	getClassObject: function(aCompMgr, aCID, aIID)
	{
		if (!aCID.equals(this.mCID))
		{
			Components.returnCode = Cr.NS_ERROR_NOT_REGISTERED;
			return null;
		}

		return this.QueryInterface(aIID);
	},

	registerSelf: function(aCompMgr, aFileSpec, aLocation, aType)
	{
		aCompMgr.QueryInterface(Ci.nsIComponentRegistrar);
		aCompMgr.registerFactoryLocation(this.mCID, this.mCategory, this.mContractID, aFileSpec, aLocation, aType);

		var catMan = Cc["@mozilla.org/categorymanager;1"].getService(Ci.nsICategoryManager);
		catMan.addCategoryEntry("app-startup", this.mClassName, "service," + this.mContractID, true, true);
	},

	unregisterSelf: function(aCompMgr, aLocation, aType)
	{
		aCompMgr.QueryInterface(Ci.nsIComponentRegistrar);
		aCompMgr.unregisterFactoryLocation(this.mCID, aLocation);

		var catMan = Cc["@mozilla.org/categorymanager;1"].getService(Ci.nsICategoryManager);
		catMan.deleteCategoryEntry("app-startup", "service," + this.mContractID, true);
	},

	canUnload: function(aCompMgr)
	{
		return true;
	},

/* ........ nsIFactory .............. */

	createInstance: function(aOuter, aIID)
	{
		if (aOuter != null)
		{
			Components.returnCode = Cr.NS_ERROR_NO_AGGREGATION;
			return null;
		}

		return this.QueryInterface(aIID);
	},

	lockFactory: function(aLock) { },

/* ........ nsIObserver .............. */

	observe: function(aSubject, aTopic, aData)
	{
		var os = Cc["@mozilla.org/observer-service;1"].getService(Ci.nsIObserverService);

		switch (aTopic)
		{
		case "app-startup":
			os.addObserver(this, "profile-after-change", false);
			break;
		case "profile-after-change":
			os.removeObserver(this, aTopic);
			try
			{
				this._restoreCache();
			}
			catch (ex) { report(ex); }
			try
			{
				this._backupSession();
			}
			catch (ex) { report(ex); }
			break;
		}
	},

/* ........ private methods .............. */

	// code adapted from Danil Ivanov's "Cache Fixer" extension
	_restoreCache: function()
	{
		try
		{
			var prefroot = Cc["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch2);
			var disabled = prefroot.getBoolPref("extensions.sessionmanager.disable_cache_fixer");
			if (disabled)
			{
				var consoleService = Cc["@mozilla.org/consoleservice;1"].getService(Components.interfaces.nsIConsoleService);
				consoleService.logStringMessage("SessionManager: Cache Fixer disabled");
				return;
			}
		}
		catch (ex) {}

		var cache = Cc["@mozilla.org/file/directory_service;1"].getService(Ci.nsIProperties).get("ProfLD", Ci.nsILocalFile);
		cache.append("Cache");
		cache.append("_CACHE_MAP_");
		if (!cache.exists())
		{
			return;
		}

		var stream = Cc["@mozilla.org/network/file-input-stream;1"].createInstance(Ci.nsIFileInputStream);
		stream.init(cache, 0x01, 0, 0); // PR_RDONLY
		var input = Cc["@mozilla.org/binaryinputstream;1"].createInstance(Ci.nsIBinaryInputStream);
		input.setInputStream(stream);
		var content = input.readByteArray(input.available());
		input.close();

		if (content[15] != 1)
		{
			return;
		}
		content[15] = 0;

		stream = Cc["@mozilla.org/network/file-output-stream;1"].createInstance(Ci.nsIFileOutputStream);
		stream.init(cache, 0x02 | 0x20, 0600, 0); // PR_WRONLY | PR_TRUNCATE
		var output = Cc["@mozilla.org/binaryoutputstream;1"].createInstance(Ci.nsIBinaryOutputStream);
		output.setOutputStream(stream);
		output.writeByteArray(content, content.length);
		output.flush();
		output.close();
	},

	_backupSession: function()
	{
		var profile = Cc["@mozilla.org/file/directory_service;1"].getService(Ci.nsIProperties).get("ProfD", Ci.nsILocalFile);
		var backup = profile.clone();
		backup.append("sessionstore.bak");
		if (backup.exists())
		{
			backup.remove(false);
		}
		profile.append("sessionstore.js");
		if (profile.exists())
		{
			profile.copyTo(null, backup.leafName);
		}
	},

/* ........ QueryInterface .............. */

	QueryInterface: function(aIID)
	{
		if (!aIID.equals(Ci.nsISupports) && !aIID.equals(Ci.nsIModule) && !aIID.equals(Ci.nsIFactory) && !aIID.equals(Ci.nsIObserver))
		{
			Components.returnCode = Cr.NS_ERROR_NO_INTERFACE;
			return null;
		}

		return this;
	}
};

function NSGetModule(aComMgr, aFileSpec)
{
	return SessionManagerHelperComponent;
}
