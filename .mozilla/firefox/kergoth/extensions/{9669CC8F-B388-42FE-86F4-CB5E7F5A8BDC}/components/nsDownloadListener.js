/*
 * $HeadURL: svn://svn.blueprintit.co. uk/dave/mozilla/firefox/buildid/trunk/components/nsDownloadListener.js $
 * $LastChangedBy: dave $
 * $Date: 2006-01-22 20:05:21 +0000 (Sun, 22 Jan 2006) $
 * $Revision: 467 $
 *
 */

function DownloadListener()
{
}

DownloadListener.prototype.init = function(name,uri,file,transfer)
{
  this.uri=uri;
  this.name=name;
	this.file=file;
	this.transfer=transfer;
}

DownloadListener.prototype.onLocationChange = function(webProgress, request, location)
{
	this.transfer.onLocationChange(webProgress, request, location);
}

DownloadListener.prototype.onProgressChange = function(webProgress, request, curSelfProgress, maxSelfProgress, curTotalProgress, maxTotalProgress)
{
	this.transfer.onProgressChange(webProgress, request, curSelfProgress, maxSelfProgress, curTotalProgress, maxTotalProgress);
}

DownloadListener.prototype.onSecurityChange = function(webProgress, request, state)
{
	this.transfer.onSecurityChange(webProgress, request, state);
}

DownloadListener.prototype.onStateChange = function(webProgress, request, stateFlags, status)
{
	this.transfer.onStateChange(webProgress, request, stateFlags, status);
	if (stateFlags&Components.interfaces.nsIWebProgressListener.STATE_STOP)
	{
    var nightlyService = Components.classes["@mrtech.com/nightlytools;1"]
                              .getService(Components.interfaces.nsINightlyToolsCallback);
    if (status==0)
    {
      nightlyService.installLocalExtension(this.name,this.uri,this.file);
    }
    else
    {
     	var sbs = Components.classes["@mozilla.org/intl/stringbundle;1"]
    									.getService(Components.interfaces.nsIStringBundleService);
    	var bundle = sbs.createBundle("chrome://local_install/locale/nightly.properties");
   		var promptService = Components.classes["@mozilla.org/embedcomp/prompt-service;1"]
  	                    .getService(Components.interfaces.nsIPromptService);
  	  
      var text=bundle.formatStringFromName("nightly.downloadfail.message",[this.name, status],2);
      promptService.alert(null,"Nightly Tester Tools",text);

      nightlyService.installFailed(this.name,this.uri);
    }
    
    if (this.file.exists())
    	this.file.remove(false);
	}
}

DownloadListener.prototype.onStatusChange = function(webProgress, request, status, message)
{
	this.transfer.onStatusChange(webProgress, request, status, message);
}

DownloadListener.prototype.QueryInterface = function(iid)
{
	if (iid.equals(Components.interfaces.nsIWebProgressListener)
		|| iid.equals(Components.interfaces.nsIDownloadListener)
		|| iid.equals(Components.interfaces.nsISupports))
	{
		return this;
	}
	else (iid.equals(Components.interfaces.nsIRDFRemoteDataSource))
	{
		throw Components.results.NS_ERROR_NO_INTERFACE;
	}
}

var initModule =
{
	ServiceCID: Components.ID("{98DDA5F8-B594-4DC0-9687-9815D5FC0E11}"),
	ServiceContractID: "@mrtech.com/downloadlistener;1",
	ServiceName: "MR Tech - Nightly Tester Download Listener",
	
	registerSelf: function (compMgr, fileSpec, location, type)
	{
		compMgr = compMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar);
		compMgr.registerFactoryLocation(this.ServiceCID,this.ServiceName,this.ServiceContractID,
			fileSpec,location,type);
	},

	unregisterSelf: function (compMgr, fileSpec, location)
	{
		compMgr = compMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar);
		compMgr.unregisterFactoryLocation(this.ServiceCID,fileSpec);
	},

	getClassObject: function (compMgr, cid, iid)
	{
		if (!cid.equals(this.ServiceCID))
			throw Components.results.NS_ERROR_NO_INTERFACE
		if (!iid.equals(Components.interfaces.nsIFactory))
			throw Components.results.NS_ERROR_NOT_IMPLEMENTED;
		return this.instanceFactory;
	},

	canUnload: function(compMgr)
	{
		return true;
	},

	instanceFactory:
	{
		createInstance: function (outer, iid)
		{
			if (outer != null)
				throw Components.results.NS_ERROR_NO_AGGREGATION;
			var instance = new DownloadListener();
			return instance.QueryInterface(iid);
		}
	}
}; //Module

function NSGetModule(compMgr, fileSpec)
{
	return initModule;
}
