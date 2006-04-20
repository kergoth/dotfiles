const _ADBLOCK_CONTRACTID = "@mozilla.org/adblock;1";
const _ADBLOCK_CID = Components.ID('{34274bf4-1d97-a289-e984-17e546307e4f}');

const CATMAN_CONTRACTID = "@mozilla.org/categorymanager;1";
const JSLOADER_CONTRACTID = "@mozilla.org/moz/jssubscript-loader;1";

/*
 * Module object
 */

var module =
{
	factoryLoaded: false,

	registerSelf: function(compMgr, fileSpec, location, type)
	{
		compMgr = compMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar);
		compMgr.registerFactoryLocation(_ADBLOCK_CID, 
										"Adblock content policy",
										_ADBLOCK_CONTRACTID,
										fileSpec, location, type);

		var catman = Components.classes[CATMAN_CONTRACTID].getService(Components.interfaces.nsICategoryManager);
		catman.addCategoryEntry("content-policy", _ADBLOCK_CONTRACTID,
							_ADBLOCK_CONTRACTID, true, true);
	},

	unregisterSelf: function(compMgr, fileSpec, location)
	{
		compMgr = compMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar);

		compMgr.unregisterFactoryLocation(_ADBLOCK_CID, fileSpec);
		var catman = Components.classes[CATMAN_CONTRACTID].getService(Components.interfaces.nsICategoryManager);
		catman.deleteCategoryEntry("content-policy", _ADBLOCK_CONTRACTID, true);
	},

	getClassObject: function(compMgr, cid, iid)
	{
		if (!cid.equals(_ADBLOCK_CID))
			throw Components.results.NS_ERROR_NO_INTERFACE;

		if (!iid.equals(Components.interfaces.nsIFactory))
			throw Components.results.NS_ERROR_NOT_IMPLEMENTED;

		if (!this.factoryLoaded || !patterns)
		{
			var loader = Components.classes[JSLOADER_CONTRACTID].getService(Components.interfaces.mozIJSSubScriptLoader);
			loader.loadSubScript('chrome://adblock/content/component.js');
			this.factoryLoaded = factory;
		}

		return factory;
	},

	canUnload: function(compMgr)
	{
		return true;
	}
};

// module initialisation
function NSGetModule(comMgr, fileSpec)
{
	return module;
}
