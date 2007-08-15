/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Nightly Tester Tools.
 *
 * The Initial Developer of the Original Code is
 *      Dave Townsend <dave.townsend@blueprintit.co.uk>.
 *
 * Portions created by the Initial Developer are Copyright (C) 2006
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK *****
 *
 * $HeadURL: file:///srv/svn/repos/dave/mozilla/firefox/buildid/trunk/src/components/nsDownloadListener.js $
 * $LastChangedBy: dave $
 * $Date: 2006-05-01 14:58:48 +0100 (Mon, 01 May 2006) $
 * $Revision: 660 $
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
