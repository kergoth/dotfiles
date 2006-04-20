/*
 * $HeadURL: svn://svn.blueprintit.co.uk/dave/mozilla/firefox/buildid/trunk/components/nsNightlyToolsService.js $
 * $LastChangedBy: dave $
 * $Date: 2006-02-05 17:15:46 +0000 (Sun, 05 Feb 2006) $
 * $Revision: 503 $
 *
 */

var nsNightlyToolsService = {

installs: [],
failCount: 0,
successCount: 0,

displayAlert: function(id,args)
{
 	var sbs = Components.classes["@mozilla.org/intl/stringbundle;1"]
									.getService(Components.interfaces.nsIStringBundleService);
	var bundle = sbs.createBundle("chrome://local_install/locale/nightly.properties");
	var promptService = Components.classes["@mozilla.org/embedcomp/prompt-service;1"]
                    .getService(Components.interfaces.nsIPromptService);
  var text = bundle.formatStringFromName(id,args,args.length);
  promptService.alert(null,"Nightly Tester Tools",text);
},

installComplete: function()
{
  if ((this.failCount+this.successCount)==this.installs.length)
  {
    if (this.successCount>0)
    {
      if (this.failCount==0)
      {
        this.displayAlert("nightly.installsuccess.message",[]);
      }
      else
      {
        this.displayAlert("nightly.installpartial.message",[this.successCount]);
      }
    }
    this.successCount=0;
    this.failCount=0;
    this.installs=[];
  }
},

installFailed: function(name, uri)
{
  this.failCount++;
  this.installComplete();
},

installSucceeded: function(name, uri)
{
  this.successCount++;
  this.installComplete();
},

queueInstall: function(name, url)
{
  var newinstall = new Object();
  newinstall.name=name;
  newinstall.url=url;
  this.installs[this.installs.length]=newinstall;
},

performInstalls: function()
{
  for (var i in this.installs)
  {
    this.performInstall(this.installs[i].name,this.installs[i].url);
  }
},

performInstall: function(name, uri)
{
  dump("Installing "+name+" from "+uri+"\n");
  var ioService = Components.classes["@mozilla.org/network/io-service;1"]
                            .getService(Components.interfaces.nsIIOService);

  if (uri.schemeIs("file"))
  {
    try
    {
      var fph = ioService.getProtocolHandler("file").QueryInterface(Components.interfaces.nsIFileProtocolHandler);
      var file = fph.getFileFromURLSpec(uri.spec);
      if ((file)&&(file.exists()))
      {
        this.installLocalExtension(name,uri,file);
        return;
      }
    }
    catch (e)
    {
      dump("Failed - "+e+"\n");
    }
    this.displayAlert("nightly.nofile.message",[name]);
    this.installFailed(name,uri);
  }
  else
  {
    try
    {  
     	var directoryService = Components.classes["@mozilla.org/file/directory_service;1"].
    										getService(Components.interfaces.nsIProperties);
    	dir = directoryService.get("TmpD",Components.interfaces.nsIFile);
    
    	var i=0;
    	var file;
  		file=dir.clone();
  		file.append("nightlytmp.xpi");
  		file.createUnique(Components.interfaces.nsILocalFile.NORMAL_FILE_TYPE, 0644);
  	  fileuri=ioService.newFileURI(file);
  		
  		var persist = Components.classes["@mozilla.org/embedding/browser/nsWebBrowserPersist;1"]
  											.createInstance(Components.interfaces.nsIWebBrowserPersist);
  		const nsIWBP = Components.interfaces.nsIWebBrowserPersist;
  		const flags = nsIWBP.PERSIST_FLAGS_REPLACE_EXISTING_FILES;
  		persist.persistFlags = flags | nsIWBP.PERSIST_FLAGS_FROM_CACHE;
  		persist.persistFlags |= nsIWBP.PERSIST_FLAGS_AUTODETECT_APPLY_CONVERSION;
  	
  		// Create download and initiate it (below)
  		var tr = Components.classes["@mozilla.org/transfer;1"].createInstance(Components.interfaces.nsITransfer);
  	  tr.init(uri, fileuri, name, null, null, null, persist);
  	  var listener = Components.classes["@mrtech.com/downloadlistener;1"]
  	  											.createInstance(Components.interfaces.nsIDownloadListener);
  	  listener.init(name,uri,file,tr);
  	  persist.progressListener = listener;
  	  persist.saveURI(uri, null, null, null, null, fileuri);
    }
    catch (e)
    {
      this.displayAlert("nightly.notemp.message",[name]);
      this.installFailed(name,uri);
    }
  }
},

installLocalExtension: function(name, uri, file)
{
  var guidTest = /^(\{[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\}|[a-z0-9-\._]*\@[a-z0-9-\._]+)\/?$/i;
  
	var directoryService = Components.classes["@mozilla.org/file/directory_service;1"].
										getService(Components.interfaces.nsIProperties);
  var ioService = Components.classes["@mozilla.org/network/io-service;1"]
                            .getService(Components.interfaces.nsIIOService);
  var rdfService = Components.classes["@mozilla.org/rdf/rdf-service;1"]
  											.getService(Components.interfaces.nsIRDFService);
	var appinfo = Components.classes['@mozilla.org/xre/app-info;1']
												.getService(Components.interfaces.nsIXULAppInfo);
	var vc = Components.classes["@mozilla.org/xpcom/version-comparator;1"]
                           .getService(Components.interfaces.nsIVersionComparator);
	
  // Find a temporary name for the rdf file.
	try
	{
  	var dir = directoryService.get("TmpD",Components.interfaces.nsIFile);
  	var i=0;
  	var rdffile;
		rdffile=dir.clone();
		rdffile.append("nightlytmp.rdf");
		rdffile.createUnique(Components.interfaces.nsILocalFile.NORMAL_FILE_TYPE, 0644); 
  }
  catch (e)
  {
    dump("Failed - "+e+"\n");
    this.displayAlert("nightly.notemp.message",[name]);
	  this.installFailed(name,uri);
	  return;
  }
  
	var source = rdfService.GetResource("urn:mozilla:install-manifest");
	var idprop = rdfService.GetResource("http://www.mozilla.org/2004/em-rdf#id");
	var targappprop = rdfService.GetResource("http://www.mozilla.org/2004/em-rdf#targetApplication");
	var minprop = rdfService.GetResource("http://www.mozilla.org/2004/em-rdf#minVersion");
	var maxprop = rdfService.GetResource("http://www.mozilla.org/2004/em-rdf#maxVersion");

  var zipReader;
  var originalID;
  var ds;
  
  try
  {
  	zipReader = Components.classes["@mozilla.org/libjar/zip-reader;1"]
  									.createInstance(Components.interfaces.nsIZipReader);
  	zipReader.init(file);
  	zipReader.open();

    try
    {
  	  // Extract the rdf file.
  		zipReader.extract("install.rdf", rdffile);
  		
  	  var fileuri=ioService.newFileURI(rdffile);
  
  		ds = rdfService.GetDataSourceBlocking(fileuri.spec);
  		originalID = ds.GetTarget(source,idprop,true);
  	}
  	catch (e)
  	{
  		dump("Failed - "+e+"\n");
  		zipReader.close();
      this.displayAlert("nightly.badrdf.message",[name]);
      this.installFailed(name,uri);
      return;
  	}
  }
  catch (e)
  {
		dump("Failed - "+e+"\n");
    this.displayAlert("nightly.badrdf.message",[name]);
    this.installFailed(name,uri);
    return;
  }

  if (ds)
  {
  	try
  	{
  		rdfService.UnregisterDataSource(ds);
  	}
  	catch (e) { }
  }
  
	// Read all we need, delete the rdf file but dont care if this fails.
	try
	{
		rdffile.remove(false);
	}
	catch (e) { }

  if (!originalID)
  {
		dump("Failed - "+e+"\n");
		zipReader.close();
    this.displayAlert("nightly.badrdf.message",[name]);
    this.installFailed(name,uri);
    return;
  }
  
	originalID=originalID.QueryInterface(Components.interfaces.nsIRDFLiteral);
	extensionID=originalID.Value;
	
  var simpleTest = /^[\w-\.]*$/;
	var em = Components.classes["@mozilla.org/extensions/manager;1"]
							.getService(Components.interfaces.nsIExtensionManager);

	if (!extensionID || !guidTest.test(extensionID))
	{
	  var invalid="@invalid-guid";
		if (simpleTest.test(extensionID))
		{
		  // Valid for simple @ form
			extensionID = extensionID+invalid;
		}
		else if (/^\{[\w-\.]*\}$/.test(extensionID))
		{
		  // Just a bad guid, convert for simple @ form
		  extensionID = extensionID.substring(1,extensionID.length-1)+invalid;
		}
		else
	  {
	    // TODO see if there is a sensible way to not use random behaviour.
	    do
	    {
  			extensionID = "extension-"+parseInt((Math.random()*10000))+invalid;
	      var testLoc = em.getInstallLocation(extensionID);
	      if (!testLoc)
	      {
	        break;
	      }
  		} while (true);
		}
    this.displayAlert("nightly.badguid.message",[name]);
	}

	var installLocation = em.getInstallLocation(extensionID);
	if (!installLocation)
	{
		installLocation = em.getInstallLocation("{9669CC8F-B388-42FE-86F4-CB5E7F5A8BDC}");
	}
	else
	{
	  // Might be nice to implement the level of safety that the EM uses when there is an old version in place.
	  var dest = installLocation.getItemLocation(extensionID);
	  /*if (dest.exists())
	    dest.remove(true);*/
	}
	
	var dest = installLocation.getItemLocation(extensionID);
				
	try
	{
    // create directories first
    var entries = zipReader.findEntries("*/");
    while (entries.hasMoreElements())
    {
      var entry = entries.getNext().QueryInterface(Components.interfaces.nsIZipEntry);
      var target = installLocation.getItemFile(extensionID, entry.name);
      if (!target.exists())
      {
        try
        {
          target.create(Components.interfaces.nsILocalFile.DIRECTORY_TYPE, 0755);
        }
        catch (e)
        {
        }
      }
    }

    entries = zipReader.findEntries("*");
    while (entries.hasMoreElements())
    {
      entry = entries.getNext().QueryInterface(Components.interfaces.nsIZipEntry);
      if (entry.name.substring(entry.name.length-1)!="/")
      {
        target = installLocation.getItemFile(extensionID, entry.name);
        try
        {
	        if (!target.exists())
	          target.create(Components.interfaces.nsILocalFile.NORMAL_FILE_TYPE, 0644);
        }
        catch (e)
        {
        }
        zipReader.extract(entry.name, target);
      }
    }
	}
	catch (e)
	{
		dump("Failed - "+e+"\n");
		zipReader.close();
		dest.remove(true);
    this.displayAlert("nightly.cannotwrite.message",[name]);
		this.installFailed(name,uri);
		return;
	}
	zipReader.close();
  
	var appid = appinfo.ID;
	var appversion = appinfo.version;
	try
	{
		appversion=prefservice.getCharPref("app.extensions.version");
		if (!appversion)
			appversion=appinfo.version;
	}
	catch (e) { }
	var versionliteral = rdfService.GetLiteral(appversion);
	
	try
	{
  	manifest=ioService.newFileURI(installLocation.getItemFile(extensionID, "install.rdf"));
  	ds = rdfService.GetDataSourceBlocking(manifest.spec);
  	
  	var changed=false;


	  if (extensionID!=originalID.Value)
	  {
		  ds.Change(source,idprop,originalID,rdfService.GetLiteral(extensionID));
		  changed = true;
	  }

  	var apps = ds.GetTargets(source,targappprop,true);
  	while (apps.hasMoreElements())
  	{
  		var appentry = apps.getNext();
  		var id = ds.GetTarget(appentry,idprop,true);
  		if (id)
  		{
  			id=id.QueryInterface(Components.interfaces.nsIRDFLiteral);
  			if (id.Value==appid)
  			{
  				var minv = ds.GetTarget(appentry,minprop,true).QueryInterface(Components.interfaces.nsIRDFLiteral);
  				var maxv = ds.GetTarget(appentry,maxprop,true).QueryInterface(Components.interfaces.nsIRDFLiteral);
  				
  				if (vc.compare(appversion,minv.Value)<0)
  				{
  					ds.Change(appentry,minprop,minv,versionliteral);
  					changed=true;
  				}
  				
  				if (vc.compare(appversion,maxv.Value)>0)
  				{
  					ds.Change(appentry,maxprop,maxv,versionliteral);
  					changed=true;
  				}
  			}
  		}
  	}
  	if (changed)
  	{
      ds.QueryInterface(Components.interfaces.nsIRDFRemoteDataSource);
      ds.Flush();
  	}
  	this.installSucceeded(name,uri);
  }
  catch (e)
  {
		dump("Failed - "+e+"\n");
		dest.remove(true);
    this.displayAlert("nightly.badrdf.message",[name]);
		this.installFailed(name,uri);
		return;
  }
},

QueryInterface: function(iid)
{
	if (iid.equals(Components.interfaces.nsINightlyToolsService)
		|| iid.equals(Components.interfaces.nsINightlyToolsCallback)
		|| iid.equals(Components.interfaces.nsISupports))
	{
		return this;
	}
	else
	{
		throw Components.results.NS_ERROR_NO_INTERFACE;
	}
}
}

var initModule =
{
	ServiceCID: Components.ID("9AA4A6B4-3A81-45F7-85E9-B257C10BB9F8"),
	ServiceContractID: "@mrtech.com/nightlytools;1",
	ServiceName: "MR Tech - Nightly Tester Tools Service",
	
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
			return nsNightlyToolsService.QueryInterface(iid);
		}
	}
}; //Module

function NSGetModule(compMgr, fileSpec)
{
	return initModule;
}
