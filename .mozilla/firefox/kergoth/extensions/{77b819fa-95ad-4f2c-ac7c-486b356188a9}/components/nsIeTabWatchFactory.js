/*
 * Copyright (c) 2005 yuoo2k <yuoo2k@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

const _IETABWATCH_CID = Components.ID('{3fdaa104-5988-4050-94fc-c711d568fe64}');
const _IETABWATCH_CONTRACTID = "@mozilla.org/ietabwatch;1";

// IeTabWatcher object
var IeTabWatcher = {
   getIeTabURL: function(url) {
      return "chrome://ietab/content/reloaded.html?url=" + url.replace(/\.\./g,"\\\\");
   },

   getCharPref: function(prefName, defval) {
      var result = defval;
      var prefservice = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefService);
      var prefs = prefservice.getBranch("");
      return (prefs.getPrefType(prefName) == prefs.PREF_STRING ? prefs.getCharPref(prefName) : result);
   },

   getBoolPref: function(prefName, defval) {
      var result = defval;
      var prefservice = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefService);
      var prefs = prefservice.getBranch("");
      return (prefs.getPrefType(prefName) == prefs.PREF_BOOL ? prefs.getBoolPref(prefName) : result);
   },

   isFilterEnabled: function() {
      return (this.getBoolPref("ietab.filter", true));
   },

   getPrefFilterList: function() {
      var s = this.getCharPref("ietab.filterlist", null);
      return (s ? s.split(" ") : "");
   },

   isMatchURL: function(url, pattern) {
      if ((!pattern) || (pattern.length==0)) return false;
      var retest = /^\/(.*)\/$/.exec(pattern);
      if (retest) {
         pattern = retest[1];
      } else {
         pattern = pattern.replace(/\\/, "\\\\");
         pattern = pattern.replace(/\./g, "\\.");
         pattern = pattern.replace(/\?/g, "\\?");
         pattern = pattern.replace(/\//g, "\\/");
         pattern = pattern.replace(/\*/g, ".*");
         pattern = "^" + pattern;
      }
      var reg = new RegExp(pattern);
      return (reg.test(url));
   },

   isMatchFilterList: function(url) {
      var aList = this.getPrefFilterList();
      for (var i=0; i<aList.length; i++) {
         if (this.isMatchURL(url, aList[i])) return(true);
      }
      return(false);
   }
}

// ContentPolicy class
var IeTabWatchFactoryClass = {
  // nsIContentPolicy interface implementation
  shouldLoad: function(contentType, contentLocation, requestOrigin, requestingNode, mimeTypeGuess, extra) {
    if (contentType == Components.interfaces.nsIContentPolicy.TYPE_DOCUMENT ||
        contentType == Components.interfaces.nsIContentPolicy.DOCUMENT) {
      // check IeTab FilterList
      if (IeTabWatcher.isFilterEnabled() && IeTabWatcher.isMatchFilterList(contentLocation.spec)) {
        contentLocation.spec = IeTabWatcher.getIeTabURL(contentLocation.spec); // load in IETab
      }
    }
    return (Components.interfaces.nsIContentPolicy.ACCEPT ?
            Components.interfaces.nsIContentPolicy.ACCEPT : true);
  },
  // this is now for urls that directly load media, and meta-refreshes (before activation)
  shouldProcess: function(contentType, contentLocation, requestOrigin, requestingNode, mimeType, extra) {
    return (Components.interfaces.nsIContentPolicy.ACCEPT ?
            Components.interfaces.nsIContentPolicy.ACCEPT : true);
  },
}

// Factory object
var IeTabWatchFactoryFactory = {
  createInstance: function(outer, iid) {
    if (outer != null) throw Components.results.NS_ERROR_NO_AGGREGATION;
    return IeTabWatchFactoryClass;
  },
}

// Module object
var IeTabWatchFactoryModule = {
  registerSelf: function(compMgr, fileSpec, location, type) {
    compMgr = compMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar);
    compMgr.registerFactoryLocation(_IETABWATCH_CID, "IETab content policy", _IETABWATCH_CONTRACTID, fileSpec, location, type);
    var catman = Components.classes["@mozilla.org/categorymanager;1"].getService(Components.interfaces.nsICategoryManager);
    catman.addCategoryEntry("content-policy", _IETABWATCH_CONTRACTID, _IETABWATCH_CONTRACTID, true, true);
  },

  unregisterSelf: function(compMgr, fileSpec, location) {
    compMgr = compMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar);
    compMgr.unregisterFactoryLocation(_IETABWATCH_CID, fileSpec);
    var catman = Components.classes["@mozilla.org/categorymanager;1"].getService(Components.interfaces.nsICategoryManager);
    catman.deleteCategoryEntry("content-policy", _IETABWATCH_CONTRACTID, true);
  },

  getClassObject: function(compMgr, cid, iid) {
    if (!cid.equals(_IETABWATCH_CID))
      throw Components.results.NS_ERROR_NO_INTERFACE;

    if (!iid.equals(Components.interfaces.nsIFactory))
      throw Components.results.NS_ERROR_NOT_IMPLEMENTED;

    return IeTabWatchFactoryFactory;
  },

  canUnload: function(compMgr) {
    return true;
  }
};

// module initialisation
function NSGetModule(comMgr, fileSpec) {
  return IeTabWatchFactoryModule;
}
