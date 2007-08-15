function Downbar() {
	// you can do |this.wrappedJSObject = this;| for the first version of the component
	// (in case you don't want to write IDL yet.)
	this.wrappedJSObject = this;
}
Downbar.prototype = {
	classID: Components.ID("{D4EE4143-3560-44c3-B170-4AC54D7D8AC1}"),
	contractID: "@devonjensen.com/downbar/downbar;1",
	classDescription: "Window independent Download Statusbar functions",

	QueryInterface: function(aIID) {
		if(!aIID.equals(CI.nsISupports) && !aIID.equals(CI.nsIObserver) && !aIID.equals(CI.nsISupportsWeakReference)) // you can claim you implement more interfaces here
			throw CR.NS_ERROR_NO_INTERFACE;
		return this;
	},

	// nsIObserver implementation
	observe: function(aSubject, aTopic, aData) {

		//var acs = Components.classes["@mozilla.org/consoleservice;1"].getService(Components.interfaces.nsIConsoleService);
		//acs.logStringMessage('downbar ' + aTopic);

		switch(aTopic) {
			case "xpcom-startup":
				//dump("xpcom-startup");
				// this is run very early, right after XPCOM is initialized, but before
				// user profile information is applied.
				var obsSvc = CC["@mozilla.org/observer-service;1"].getService(CI.nsIObserverService);
				obsSvc.addObserver(this, "profile-after-change", true);
				obsSvc.addObserver(this, "quit-application-granted", true);
				obsSvc.addObserver(this, "dl-start", true);
				obsSvc.addObserver(this, "dl-done", true);
				obsSvc.addObserver(this, "em-action-requested", true);
				//obsSvc.addObserver(this, "domwindowopened", true);
			break;
			
			//case "domwindowopened":
					
			//break;
		
			case "profile-after-change":
				// This happens after profile has been loaded and user preferences have been read.
				// startup code here
				
		
			break;
		
			case "dl-start":
			
				var db_dl = aSubject.QueryInterface(Components.interfaces.nsIDownload);
				var elmpath = db_dl.targetFile.path;
				//var fixedelmpath = elmpath.replace(/\\/g, "\\\\");  // The \ and ' get messed up in the command if they are not fixed
				//fixedelmpath = fixedelmpath.replace(/\'/g, "\\\'");
				var db_fileext = elmpath.split(".").pop().toLowerCase();
			
				var db_pref = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
				var db_ignoreList = new Array ( );
				
				var ignoreRaw = db_pref.getCharPref("downbar.function.ignoreFiletypes");
				ignoreRaw = ignoreRaw.toLowerCase().replace(/\s/g,'');  // remove all whitespace
				db_ignoreList = ignoreRaw.split(",");
				
				// If it's on the ignore list, don't show it on the downbar
				for (var i=0; i<=db_ignoreList.length; ++i) {
						if (db_fileext == db_ignoreList[i])	
							return;
				}
		
				var rdf = Components.classes["@mozilla.org/rdf/rdf-service;1"].getService(Components.interfaces.nsIRDFService);
				var intNode = rdf.GetIntLiteral(1);
				this.db_setRDFProperty(elmpath, "DownbarShow", intNode);
		/*
				var allowDLstart = db_checkQueue();
				//d(allowDLstart);
				if (!allowDLstart){
					var fixedelmpath = elmpath.replace(/\\/g, "\\\\");  // The \ and ' get messed up in the command if they are not fixed
					fixedelmpath = fixedelmpath.replace(/\'/g, "\\\'");
					window.setTimeout("db_stopit('" + fixedelmpath + "')", 100);
				}
		*/
				//window.setTimeout("db_checkShouldShow()", 100);
				//window.setTimeout("db_startUpdateDLrepeat('" + fixedelmpath + "')", 100);
				
				
				var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService(Components.interfaces.nsIWindowMediator);
				var e = wm.getEnumerator("navigator:browser");
				var win;
		
				while (e.hasMoreElements()) {
					win = e.getNext();
					
					win.db_startUpdateDLrepeat(elmpath);
					win.document.getElementById("downbar").hidden = false;
						
					win.db_startUpdateMini();
					
				}
		
			break;
		
			case "dl-done":
				//var acs = Components.classes["@mozilla.org/consoleservice;1"].getService(Components.interfaces.nsIConsoleService);
				//acs.logStringMessage('download done ' + aTopic);
				
				var db_dl = aSubject.QueryInterface(Components.interfaces.nsIDownload);
				var elmpath = db_dl.targetFile.path;
				//var fixedelmpath = elmpath.replace(/\\/g, "\\\\");  // The \ and ' get messed up in the command if they are not fixed
				//fixedelmpath = fixedelmpath.replace(/\'/g, "\\\'");
				var db_fileext = elmpath.split(".").pop().toLowerCase();
				
				this.db_dlCompleteSound(db_fileext);
				
				this.db_AntiVirusScan(elmpath, db_fileext);
				
				var db_pref = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
				var clearTime = db_pref.getIntPref("downbar.function.timeToClear");
				var clearRaw = db_pref.getCharPref("downbar.function.clearFiletypes");
				var db_clearList = new Array ( );
				
				clearRaw = clearRaw.toLowerCase().replace(/\s/g,'');  // remove all whitespace
				db_clearList = clearRaw.split(",");
				
				
				// check if it's on the list of autoclear
				var autoClear = false;
				if(db_clearList[0] == "all" | db_clearList[0] == "*")
					autoClear = true;
				else {
					for (var i=0; i<=db_clearList.length; ++i) {
						if (db_fileext == db_clearList[i])
							autoClear = true;
					}
				}
								
				var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService(Components.interfaces.nsIWindowMediator);
				var e = wm.getEnumerator("navigator:browser");
				var win;
				
				// For delayed actions, like autoclear, enumerating each window and calling timeout doesn't work 
				// (all the timeouts are triggered on one window), so need to call a function in the window and have it do the timeout 
				while (e.hasMoreElements()) {
					win = e.getNext();
					
					//var acs = Components.classes["@mozilla.org/consoleservice;1"].getService(Components.interfaces.nsIConsoleService);
					//acs.logStringMessage(win.self._content.location.href);
				
					if(autoClear) {
						win.db_startAutoClear(elmpath, clearTime*1000);
					}
					
					win.db_startUpdateMini();
					win.setTimeout("db_updateProgressNow()", 10);  // sorta works - at least for image saves
				}
				
				
			break;  
		
		
			case "quit-application-granted":
				
				var db_pref = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
				try {
					if(db_pref.getBoolPref("downbar.toUninstall")) {
						// Put back the firefox download manager settings
						db_pref.setBoolPref("browser.download.manager.showWhenStarting", true);
						db_pref.setBoolPref("browser.download.manager.showAlertOnComplete", true);
						db_pref.setBoolPref("downbar.toUninstall", false);
						db_pref.setBoolPref("downbar.function.firstRun", true);
						if(!db_pref.getBoolPref("downbar.function.keepHistory"))
							db_pref.setIntPref("browser.download.manager.retention", 0);
						
					}
				} catch(e){}
				
				try {
					var launchDLWin = db_pref.getBoolPref("downbar.function.launchOnClose");
					var clearOnClose = db_pref.getBoolPref("downbar.function.clearOnClose");
				} catch(e){}
				
				const db_dlmgrContractID = "@mozilla.org/download-manager;1";
				const db_dlmgrIID = Components.interfaces.nsIDownloadManager;
				db_gDownloadManager = Components.classes[db_dlmgrContractID].getService(db_dlmgrIID);
				
				if(launchDLWin && db_gDownloadManager.activeDownloadCount > 0) {
					var ww = Components.classes["@mozilla.org/embedcomp/window-watcher;1"].getService(Components.interfaces.nsIWindowWatcher);
					
					var dlWin = ww.openWindow(null, 'chrome://mozapps/content/downloads/downloads.xul', null, 'chrome,dialog=no,resizable', null);
					// prevents the File...Exit "goquitApplication" from closing the new window
					dlWin.tryToClose = function(){return false;}
				}
				
				this.db_trimHistory();
				
				// leaving this in the browser window for the sake of efficiency (don't want to iterate over everything in downloads.rdf looking for downbarshow=1 when closing
				//if(clearOnClose) {
				//	db_clearAll();
				//}
				
		
			break;
			
			case "em-action-requested":
				subject = aSubject.QueryInterface(Components.interfaces.nsIUpdateItem);
				if (subject.id == "{D4DD63FA-01E4-46a7-B6B1-EDAB7D6AD389}") {
					var db_pref = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
					switch (aData) {
		    			case "item-uninstalled":
		     				db_pref.setBoolPref("downbar.toUninstall", true);
		    				break;
		    			case "item-cancel-action":
		     				db_pref.setBoolPref("downbar.toUninstall", false);
		    				break;
		    		}
					
				}
			break;
		
			default:
				throw Components.Exception("Unknown topic: " + aTopic);
		}
	},

	db_dlCompleteSound : function(fileExt) {
	
		var db_pref = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
	
		try {
			var shouldSound = db_pref.getIntPref("downbar.function.soundOnComplete");  // 0:no sound, 1: default sound, 2: custom sound
			var ignoreListRaw = db_pref.getCharPref("downbar.function.soundCompleteIgnore");
		} catch(e){}
		
		if(shouldSound == 0)
			return;
		
		var soundIgnoreList = new Array ( );
		ignoreListRaw = ignoreListRaw.toLowerCase().replace(/\s/g,'');  // remove all whitespace
		soundIgnoreList = ignoreListRaw.split(",");
		
		var toIgnore = false;
		for (var i=0; i<=soundIgnoreList.length; ++i) {
			if (fileExt == soundIgnoreList[i])
				toIgnore = true;
		}
		if(toIgnore)
			return;
			
		try {
			var sound = Components.classes["@mozilla.org/sound;1"].createInstance(Components.interfaces.nsISound);
			var nsIIOService = Components.classes['@mozilla.org/network/io-service;1'].getService(Components.interfaces.nsIIOService);
			
			var soundLoc;
			if(shouldSound == 1)
				soundLoc = "chrome://downbar/content/downbar_finished.wav";
			
			if(shouldSound == 2) {
				var soundLoc = db_pref.getCharPref("downbar.function.soundCustomComplete");  //format of filesystem sound "file:///c:/sound1_final.wav"
			}
			
		
			soundURIformat = nsIIOService.newURI(soundLoc,null,null);
			sound.play(soundURIformat);
		} catch(e) {
			sound.beep;
		}
		
	},
	
	db_AntiVirusScan : function(filepath, db_fileext) {
		
		//var acs = Components.classes["@mozilla.org/consoleservice;1"].getService(Components.interfaces.nsIConsoleService);
		//acs.logStringMessage(filepath);
		
		var db_pref = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
		var shouldScan = db_pref.getBoolPref("downbar.function.virusScan");
		if(shouldScan) {
			
			var dlPath = filepath;
			try {
				var defCharset = db_pref.getComplexValue("intl.charset.default", Components.interfaces.nsIPrefLocalizedString).data;
				var uniConv = Components.classes['@mozilla.org/intl/scriptableunicodeconverter'].createInstance(Components.interfaces.nsIScriptableUnicodeConverter);
				uniConv.charset = defCharset;
				var convertedPath = uniConv.ConvertFromUnicode(dlPath);
				dlPath = convertedPath;
			}
			catch(e) {}
			
			var db_excludeList = new Array ( );
			var excludeRaw = db_pref.getCharPref("downbar.function.virusExclude");
			excludeRaw = excludeRaw.toLowerCase().replace(/\s/g,'');  // remove all whitespace
			db_excludeList = excludeRaw.split(",");
			
			var excludeFiletype = false;
			for (var i=0; i<=db_excludeList.length; ++i) {
				if (db_fileext == db_excludeList[i])
					excludeFiletype = true;
			}
			
			if(!excludeFiletype) {	
				try {
					var AVProgLoc = db_pref.getCharPref("downbar.function.virusLoc");
					var AVArgs = db_pref.getCharPref("downbar.function.virusArgs");
					var AVExecFile = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);
					var process = Components.classes["@mozilla.org/process/util;1"].createInstance(Components.interfaces.nsIProcess);
					
					// Arguments must be separated into an array
					var args = AVArgs.split(" ");
					// Put the path where it is supposed to be
					for (var i=0; i<args.length; ++i) {
						args[i] = args[i].replace(/%1/g, dlPath);
					}
					
					AVExecFile.initWithPath(AVProgLoc);
					if (AVExecFile.exists()) {
						process.init(AVExecFile);
						process.run(false, args, args.length);
					}
					else {
						var bundleService = Components.classes["@mozilla.org/intl/stringbundle;1"].getService(Components.interfaces.nsIStringBundleService);
						var stringBundle = bundleService.createBundle("chrome://downbar/locale/downbar.properties");
							
						var promptSvc = Components.classes["@mozilla.org/embedcomp/prompt-service;1"].getService(Components.interfaces.nsIPromptService);
						promptSvc.alert(null,"Download statusbar",stringBundle.GetStringFromName("AVnotFound"));
					}
				} catch (e) {
						var bundleService = Components.classes["@mozilla.org/intl/stringbundle;1"].getService(Components.interfaces.nsIStringBundleService);
						var stringBundle = bundleService.createBundle("chrome://downbar/locale/downbar.properties");
							
						var promptSvc = Components.classes["@mozilla.org/embedcomp/prompt-service;1"].getService(Components.interfaces.nsIPromptService);
						promptSvc.alert(null,"Download statusbar",stringBundle.GetStringFromName("failedAV"));
					return;
				}
			}
		}
		
	},
	
	db_trimHistory : function() {
		
		var db_pref = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
		try {
			var shouldTrim = db_pref.getBoolPref("downbar.function.trimHistory");
			var limit = db_pref.getIntPref("downbar.function.numToTrim");
			var downloadRetention = db_pref.getIntPref("browser.download.manager.retention");
		} catch (e){}
		if(!shouldTrim)
			return;
		if(downloadRetention != 2) //Then it is clearing on close or on successful download and this will have no effect
			return;
	
		var rdf = Components.classes["@mozilla.org/rdf/rdf-service;1"].getService(Components.interfaces.nsIRDFService);
		const db_dlmgrContractID = "@mozilla.org/download-manager;1";
		const db_dlmgrIID = Components.interfaces.nsIDownloadManager;
		db_gDownloadManager = Components.classes[db_dlmgrContractID].getService(db_dlmgrIID);
		var ds = db_gDownloadManager.datasource;
		
		var dlRes = rdf.GetResource("NC:DownloadsRoot");
		var dlCont = Components.classes["@mozilla.org/rdf/container;1"].getService(Components.interfaces.nsIRDFContainer);
		//var mCUtils = Components.classes["@mozilla.org/rdf/container-utils;1"].getService(Components.interfaces.nsIRDFContainerUtils);
		//d(mCUtils.IsContainer(ds,dlRes));
		dlCont.Init(ds, dlRes);
		var numDL = dlCont.GetCount();
	
		if(numDL > limit) {
			//var diff = numDL - limit;
			//d(numDL + " - " + limit + " = " + diff);
			var allDownloads = dlCont.GetElements();
	
			for(i = 1; i <= limit; ++i) { // Downloads to keep
				allDownloads.getNext();
				//var resource2 = allDownloads.getNext();
				//d("keep: " + resource2.QueryInterface(Components.interfaces.nsIRDFResource).ValueUTF8);
			}
			var toRemove = new Array(); // hold the id of elements that are to be removed in the 2nd for loop
			var posCount = 1;
			while(allDownloads.hasMoreElements()) { // Downloads to get rid of
				var resource = allDownloads.getNext();
				//d("remove: " + resource.QueryInterface(Components.interfaces.nsIRDFResource).ValueUTF8);
				toRemove[posCount] = resource.QueryInterface(Components.interfaces.nsIRDFResource).ValueUTF8;
				posCount++;
			}
	
			db_gDownloadManager.startBatchUpdate();
			db_gDownloadManager.datasource.beginUpdateBatch();
	
			var dlState;
			for(var j = 1; j <= posCount - 1; ++j){
				try {
					dlState = document.getElementById(toRemove[j]).getAttribute("state");
					if (dlState == "1")  // check that it's not an active paused or stopped download
						db_gDownloadManager.removeDownload(toRemove[j]);
				} catch (e){db_gDownloadManager.removeDownload(toRemove[j]);} // canceled downloads not on the statusbar are fair game to be trimmed (it won't be active or paused)
			}
			db_gDownloadManager.datasource.endUpdateBatch();
	    	db_gDownloadManager.endBatchUpdate();
		}
		
	},
	
	db_showSampleDownload : function() {
	
		var rdf = Components.classes["@mozilla.org/rdf/rdf-service;1"].getService(Components.interfaces.nsIRDFService);
		const db_dlmgrContractID = "@mozilla.org/download-manager;1";
		const db_dlmgrIID = Components.interfaces.nsIDownloadManager;
		db_gDownloadManager = Components.classes[db_dlmgrContractID].getService(db_dlmgrIID);
		var ds = db_gDownloadManager.datasource;
			
		var dlRes = rdf.GetResource("NC:DownloadsRoot");
		var dlCont = Components.classes["@mozilla.org/rdf/container;1"].getService(Components.interfaces.nsIRDFContainer);
		dlCont.Init(ds, dlRes);
		var numDL = dlCont.GetCount();
		
		// show them their last download
		if(numDL > 0) {
			var allDownloads = dlCont.GetElements();
			var latestDownload = allDownloads.getNext();
			
			downloadPath = latestDownload.QueryInterface(Components.interfaces.nsIRDFResource).ValueUTF8;
			
			var intNode = rdf.GetIntLiteral(1);
			this.db_setRDFProperty(downloadPath, "DownbarShow", intNode);
			
		}
		
		else {
			// xxxshow a fake sample download?
		}
	},
	
	db_setRDFProperty : function(aID, aProperty, aValue) {
		
		const db_dlmgrContractID = "@mozilla.org/download-manager;1";
		const db_dlmgrIID = Components.interfaces.nsIDownloadManager;
		db_gDownloadManager = Components.classes[db_dlmgrContractID].getService(db_dlmgrIID);
		
		var rdf = Components.classes["@mozilla.org/rdf/rdf-service;1"].getService(Components.interfaces.nsIRDFService);
		var db = db_gDownloadManager.datasource;
		var propertyArc = rdf.GetResource("http://home.netscape.com/NC-rdf#" + aProperty);
		var res = rdf.GetResource(aID);
		var node = db.GetTarget(res, propertyArc, true);
	
		if (node)
			db.Change(res, propertyArc, node, aValue);
		else
			db.Assert(res, propertyArc, aValue, true);
		var remoteDS = db.QueryInterface(Components.interfaces.nsIRDFRemoteDataSource);
	    remoteDS.Flush();
	},

	db_getRDFProperty : function (aID, aProperty) {
		
		var rdf = Components.classes["@mozilla.org/rdf/rdf-service;1"].getService(Components.interfaces.nsIRDFService);
		
		const db_dlmgrContractID = "@mozilla.org/download-manager;1";
		const db_dlmgrIID = Components.interfaces.nsIDownloadManager;
		db_gDownloadManager = Components.classes[db_dlmgrContractID].getService(db_dlmgrIID);
	
		var db = db_gDownloadManager.datasource;
		var propertyArc = rdf.GetResource("http://home.netscape.com/NC-rdf#" + aProperty);
	
		var res = rdf.GetResource(aID);
		var node = db.GetTarget(res, propertyArc, true);
		if (!node) return "";
		try {
			node = node.QueryInterface(Components.interfaces.nsIRDFLiteral);
			return node.Value;
		}
		catch(e) {
			try {
				node = node.QueryInterface(Components.interfaces.nsIRDFInt);
				return node.Value;
			}
			catch(e) {
				try {
					node = node.QueryInterface(Components.interfaces.nsIRDFResource);
					return node.Value;
				} catch(e) {
					node = node.QueryInterface(Components.interfaces.nsIRDFDate);
					return node.Value;
				}
				
			}
		}
		return "";
	},
	


};


// constructors for objects we want to XPCOMify
var objects = [Downbar];

/*
* Registration code.
*
*/

const CI = Components.interfaces, CC = Components.classes, CR = Components.results;

const MY_OBSERVER_NAME = "Downbar Observer";

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

// this can be deleted if you don't need to init on startup
var catman = CC["@mozilla.org/categorymanager;1"].getService(CI.nsICategoryManager);
catman.addCategoryEntry("xpcom-startup", MY_OBSERVER_NAME,
Downbar.prototype.contractID, true, true);
catman.addCategoryEntry("xpcom-shutdown", MY_OBSERVER_NAME,
Downbar.prototype.contractID, true, true);
},

unregisterSelf: function(aCompMgr, aFileSpec, aLocation) {
// this must be deleted if you delete the above code dealing with |catman|
var catman = CC["@mozilla.org/categorymanager;1"].getService(CI.nsICategoryManager);
catman.deleteCategoryEntry("xpcom-startup", MY_OBSERVER_NAME, true);
// end of deleteable code

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