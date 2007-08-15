// Update Notifier
// By Todd Long <longfocus@gmail.com>
// http://www.longfocus.com/firefox/updatenotifier/

const UN_CC = Components.classes;
const UN_CI = Components.interfaces;
const UN_CS = UN_CC['@mozilla.org/consoleservice;1'].getService(UN_CI.nsIConsoleService);

const UN_BRANCH = "longfocus.updatenotifier.";
const UN_BUNDLE = "chrome://updatenotifier/locale/updatenotifier.properties";

const UN_NOTIFY_TOPIC = "UN:update-topic";
const UN_NOTIFY_TYPE_CHANGE = "UN:update-type-change";
const UN_NOTIFY_TYPE_BUSY_NONE = "UN:update-type-busy-none";
const UN_NOTIFY_TYPE_BUSY_CHECKING = "UN:update-type-busy-checking";
const UN_NOTIFY_TYPE_BUSY_DOWNLOAD = "UN:update-type-busy-download";
const UN_NOTIFY_TYPE_BUSY_INSTALL = "UN:update-type-busy-install";

const UN_ACTION_INSTALL = "UN:action-install";
const UN_ACTION_REMOVE = "UN:action-remove";
const UN_ACTION_UPDATE = "UN:action-update";

function unManager() {}
unManager.prototype = {
  _items: new Array(),
  _firstTime: true,
  _theme: "classic/1.0",
  _busyStatus: UN_NOTIFY_TYPE_BUSY_NONE,
  _newUpdate: false,
  
  get branch()
  {
    return UN_CC["@mozilla.org/preferences-service;1"]
             .getService(UN_CI.nsIPrefService)
             .getBranch(UN_BRANCH);
  },
  
  get bundle()
  {
    return UN_CC["@mozilla.org/intl/stringbundle;1"]
             .getService(UN_CI.nsIStringBundleService)
             .createBundle(UN_BUNDLE);
  },
  
  get restart()
  {
    var restart = false;
    
    for (var id in this._items) {
      if (this._items[id].needsRestart)
        restart = true;
    }
    
    return restart;
  },
  
  get status()
  {
    return this._busyStatus;
  },
  
  getItems: function(aCount)
  {
    var items = new Array();
    
    for (var id in this._items)
      items.push(this._items[id]);
    
    aCount.value = items.length;       
    
    return items;
  },
  
  getUpdateItems: function(aCount)
  {
    var items = new Array();
    
    for (var id in this._items) {
      if (this._items[id].newVersion != null)
        items.push(this._items[id]);
    }
    
    aCount.value = items.length;       
    
    return items;
  },
  
  load: function()
  {
    if (this._firstTime)
    {
      this._firstTime = false;
      
      this._em = UN_CC["@mozilla.org/extensions/manager;1"].getService(UN_CI.nsIExtensionManager);
      this._observer = UN_CC["@mozilla.org/observer-service;1"].getService(UN_CI.nsIObserverService);
      
      // Adds observers for item updates
      this._em.datasource.AddObserver(this);
      this._em.addUpdateListener(this);
      
      try {
        // Get theme in use
        this._theme = UN_CC["@mozilla.org/preferences-service;1"].getService(UN_CI.nsIPrefBranch).getCharPref("general.skins.selectedSkin");
      } catch(e) {}
      
      if (this.branch.getBoolPref("startup.check"))
        this.checkUpdates();
    }
    
    // Check RDF for available updates
    var res = this._em.datasource.GetAllResources();
    
    while (res.hasMoreElements())
    {
      var element = res.getNext().QueryInterface(UN_CI.nsIRDFResource);
      this._itemUpdateAction(this._em.datasource, element, UN_ACTION_UPDATE);
    }
    
    if (this._newUpdate)
      this._showAlert();
  },
  
  checkUpdates: function()
  {
    var items = this._em.getItemList(UN_CI.nsIUpdateItem.TYPE_ANY, {});
    this._em.update(items, items.length, false, this);
  },
  
  installUpdates: function()
  {
    var itemList = new Array();
    
    for (var id in this._items)
    {
      // Make sure Firefox hasn't already installed
      if (this._items[id].newVersion != null)
        itemList.push(this._em.getItemForID(id));
    }
    
    if (itemList.length > 0)
      this._em.addDownloads(itemList, itemList.length, true);
  },
  
  _itemUpdateAction: function(aDataSource, aSource, aAction, aOpType)
  {
    var arcLabelsOut = aDataSource.ArcLabelsOut(aSource);
    var curItem = this._em.getItemForID(aSource.Value.replace("urn:mozilla:item:", ""));
    var item = new unItem();
    var internalName = null;
    
    item.id = curItem.id;
    item.name = curItem.name;
    item.oldVersion = curItem.version;
    item.newVersion = null;
    item.opType = aOpType;
    item.needsRestart = true;
    
    switch (curItem.type)
    {
      case UN_CI.nsIUpdateItem.TYPE_EXTENSION:
        item.type = "extension";
        break;
      case UN_CI.nsIUpdateItem.TYPE_THEME:
        item.type = "theme";
        break;
      default: // Don't know, don't care
        return;
    }
    
    while(arcLabelsOut.hasMoreElements())
    {
      labelOut = arcLabelsOut.getNext().QueryInterface(UN_CI.nsIRDFResource);
      
      var target = aDataSource.GetTarget(aSource, labelOut, true);
      var rdfLiteral = null;
      
      if (target instanceof UN_CI.nsIRDFLiteral)
        rdfLiteral = target.Value;
      
      if (labelOut.Value.indexOf("#availableUpdateVersion") > -1)
        item.newVersion = rdfLiteral;
      else if (labelOut.Value.indexOf("#internalName") > -1)
        internalName = rdfLiteral;
    }
    
    switch (aAction)
    {
      case UN_ACTION_UPDATE:
      case UN_ACTION_INSTALL:
      {
        var isTheme = (item.type == "theme" && this._theme != internalName);
        
        if ((aAction == UN_ACTION_UPDATE || isTheme) && item.newVersion == null)
          return;
        
        if (item.newVersion != null)
          item.needsRestart = false;
        
        this._addItemUpdate(item);
        break;
      }
      case UN_ACTION_REMOVE:
      {
        this._removeItemUpdate(item);
        break;
      }
    }
  },
  
  _addItemUpdate: function(aItem)
  {
    // Check if item exists
    if (this._items[aItem.id])
    {
      // Check duplicate
      if (this._items[aItem.id].id == aItem.id &&
          this._items[aItem.id].name == aItem.name &&
          this._items[aItem.id].oldVersion == aItem.oldVersion &&
          this._items[aItem.id].newVersion == aItem.newVersion &&
          this._items[aItem.id].opType == aItem.opType)
        return;
    }
    
    if (aItem.newVersion != null && this.branch.getBoolPref("alerts"))
      this._newUpdate = true;
    
    // Add item
    this._items[aItem.id] = aItem;
    
    // Notify change
    this._observer.notifyObservers(null, UN_NOTIFY_TOPIC, UN_NOTIFY_TYPE_CHANGE);
  },
  
  _removeItemUpdate: function(aItem)
  {
    // Check if item exists
    if (this._items[aItem.id])
    {
      // Remove item
      delete this._items[aItem.id];
      
      // Notify change
      this._observer.notifyObservers(null, UN_NOTIFY_TOPIC, UN_NOTIFY_TYPE_CHANGE);
    }
  },
  
  _setBusyStatus: function(aStatus)
  {
    // Sets the status
    this._busyStatus = aStatus;
    
    // Notifies the status
    this._observer.notifyObservers(null, UN_NOTIFY_TOPIC, aStatus);
  },
  
  _showAlert: function()
  {
    this._newUpdate = false;
    
    UN_CC["@mozilla.org/embedcomp/window-watcher;1"]
      .getService(UN_CI.nsIWindowWatcher)
      .openWindow(null, "chrome://updatenotifier/content/alert.xul", "alerts", "chrome,dialog=yes,titlebar=no,popup=yes", null);
  },
  
  /**
   * nsIRDFObserver
   */
  onUnassert: function(aDataSource, aSource, aProperty, aTarget)
  {
    var pv = aProperty.QueryInterface(UN_CI.nsIRDFResource).Value;
    
    //UN_CS.logStringMessage("onUnassert - " + pv);
    
    if (pv.indexOf("#installLocation") > -1)
      this._itemUpdateAction(aDataSource, aSource, UN_ACTION_REMOVE);
  },
  
  onChange: function(aDataSource, aSource, aProperty, aOldTarget, aNewTarget)
  {
    var pv = aProperty.QueryInterface(UN_CI.nsIRDFResource).Value;
    var action = null;
    var opType = null;
    
    //UN_CS.logStringMessage("onChange - " + pv);
    
    if (pv.indexOf("#opType") > -1)
    {
      opType = aNewTarget.QueryInterface(UN_CI.nsIRDFLiteral).Value;
      
      //UN_CS.logStringMessage("opType - " + opType);
      
      if (opType == "none" || opType == "")
        action = UN_ACTION_UPDATE;
      else if (opType == "needs-uninstall")
        action = UN_ACTION_REMOVE;
      else if (opType == "needs-install" || opType == "needs-upgrade")
        action = UN_ACTION_INSTALL;
    }
    else if (pv.indexOf("#availableUpdateURL") > -1)
      action = UN_ACTION_UPDATE;
    
    if (action != null)
      this._itemUpdateAction(aDataSource, aSource, action, opType);
  },
  
  onAssert: function(aDataSource, aSource, aProperty, aTarget) {},
  onBeginUpdateBatch: function(aDataSource) {},
  onEndUpdateBatch: function(aDataSource) {},
  onMove: function(aDataSource, aOldSource, aNewSource, aProperty, aTarget) {},
  
  /**
   * nsIAddonUpdateCheckListener
   */
  onUpdateStarted: function() {
    this._setBusyStatus(UN_NOTIFY_TYPE_BUSY_CHECKING);
  },
  
  onUpdateEnded: function() {
    this._setBusyStatus(UN_NOTIFY_TYPE_BUSY_NONE);
    
    if (this._newUpdate)
      this._showAlert();
  },
  
  onAddonUpdateEnded: function(aAddon, aStatus) {},
  onAddonUpdateStarted: function(aAddon) {},
  
  /**
   * nsIAddonUpdateListener
   */
  onStateChange: function (aAddon, aState, aValue)
  {
    switch (aState)
    {
      case UN_CI.nsIXPIProgressDialog.DOWNLOAD_START: {
        this._setBusyStatus(UN_NOTIFY_TYPE_BUSY_DOWNLOAD);
        break;
      }
      case UN_CI.nsIXPIProgressDialog.INSTALL_START: {
        this._setBusyStatus(UN_NOTIFY_TYPE_BUSY_INSTALL);
        break;
      }
      case UN_CI.nsIXPIProgressDialog.DOWNLOAD_DONE:
      case UN_CI.nsIXPIProgressDialog.INSTALL_DONE: {
        this._setBusyStatus(UN_NOTIFY_TYPE_BUSY_NONE);
        break;
      }
      case UN_CI.nsIXPIProgressDialog.DIALOG_CLOSE:
        break;
    }
  },
  
  onProgress: function (aAddon, aValue, aMaxValue) {},
  
  QueryInterface: function(iid)
  {
    if (!iid.equals(UN_CI.unIManager) &&
        !iid.equals(UN_CI.nsIAddonUpdateCheckListener) &&
        !iid.equals(UN_CI.nsIAddonUpdateListener) &&
        !iid.equals(UN_CI.nsIObserver) &&
        !iid.equals(UN_CI.nsISupports))
      throw Components.results.NS_ERROR_NO_INTERFACE;
    return this;
  }
}

function unItem() {}
unItem.prototype = {
  _id: null,
  _name: null,
  _type: null,
  _oldVersion: null,
  _newVersion: null,
  _opType: null,
  _needsRestart: false,
  
  get id() { return this._id; },
  get name() { return this._name; },
  get type() { return this._type; },
  get oldVersion() { return this._oldVersion; },
  get newVersion() { return this._newVersion; },
  get opType() { return this._opType; },
  get needsRestart() { return this._needsRestart; },
  
  set id(aId) { this._id = aId; },
  set name(aName) { this._name = aName; },
  set type(aType) { this._type = aType; },
  set oldVersion(aVersion) { this._oldVersion = aVersion; },
  set newVersion(aVersion) { this._newVersion = aVersion; },
  set opType(aOpType) { this._opType = aOpType; },
  set needsRestart(aNeedsRestart) { this._needsRestart = aNeedsRestart; }
}

var myModule = {
  firstTime: true,
  
  myCID: Components.ID("{0090c2b0-9e45-11da-a746-0800200c9a66}"),
  myDesc: "Manager for Add-on updates",
  myProgID: "@longfocus.com/updatenotifier/manager;1",
  myFactory: {
    createInstance: function (outer, iid) {
      if (outer != null)
        throw Components.results.NS_ERROR_NO_AGGREGATION;
      
      return (new unManager()).QueryInterface(iid);
    }
  },

  registerSelf: function (compMgr, fileSpec, location, type)
  {
    if (this.firstTime) {
      this.firstTime = false;
      throw Components.results.NS_ERROR_FACTORY_REGISTER_AGAIN;
    }
    
    compMgr = compMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar);
    compMgr.registerFactoryLocation(this.myCID, this.myDesc, this.myProgID, fileSpec, location, type);
  },
 
  getClassObject: function (compMgr, cid, iid)
  {
    if (!cid.equals(this.myCID))
      throw Components.results.NS_ERROR_NO_INTERFACE;
    
    if (!iid.equals(Components.interfaces.nsIFactory))
      throw Components.results.NS_ERROR_NOT_IMPLEMENTED;
    
    return this.myFactory;
  },
  
  canUnload: function(compMgr) { return true; }
};

function NSGetModule(compMgr, fileSpec) { return myModule; }
