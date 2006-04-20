/**
 * MHT Document Viewer Factory JS Component
 * ========================================
 *
 *  Description: This component register .mht(.mhtml) MimeType into Mozilla Firefox
 *
 *  Copyright (c) 2005 yuoo2k@gmail.com
 *
 *  This file is part of IE Tab. http://ietab.mozdev.org
 *
 *  This component is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This component is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this component; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 */

// Provides MHT Document Viewer Factory
const mhtMimeType = "application/x-mht";
const mhtViewerFactoryContractID = "@mozilla.org/content-viewer-factory/view;1?type="+mhtMimeType;
const mhtViewerFactoryCID = Components.ID("{3a31c9df-535b-4d1b-9203-37cc910c807c}");
const mhtViewerFactoryIID = Components.interfaces.nsIMhtViewerFactory;

var MhtViewerFactory = null;

function MhtViewerFactoryClass() { }

MhtViewerFactoryClass.prototype = {

  init: function(requestTarget) {
    this.requestTarget = requestTarget;
    this.addCategoryEntry();
    this.registerMimeType();
  },

  addCategoryEntry: function() {
    var catMan = Components.classes["@mozilla.org/categorymanager;1"].getService(Components.interfaces.nsICategoryManager);
    catMan.addCategoryEntry("Gecko-Content-Viewers", mhtMimeType, mhtViewerFactoryContractID, true, true);
  },

  getMimeTypeRdfFileURL: function() {
    var dirSrv = Components.classes["@mozilla.org/file/directory_service;1"].getService(Components.interfaces.nsIProperties);
    var rdfFile = dirSrv.get("UMimTyp", Components.interfaces.nsIFile);

    var ioSrv = Components.classes["@mozilla.org/network/io-service;1"].getService(Components.interfaces.nsIIOService);
    var fileHandler = ioSrv.getProtocolHandler("file").QueryInterface(Components.interfaces.nsIFileProtocolHandler);

    return fileHandler.getURLSpecFromFile(rdfFile);
  },

  registerMimeType: function() {
    const ncURI = "http://home.netscape.com/NC-rdf#";

    var gRDF = Components.classes["@mozilla.org/rdf/rdf-service;1"].getService(Components.interfaces.nsIRDFService);
    var gDS = gRDF.GetDataSourceBlocking(this.getMimeTypeRdfFileURL());

    var mimeSource = gRDF.GetUnicodeResource("urn:mimetype:"+mhtMimeType);

    var valueProperty = gRDF.GetUnicodeResource(ncURI+"value");
    var mimeLiteral = gRDF.GetLiteral(mhtMimeType);
    var currentValue = gDS.GetTarget(mimeSource, valueProperty, true);
    if (currentValue) {
      gDS.Change(mimeSource, valueProperty, currentValue, mimeLiteral);
    } else {
      gDS.Assert(mimeSource, valueProperty, mimeLiteral, true);
    }

    var fileExtsProperty = gRDF.GetUnicodeResource(ncURI+"fileExtensions");
    gDS.Assert(mimeSource, fileExtsProperty, gRDF.GetLiteral("mht"), true);
    gDS.Assert(mimeSource, fileExtsProperty, gRDF.GetLiteral("mhtml"), true);

    // add the mime type to the MIME types seq
    var container = Components.classes["@mozilla.org/rdf/container;1"].createInstance();
    if (container) {
      container = container.QueryInterface(Components.interfaces.nsIRDFContainer);
      if (container) {
        var containerRes = gRDF.GetUnicodeResource("urn:mimetypes:root");
        container.Init(gDS, containerRes);
        if (container.IndexOf(mimeSource) == -1) container.AppendElement(mimeSource);
      }
    }

    gDS.QueryInterface(Components.interfaces.nsIRDFRemoteDataSource).Flush();
  },

  createInstance: function(command, channel, loadGroup, contentType, container, extraInfo, docListenerResult) {
    this.requestTarget.loadIeTab(channel.URI.spec); //loadMHT()
    docListenerResult = null;
    return null;
  },

  createBlankDocument: function(loadGroup) {
    return null;
  },

  createInstanceForDocument: function(container, document, command) {
    return null;
  },

  QueryInterface: function(iid) {
    if (!iid.equals(Components.interfaces.nsIDocumentLoaderFactory) &&
        !iid.equals(mhtViewerFactoryIID) &&
        !iid.equals(Components.interfaces.nsISupports)) {
      throw Components.results.NS_ERROR_NO_INTERFACE;
    }
    return this;
  }
};

var MhtViewerFactoryFactory = new Object();

MhtViewerFactoryFactory.createInstance = function (outer, iid) {
  if (outer != null) {
    throw Components.results.NS_ERROR_NO_AGGREGATION;
  }

  if (!iid.equals(Components.interfaces.nsIDocumentLoaderFactory) &&
      !iid.equals(mhtViewerFactoryIID) &&
      !iid.equals(Components.interfaces.nsISupports)) {
    throw Components.results.NS_ERROR_NO_INTERFACE;
  }

  if (MhtViewerFactory == null) {
    MhtViewerFactory = new MhtViewerFactoryClass();
  }

  return MhtViewerFactory.QueryInterface(iid);
};


/**
 * XPCOM component registration
 */
var MhtViewerFactoryModule = new Object();

MhtViewerFactoryModule.registerSelf = function (compMgr, fileSpec, location, type) {
  compMgr = compMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar);
  compMgr.registerFactoryLocation(mhtViewerFactoryCID,
                                  "MHT Document Viewer Factory JS Component",
                                  mhtViewerFactoryContractID,
                                  fileSpec,
                                  location,
                                  type);
};

MhtViewerFactoryModule.getClassObject = function(compMgr, cid, iid) {
  if (!cid.equals(mhtViewerFactoryCID)) {
    throw Components.results.NS_ERROR_NO_INTERFACE;
  }

  if (!iid.equals(Components.interfaces.nsIFactory)) {
    throw Components.results.NS_ERROR_NOT_IMPLEMENTED;
  }

  return MhtViewerFactoryFactory;
};

MhtViewerFactoryModule.canUnload = function (compMgr) {
  return true;
};

function NSGetModule(compMgr, fileSpec) {
  return MhtViewerFactoryModule;
};
