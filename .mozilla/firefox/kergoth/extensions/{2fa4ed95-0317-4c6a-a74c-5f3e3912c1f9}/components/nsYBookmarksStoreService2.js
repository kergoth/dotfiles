/*
 * Constants
 */

const nsIYBookmarksStoreService = Components.interfaces.
    nsIYBookmarksStoreService;
const nsISupports = Components.interfaces.nsISupports;

const CLASS_ID = Components.ID("{1ed70ced-0c94-4878-b7b5-64c51251a1cc}");
const TEST_CLASS_ID = Components.ID("{732f7148-80f3-403c-a33a-2f0acb54b5b0}");
const CLASS_NAME = "Access Local Bookmarks Store";
const TEST_CLASS_NAME = "Access Local Bookmarks Store (Test)";
const CONTRACT_ID = "@mozilla.org/ybookmarks-store-service;1";
const TEST_CONTRACT_ID = "@mozilla.org/ybookmarks-store-test-service;1";

var CC = Components.classes;
var CI = Components.interfaces;

const SOFAR_SEARCHED = 500;
const SEARCH_TIMEOUT = 50;

/*
 *
 *
 *       ----------------------
 *  --->| NC:YBookmarksTopRoot |
 * |     ----------------------
 * |
 * |      --------------------   contains    ----------------------   contains   ----------------------
 * |-----| NC:BookmarksRoot   |------------>|  Bookmark Sequence   | ---------->| bookmark resource    |  contains
 * |      --------------------              | (Anonymous resource) |            | (Anonymous resource) |<-------
 * |                                         ----------------------              ----------------------         |
 * |                                                                                                            |
 * |                                                                                                            |
 * |       ----------------------  contains    ---------------------   contains     ----------------------      |
 *  -----| NC:YBookmarksTagRoot |----------->| Tag Sequence         |------------->| Tag resource         |-----
 *         ----------------------            | (Anonymous resource) |              | (Anonymous resource) |
 *                                            ----------------------                ----------------------
 *
 *  All the relationships are stored in delicious.rdf
 *
 */

/**
 * Some documentation about bookmarks search
 *
 * Bookmarks search is divided into 2 parts:
 * 1. Searching bookmarks and,
 * 2. Searching tags.
 *
 * In both cases when search begins, all the observers for
 * "ybookmarkSearch.begin" topic is notified
 * with "tags" or "bookmarks" as the data. Subject is a javascript object
 * having wrappedJSObject property set.
 *
 * Subject object is having the following properties.
 *
 *  type: "bookmarks" or "tags" depending on the type of search.
 *  keyword: keyword being searched for.
 *
 * During the search, all the observers for "ybookmarkSearch.inProgress" topic
 * are notified with "tags" or "bookmarks" as the data. Subject of the
 * notification is a javascript object having wrappedJSObject property set.
 *
 * Following are the fields for the subject object.
 *
 *  type: "bookmarks" or "tags" depending on the type of search.
 *  keyword: keyword being searched for.
 *  objectTotal: total number of objects to search, total bookmarks when
 *      type is "bookmarks" and total tags to search when type is "tags".
 *  total: total number of bookmarks and tags being searched. This can be used
 *      for calculating any the percentage of search completed,
 *      being used by ybSidebarOverlay.xml to show the progress of search.
 *  sofar: This has the number of objects done searching for. Again this is
 *      number of bookmarks done searching for when type is "bookmarks" and
 *      number of tags done searching for when type is "tags".
 *
 * At the end of search all the observers for "ybookmarkSearch.end" topic is
 * notified with "tags" or "bookmarks" as the data. Subject of the notification
 * is a javascript object having wrappedJSObject property set.
 *
 * Following are the fields of the subject object.
 *
 *  type: "tags" or "bookmarks" depending on the type of search.
 *  keyword: keyword being searched for.
 *  totalMatched: total number of objects matched. Total number of bookmarks
 *      matched the keyword when type is "bookmarks" and total number of tags
 *      matched when type if "tags".
 *
 *
 *
 * Bundles
 * =======
 * Bundles contain tag arcs and order arcs
 *
 *
 * Favorite Tags
 * =============
 * Favorite tags contain the favoriteTagValue, order, and a ordered sequence of 
 * bookmark resources.
 *
 * The ordered bookmark resources are to support aribtrary/user-defined order for the bookmarks 
 * within the Favorite Tag. Obvously, this may lead to some bookkeeping troubles maintaining the correct
 * bookmarks within the Favorite Tag resource. As of Febuary 2007, we don't actually show this 
 * functionality in the  UI, but the support is there.  On resync, we clear out the bookmark sequence 
 * with the Favorite Tag, but not the Faorite Tag resource or the order, since this data is not stored 
 * on the server. The sync then takes care of rebuilding the bookmarks sequence.
 *
 */

const kHashPropertyBagContractID = "@mozilla.org/hash-property-bag;1";
const kIWritablePropertyBag = Components.interfaces.nsIWritablePropertyBag;
const HashPropertyBag = new Components.Constructor(kHashPropertyBagContractID,
                                                   kIWritablePropertyBag);

const kMutableArrayContractID = "@mozilla.org/array;1";
const kIMutableArray = Components.interfaces.nsIMutableArray;
const NSArray = new Components.Constructor(kMutableArrayContractID,
                                           kIMutableArray);

const kStringContractID = "@mozilla.org/supports-string;1";
const kIString = Components.interfaces.nsISupportsString;
const NSString = new Components.Constructor(kStringContractID, kIString);

const kMicrosummaryContractID = "@mozilla.org/microsummary/service;1";
const kIMicrosummaryService = Components.interfaces.nsIMicrosummaryService;

const kIOContractID = "@mozilla.org/network/io-service;1";
const kIOIID = CI.nsIIOService;
const IOSVC = CC[kIOContractID].getService(kIOIID);

const kRSS10_NAMESPACE_URI = "http://purl.org/rss/1.0/";
const kRSS09_NAMESPACE_URI = "http://my.netscape.com/rdf/simple/0.9/";

// Resource Namespaces
var gRdfService = CC["@mozilla.org/rdf/rdf-service;1"].
                      getService(Components.interfaces.nsIRDFService);
var gRdfContainerUtils = CC["@mozilla.org/rdf/container-utils;1"].
                        getService(CI.nsIRDFContainerUtils);

const NS_TRANSACTION_BASE = "http://www.mozilla.org/transaction#";
const NS_BOOKMARK_BASE = "http://www.mozilla.org/bookmark#";
const NS_TAG_BASE = "http://www.mozilla.org/tags#";
const NS_BUNDLE_BASE = "http://www.mozilla.org/bundles#";
const NS_FAVORITETAG_BASE = "http://www.mozilla.org/favoritetag#";
const gNC_NS     = "http://home.netscape.com/NC-rdf#";
const gRDF_NS    = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
const gWEB_NS    = "http://home.netscape.com/WEB-rdf#";

const TAGS = "tags";
const BOOKMARKS = "bookmarks";
// namespaces

var grscTopRoot = gRdfService.GetResource("NC:YBookmarksTopRoot");
var grscBookmarksRoot = gRdfService.GetResource("NC:BookmarksRoot");
var grscTagRoot = gRdfService.GetResource("NC:YBookmarksTagRoot");
var grscFavoriteTagsRoot = gRdfService.GetResource(
    "NC:YBookmarksFavoriteTagsRoot");
var grscFeedRoot = gRdfService.GetResource("NC:YBookmarksFeedRoot");
var grscTransactionRoot = gRdfService.GetResource(
    "NC:YBookmarksTransactionRoot");
var grscBundleRoot = gRdfService.GetResource("NC:YBookmarksBundleRoot");

var grscName = gRdfService.GetResource(gNC_NS + "Name");
var grscUrl = gRdfService.GetResource(gNC_NS + "URL");
var grscShortcut = gRdfService.GetResource(gNC_NS + "ShortcutURL");
var grscPostData = gRdfService.GetResource(gNC_NS + "PostData");
var grscFeedUrl = gRdfService.GetResource(gNC_NS + "FeedURL");
var grscLocked = gRdfService.GetResource(gNC_NS + "Locked");
var grscLivemarkExpiration = gRdfService.GetResource(gNC_NS + "Expiration");
var grscIcon = gRdfService.GetResource(gNC_NS + "Icon");
var grscDesc = gRdfService.GetResource(gNC_NS + "Description");
var grscWebPanel = gRdfService.GetResource(gNC_NS + "WebPanel");
var grscCharset = gRdfService.GetResource(gWEB_NS + "LastCharset");
var grscAddDate = gRdfService.GetResource(gNC_NS + "BookmarkAddDate");
var grscDate = gRdfService.GetResource(gNC_NS + "Date");
var grscPage = gRdfService.GetResource(gNC_NS + "Page");
var grscReferrer = gRdfService.GetResource(gNC_NS + "Referrer");
var grscVisitCount = gRdfService.GetResource(gNC_NS + "VisitCount");
var grscChildCount = gRdfService.GetResource(gNC_NS + "ChildCount");
var grscSync = gRdfService.GetResource(gNC_NS + "Sync");
var grscLastModifiedDate = gRdfService.GetResource(gWEB_NS
    + "LastModifiedDate");
var grscLastVisitDate = gRdfService.GetResource(gWEB_NS + "LastVisitDate");
var grscLastUpdateDate = gRdfService.GetResource(gNC_NS + "LastUpdateDate");
var grscType = gRdfService.GetResource(gRDF_NS + "type");
var grscBookmarkType = gRdfService.GetResource(gNC_NS + "Bookmark");
var grscLivemarkType = gRdfService.GetResource(gNC_NS + "Livemark");
var grscLiveBookmarkType = gRdfService.GetResource(gNC_NS + "LiveBookmark");
var grscHash = gRdfService.GetResource(NS_BOOKMARK_BASE + "hash");
var grscMetaHash = gRdfService.GetResource(NS_BOOKMARK_BASE + "metahash");
var grscTag = gRdfService.GetResource(NS_BOOKMARK_BASE + "tag");
var grscTagValue = gRdfService.GetResource(NS_BOOKMARK_BASE + "tagvalue");
var grscFavoriteTag = gRdfService.GetResource(NS_FAVORITETAG_BASE + "favoriteTag");
var grscFavoriteTagValue = gRdfService.GetResource(NS_FAVORITETAG_BASE
    + "favoriteTagValue");
var grscFavoriteTagOrder = gRdfService.GetResource(NS_FAVORITETAG_BASE
    + "favoriteTagOrder");
var grscShared = gRdfService.GetResource(NS_BOOKMARK_BASE + "shared");
var grscLocalOnly = gRdfService.GetResource(NS_BOOKMARK_BASE + "localonly");
var grscBookmark = gRdfService.GetResource(NS_BOOKMARK_BASE + "bookmark");
var grscState = gRdfService.GetResource(NS_TRANSACTION_BASE +
      "transactionState");
var grscTime = gRdfService.GetResource(NS_TRANSACTION_BASE + "transactionTime");
var grscBundleValue = gRdfService.GetResource(NS_BUNDLE_BASE + "BundleValue");
var grscBundleOrder = gRdfService.GetResource(NS_BUNDLE_BASE + "BundleOrder");

var grscRSS09Item = gRdfService.GetResource(kRSS09_NAMESPACE_URI + "item");
var grscRSS09Channel = gRdfService.GetResource(kRSS09_NAMESPACE_URI
  + "channel");
var grscRSS09Title = gRdfService.GetResource(kRSS09_NAMESPACE_URI + "title");
var grscRSS09Link = gRdfService.GetResource(kRSS09_NAMESPACE_URI + "link");

var grscRSS10Items = gRdfService.GetResource(kRSS10_NAMESPACE_URI + "items");
var grscRSS10Channel = gRdfService.GetResource(kRSS10_NAMESPACE_URI
  + "channel");
var grscRSS10Title = gRdfService.GetResource(kRSS10_NAMESPACE_URI + "title");
var grscRSS10Link = gRdfService.GetResource(kRSS10_NAMESPACE_URI + "link");

var glitTrue = gRdfService.GetLiteral("true");

const nsTimer = "@mozilla.org/timer;1";
const nsITimer = Components.interfaces.nsITimer;
const nsPreferences = "@mozilla.org/preferences-service;1";
const nsIPrefBranch = Components.interfaces.nsIPrefBranch;
const nsIPrefBranch2 = Components.interfaces.nsIPrefBranch2;
const kPrefChangeTopic = "nsPref:changed";

const PREF_PREFIX = "extensions.ybookmarks@yahoo";
const PREF_FLUSH_TIMER = PREF_PREFIX + ".flush.timer";

const FAVTAG_ORDER_CHRONO = "chrono";
const FAVTAG_ORDER_CHRONO_REVERSE = "chrono_reverse";
const FAVTAG_ORDER_ALPHANUM = "alphanum";
const FAVTAG_ORDER_ALPHANUM_REVERSE = "alphanum_reverse";
const FAVTAG_ORDER_DEFAULT = FAVTAG_ORDER_CHRONO_REVERSE;

// default Flush timer is 5 minutes
const DEFAULT_FLUSH_TIMER = 1;

/**********************************************************
 * Load yDebug.js
 **********************************************************/
((Components.classes["@mozilla.org/moz/jssubscript-loader;1"]).getService(
     Components.interfaces.mozIJSSubScriptLoader)).loadSubScript(
        "chrome://ybookmarks/content/yDebug.js");

/**********************************************************
 * Load ybookmarksUitl.js
 **********************************************************/
((Components.classes["@mozilla.org/moz/jssubscript-loader;1"]).getService(
     Components.interfaces.mozIJSSubScriptLoader)).loadSubScript(
        "chrome://ybookmarks/content/ybookmarksUtils.js");

var gResourceMap = {
  name: grscName,
  description: grscDesc,
  shared: grscShared,
  shortcut: grscShortcut,
  postData: grscPostData,
  localOnly: grscLocalOnly  
};

var trace = false;
var rethrow = false;

function traceIn(name) {
  if (trace) {
    yDebug.print("In: " + name);
  }
}

function traceOut(name) {
  if (trace) {
    yDebug.print("Out: " + name);
  }
}

function logError(name, e) {
  yDebug.print("Error in " + name + ": " + e, YB_LOG_MESSAGE);
  if (rethrow) {
    throw e;
  }
}

function newLivemarkChild(datasource, title, url)
{
  var source = gRdfService.GetAnonymousResource();
  datasource.Assert(source, grscType, grscLiveBookmarkType, true);
  datasource.Assert(source, grscUrl, gRdfService.GetLiteral(url), true);
  datasource.Assert(source, grscName, gRdfService.GetLiteral(title),
    true);
  return source;
}

function emptyContainer(container) {
      var contents = container.GetElements();
      var length = 0;
      while (contents.hasMoreElements()) {
        length++;
        contents.getNext();
      }

      for (var i = length; i > 0; --i) {
        container.RemoveElementAt(i, true);
      }    
}

function FeedListener(datasource, livemarkContainer, channel, uri) {
  this._datasource = datasource;
  this._livemarkContainer = livemarkContainer;
  this._channel = channel;
  this._uri = uri;
  this._countRead = 0;
}

FeedListener.prototype = {
  _uri : null,
  _datasource : null,
  _livemarkContainer : null,
  _countRead : null,
  _channel : null,
  _data : Array(),
  _stream : null,

  QueryInterface: function (iid) {
    if (!iid.equals(Components.interfaces.nsISupports) &&
        !iid.equals(Components.interfaces.nsIInterfaceRequestor) &&
        !iid.equals(Components.interfaces.nsIRequestObserver) &&
        !iid.equals(Components.interfaces.nsIChannelEventSink) &&
        !iid.equals(Components.interfaces.nsIProgressEventSink) && // see below
        !iid.equals(Components.interfaces.nsIWebProgress) && // see below
        !iid.equals(Components.interfaces.nsIStreamListener)) {
      throw Components.results.NS_ERROR_NO_INTERFACE;
    }
    return this;
  },

  // nsIProgressEventSink: the only reason we support
  // nsIProgressEventSink is to shut up a whole slew of xpconnect
  // warnings in debug builds.  (see bug #253127)
  onProgress : function (aRequest, aContext, aProgress, aProgressMax) { },
  onStatus : function (aRequest, aContext, aStatus, aStatusArg) { },
  addProgressListener : function(listener , notifyMask ) { },
  removeProgressListener : function(listener) { },


  // nsIInterfaceRequestor
  getInterface: function (iid) {
    try {
      return this.QueryInterface(iid);
    } catch (e) {
      throw Components.results.NS_NOINTERFACE;
    }
  },

  // nsIRequestObserver
  onStartRequest : function (aRequest, aContext) {
    this._stream = CC['@mozilla.org/binaryinputstream;1'].
      createInstance(CI.nsIBinaryInputStream);
  },

  onStopRequest : function (aRequest, aContext, aStatusCode) {
    try {
      if (aStatusCode != 0) {
        emptyContainer(this._livemarkContainer);
        this._livemarkContainer.AppendElement(
          newLivemarkChild(this._datasource, "Update failed", "about:livemarks"));
        yDebug.print("Livemark " + this._uri + " not updated as statusCode is " + aStatusCode);
      } else {
        this._datasource.beginUpdateBatch();
        emptyContainer(this._livemarkContainer);

        var p = CC["@mozilla.org/xmlextras/domparser;1"].
            createInstance(CI.nsIDOMParser);      
        var doc = p.parseFromBuffer(this._data, this._countRead, "text/xml");    

        if (!this._trySimpleRss(doc) && !this._tryAsRDF(doc)) {
            this._livemarkContainer.AppendElement(
              newLivemarkChild(this._datasource, "Update failed",
                "about:livemarks"));
            yDebug.print("Livemark " + this._uri + " not updated as both rdf and rss parsing failed");
        } else {
            yDebug.print("Livemark " + this._uri + " updated");
        }
        this._datasource.endUpdateBatch();
        var ttl = 3600 * 1000; // By default reload after 1 hour.

        var channel = aRequest.QueryInterface(CI.nsICachingChannel);
        if (channel) {
            var cei = channel.cacheToken.QueryInterface(CI.nsICacheEntryInfo);
            if (cei) {
                var now = new Date();
                yDebug.print("cei.expirationTime : " + cei.expirationTime + ", now : " + now.getTime());
                var expirationTime = (1000 * cei.expirationTime) - now.getTime();
                if (expirationTime > ttl) {
                    ttl = expirationTime;
                }
            }
        }
        var t = gRdfService.GetDateLiteral(new Date(now.getTime() + ttl));
        var old = this._datasource.GetTarget(this._livemarkContainer.Resource,
        grscLivemarkExpiration, true);
        if (old) {
            this._datasource.Change(this._livemarkContainer.Resource,
                grscLivemarkExpiration, old, t, true);
        } else {
            this._datasource.Assert(this._livemarkContainer.Resource,
                grscLivemarkExpiration, t, true);
        }

        this._channel = null;
      }
    } catch (e) {
      logError("onStopRequest(" + this._uri + ")", e);
    } finally {
      this._datasource.Unassert(this._livemarkContainer.Resource,
        grscLocked, glitTrue, true);
    }
  },

  // nsIStreamObserver
  onDataAvailable : function (aRequest, aContext, aInputStream,
    aOffset, aCount) {
    try {
        this._stream.setInputStream(aInputStream);
        var chunk = this._stream.readByteArray(aCount);
        this._data = this._data.concat(chunk);
        this._countRead += aCount;
    } catch (e) {
      logError("onDataAvailable", e);
    }
  },

  // nsIChannelEventSink
  onChannelRedirect : function (aOldChannel, aNewChannel, aFlags) {
    this._channel = aNewChannel;
  },

  _tryAsRDF : function(doc) {
    yDebug.print("_tryAsRDF");
  
    var serializer = Components.classes["@mozilla.org/xmlextras/xmlserializer;1"]
        .createInstance(Components.interfaces.nsIDOMSerializer);
    var xmlString=serializer.serializeToString(doc.documentElement);
    var ds = CC["@mozilla.org/rdf/datasource;1?name=in-memory-datasource"].
      createInstance(CI.nsIRDFDataSource);
    var rdfXmlParser = CC["@mozilla.org/rdf/xml-parser;1"].
      createInstance(CI.nsIRDFXMLParser);
    var uri = CC["@mozilla.org/network/io-service;1"].
      getService(CI.nsIIOService).newURI(this._uri, null, null);
    rdfXmlParser.parseString(ds, uri, xmlString);
    var channelResource = ds.GetSource(grscType, grscRSS10Channel, true);
    if (channelResource) {
      return this._processRDF10(ds, channelResource);
    } else {
      channelResource = ds.GetSource(grscType, grscRSS09Channel, true);
      if (channelResource) {
        return this._processRDF09(ds, channelResource);
      }
      return false;
    }
  },

  _processRDF10 : function(datasource, channelResource) {
    var itemsNode = datasource.GetTarget(channelResource, grscRSS10Items, true);
    if (itemsNode) {
      this._populateChildren(datasource,
        gRdfContainerUtils.MakeSeq(datasource, itemsNode).GetElements(),
        grscRSS10Title, grscRSS10Link);
      return true;
    }
    return false;
  },

  _processRDF09 : function(datasource, channelResource) {
    this._populateChildren(datasource,
      datasource.GetSources(grscType, grscRSS09Item, true),
      grscRSS09Title, grscRSS09Link);
    return true;
  },

  _populateChildren : function(datasource, enumerator,
    titleResource, linkResource) {
    while (enumerator.hasMoreElements()) {
      var r = enumerator.getNext().QueryInterface(CI.nsIRDFResource);
      var title = datasource.GetTarget(r, titleResource, true);
      var link = datasource.GetTarget(r, linkResource, true);
      if (title && link) {
        this._newLivemarkBookmark(title.QueryInterface(CI.nsIRDFLiteral).Value,
          link.QueryInterface(CI.nsIRDFLiteral).Value);
      }
    }
  },

  _trySimpleRss : function(doc) {
    yDebug.print("_trySimpleRss");
    
    if (! doc.documentElement) {
      return false;
    }
    var lookingForChannel = false;
    var node = doc.firstChild;
    var isAtom = false;
    while (node) {
      if (node.nodeType == CI.nsIDOMNode.ELEMENT_NODE) {
        var name = node.nodeName;
        if (lookingForChannel) {
          if (name == "channel") {
            break;
          }
        } else {
          if (name == "rss") {
            node = node.firstChild;
            lookingForChannel = true;
            continue;
          } else if (name == "feed") {
            isAtom = true;
            break;
          }
        }
      }
      node = node.nextSibling;
    }

    if (! node) {
      return false;
    }
    var chElement = node.QueryInterface(CI.nsIDOMElement);

    node = chElement.firstChild;
    while (node) {
      if (node.nodeType == CI.nsIDOMNode.ELEMENT_NODE) {
        name = node.nodeName;
        if (isAtom && (name == "entry")) {
          this._processEntry(node);
        } else if (!isAtom && (name == "item")) {
          this._processItem(node);
        }
      }
      node = node.nextSibling;
    }
    return true;
  },

  _processEntry : function(node) {
    // TODO: Implement handler for feeds. (rather than channels)
    var titleString = "", dateString = "", linkString = "";

    var childNode = node.firstChild;
    while (childNode) {
      if (childNode.nodeType == CI.nsIDOMNode.ELEMENT_NODE) {
        childNode.QueryInterface(CI.nsIDOMElement);
        var childName = childNode.nodeName;
        if (childName == "title") {
          var titleMode = childNode.getAttribute("mode");
          var titleType = childNode.getAttribute("type");
          if (titleMode == "base64") {
            // No one does this in <title> except standards pendats making
            // test feeds, Atom 0.3 is deprecated and RFC 4287 doesn't allow it
            break;
          } else if ((titleType == "text")
            || (titleType == "text/plain")
            || ! titleType) {
            titleString = this._getTextContents(childNode);
          } else if ((titleType == "html")
            || ((titleType == "text/html") && (titleType != "xml"))
            || (titleMode == "escaped")) {
              titleString = this._getTextContents(childNode);
          } else if ((titleType == "xhtml")
            || (titleType == "application/xhtml")
            || (titleMode == "xml")) {
            titleString = this._getTextContents(childNode);
          } else {
            titleString = this._getTextContents(childNode);
          }
        } else if (childName == "link" && !linkString) {
          var rel = childNode.getAttribute("rel");
          if (! rel || rel == "alternate") {
            linkString = childNode.getAttribute("href");
          }
        } else if (!dateString &&
          ((childName == "pubDate") || (childName == "updated"))) {
            dateString = this._getTextContents(childNode);
        }
      }

      childNode = childNode.nextSibling;
    }
    if (! titleString && dateString) {
      titleString = dateString;
    }

    if (titleString && linkString) {
      this._newLivemarkBookmark(titleString, linkString);
    }

  },

  _processItem : function(node) {
    var titleString = "", dateString = "", linkString = "";

    var childNode = node.firstChild;
    while (childNode) {
      if (childNode.nodeType == CI.nsIDOMNode.ELEMENT_NODE) {
        childNode.QueryInterface(CI.nsIDOMElement);
        var childName = childNode.nodeName;
        if (childName == "title") {
          titleString = this._getTextContents(childNode);
        } else if (childName == "link" && !linkString) {
          linkString = this._getTextContents(childNode);
        } else if (childName == "guid" && !linkString) {
          if (childNode.getAttribute("isPermaLink") != "false") {
            linkString = this._getTextContents(childNode);
          }
        } else if (!dateString &&
          ((childName == "pubDate") || (childName == "updated"))) {
            dateString = this._getTextContents(childNode);
        }
      }

      childNode = childNode.nextSibling;
    }
    if (! titleString && dateString) {
      titleString = dateString;
    }

    if (titleString && linkString) {
      this._newLivemarkBookmark(titleString, linkString);
    }

  },

  _newLivemarkBookmark : function(titleString, linkString) {
    this._livemarkContainer.AppendElement(
      newLivemarkChild(this._datasource, titleString, linkString));
  },

  _getTextContents : function(node) {
    var result = "";
    var doc = node.ownerDocument;
    doc.QueryInterface(CI.nsIDOMDocumentTraversal);
    var treeWalker = doc.createTreeWalker(node,
      CI.nsIDOMNodeFilter.SHOW_TEXT | CI.nsIDOMNodeFilter.SHOW_CDATA_SECTION,
      null, true);
    var curNode = treeWalker.currentNode;
    while (curNode) {
      try {
        curNode.QueryInterface(CI.nsIDOMCharacterData);
        result += curNode.data;
      } catch (e) {
      }
      curNode = treeWalker.nextNode();
    }
    return result;
  }
}

/* Class definition */

function YBookmarksStoreService(filename) {
  this._init(filename);
  this.wrappedJSObject = this;
}

YBookmarksStoreService.prototype = {
  _searchDatasource : null, // Search datasource which holds the search results

  /**
   * Local delicious datasource to store data.
   */

  _datasource : null,
  _fileDatasource : null,
  _memoryDatastore : null,
  /**
   * Useful for debugging.
   */
  _dumpChildren : function(parent, label) {
    var it = this._datasource.ArcLabelsOut(parent);
    while (it.hasMoreElements()) {
      var c = it.getNext().QueryInterface(CI.nsIRDFResource);
      var v = this._datasource.GetTarget(parent, c, true);
      try {
        v = "Resource = " + v.QueryInterface(CI.nsIRDFResource).Value;
      } catch (e) {
        try {
          v = "Literal = " + v.QueryInterface(CI.nsIRDFLiteral).Value;
        } catch (e) {
          v = "Neithe a resource nor a literal";
        }
      }
      yDebug.print(label + ": " + c.Value + " " + v);
    }
  },

  _tagRoot : null,
  _getTagRoot : function() {
    if (! gRdfContainerUtils.IsSeq(this._fileDatasource, grscTagRoot)) {
      yDebug.print("No longer a seq: " + grscTagRoot.Value);
    }
    return this._tagRoot;
  },
  _bookmarkRoot : null,
  _getBookmarkRoot : function() {
    if (! gRdfContainerUtils.IsSeq(this._fileDatasource, grscBookmarksRoot)) {
      yDebug.print("No longer a seq: " + grscBookmarksRoot.Value);
    }
    return this._bookmarkRoot;
  },
  _transactionRoot : null,
  _feedsRoot : null,
  _favoriteTagsRoot : null,

  _allowDeleteAllBookmarks : false,  //should we delete all bookmarks?

  _timer : null,
  _flushPending : false,
  _hiddenWindow : null,
  _isTagSearching : false,
  _isBookmarkSearching : false,
  _tagSearchTimeout : null,
  _bookmarkSearchTimeout : null,
  _stopBookmarkSearching : false,
  _stopTagSearching : false,

  _initDatasource : function(filename) {
    this._datasource = CC[
      "@mozilla.org/rdf/datasource;1?name=composite-datasource"].
      createInstance(CI.nsIRDFCompositeDataSource);
    this._fileDatasource = CC[
      "@mozilla.org/rdf/datasource;1?name=xml-datasource"].
      createInstance(CI.nsIRDFRemoteDataSource);
    this._fileDatasource.QueryInterface(CI.nsIRDFDataSource);
    this._memoryDatastore = CC[
      "@mozilla.org/rdf/datasource;1?name=in-memory-datasource"].
      createInstance(CI.nsIRDFDataSource);

    try {
      this._fileDatasource.Init(this._getProfileFilePath(filename));
    } catch (e) {
        yDebug.print("Error in initializing RDF: " + e);
    }

    try {
      this._fileDatasource.Refresh(true);
    } catch (e) {
        yDebug.print("Error in refreshing RDF: " + e);
    }

    /**
     * Note: The order is important. The changes that happen to the composite
     * datasource are tried in the last to first order.
     */
    this._datasource.AddDataSource(this._memoryDatastore);
    this._datasource.AddDataSource(this._fileDatasource);

  },

  _initRoots : function() {
    var result = false;
    if (! gRdfContainerUtils.IsSeq(this._fileDatasource, grscBookmarksRoot)
      || ! gRdfContainerUtils.IsSeq(this._fileDatasource, grscTagRoot)
      || ! gRdfContainerUtils.IsSeq(this._fileDatasource, grscFavoriteTagsRoot)
      || ! gRdfContainerUtils.IsSeq(this._fileDatasource, grscFeedRoot)
      || ! gRdfContainerUtils.IsSeq(this._fileDatasource, grscBundleRoot)
      || ! gRdfContainerUtils.IsSeq(this._fileDatasource, grscTransactionRoot)) {
      result = true;
    }
    this._bookmarkRoot = gRdfContainerUtils.MakeSeq(this._fileDatasource,
      grscBookmarksRoot);
    this._tagRoot = gRdfContainerUtils.MakeSeq(this._fileDatasource, grscTagRoot);
    this._favoriteTagsRoot = gRdfContainerUtils.MakeSeq(this._fileDatasource,
      grscFavoriteTagsRoot);
    this._feedsRoot = gRdfContainerUtils.MakeSeq(this._fileDatasource,
      grscFeedRoot);
    this._bundleRoot = gRdfContainerUtils.MakeSeq(this._fileDatasource,
      grscBundleRoot);
    this._transactionRoot = gRdfContainerUtils.MakeSeq(this._fileDatasource,
      grscTransactionRoot);

    // add top root which contains both bookmarks root and tag root
    if (! gRdfContainerUtils.IsSeq(this._fileDatasource, grscTopRoot)) {
      var topRoot = gRdfContainerUtils.MakeSeq(this._fileDatasource, grscTopRoot);
      topRoot.AppendElement(grscBookmarksRoot);
      topRoot.AppendElement(grscTagRoot);
      topRoot.AppendElement(grscFavoriteTagsRoot);
      topRoot.AppendElement(grscFeedRoot);
      topRoot.AppendElement(grscBundleRoot);
      topRoot.AppendElement(grscTransactionRoot);
      result = true;
    }

    return result;
  },

  _updateLivemarks : function() {
    yDebug.print("Livemarks being updated...");
    var contents = this._feedsRoot.GetElements();
    while (contents.hasMoreElements()) {
      var bookmark = contents.getNext().QueryInterface(CI.nsIRDFResource);
      this._updateLivemarkChildren(bookmark);
    }
    // Refresh every 5 minutes.
    this._hiddenWindow.setTimeout(function (self) { self._updateLivemarks(); },
      5 * 60 * 1000, this);
  },

  _updateLivemarkChildren : function(resource) {
    try {
      var srcDatasource = this._fileDatasource;
      var dstDatasource = this._memoryDatastore;        
      if (dstDatasource.HasAssertion(resource, grscLocked, glitTrue, true)) {
        return;   // Already loading.
      }
      var feedUrl = srcDatasource.GetTarget(resource, grscFeedUrl, true);
      if (feedUrl) {
        feedUrl.QueryInterface(CI.nsIRDFLiteral);
        dstDatasource.Assert(resource, grscLocked, glitTrue, true);

        var expirationDate = dstDatasource.GetTarget(resource,
          grscLivemarkExpiration, true);
        if (expirationDate) {
          expirationDate.QueryInterface(CI.nsIRDFDate);
          if (expirationDate.Value > new Date()) {
            yDebug.print("Livemark " + feedUrl.Value + " is up-to-date");
            dstDatasource.Unassert(resource, grscLocked, glitTrue, true);
            return;
          }
        }
        var container = gRdfContainerUtils.MakeSeq(dstDatasource, resource);

        if (! expirationDate) { // Loading for first time...
          emptyContainer(container);
          container.AppendElement(newLivemarkChild(dstDatasource, "Loading...",
            "about:livemark-loading"));
        }
        var channel = IOSVC.newChannel(feedUrl.Value, null, null);
        var listener = new FeedListener(this._memoryDatastore, container,
          channel, feedUrl.Value);
        channel.notificationCallbacks = listener;
        channel.asyncOpen(listener, null);
      }
    } catch (e) {
        logError("updateLivemarkChildren", e);        
    }
  },

  reloadLivemark : function(aFeedUrl) {
    var res = this.isLivemarked(aFeedUrl);
    if (res) {
        var old = this._memoryDatastore.GetTarget(res, grscLivemarkExpiration, true);
        var t = gRdfService.GetDateLiteral(0);
        if (old) {
            this._memoryDatastore.Change(res, grscLivemarkExpiration, old, t);
        } else {
            this._memoryDatastore.Assert(res, grscLivemarkExpiration, t, true);
        }
        this._updateLivemarkChildren(res);
    }
  },

  _initSearchDatasource : function() {
    this._searchDatasource = CC[
      "@mozilla.org/rdf/datasource;1?name=in-memory-datasource"].
      createInstance(CI.nsIRDFDataSource);
  },

  _initHiddenWindow : function() {
    this._hiddenWindow = CC["@mozilla.org/appshell/appShellService;1"].
      getService(CI.nsIAppShellService).hiddenDOMWindow;
  },

  _init : function(filename) {
    yDebug.print("Initialing bookmarks service");
    this._initDatasource(filename);

    if (this._initRoots()) {
      this._doFlush();
    }

    this._initSearchDatasource();

    this._allowDeleteAllBookmarks = true;

    // Clear completed transactions and reset other transactions'
    // state to uninitialized
    this._resetTransactions();

    // init the flush timer and observe the change of the flush timer pref
    this._resetFlushTimer();
    this._initPrefObserver();
    this._initHiddenWindow();

    this._updateLivemarks();
  },

  /**
   * Flushing the bookmarks for all changes is not a good idea as it depends
   * on number of bookmarks stored. If number of bookmarks is a large number,
   * flush take long time to finish. To overcome
   * this problem set the timer to every 5/10 seconds.
   */
  _resetFlushTimer : function() {

    if (! this._timer) {
      this._timer = CC[nsTimer].createInstance(nsITimer);
    } else {
      this._timer.cancel();
    }

    var prefs = CC[nsPreferences].getService(nsIPrefBranch);
    var flushDelay = DEFAULT_FLUSH_TIMER;
    try {
      flushDelay = prefs.getIntPref(PREF_FLUSH_TIMER);
    } catch (e) {
    }
    this._timer.initWithCallback(this, flushDelay * 60 * 1000,
      CI.nsITimer.TYPE_REPEATING_SLACK);
    yDebug.print("Timer initiated", YB_LOG_MESSAGE);
  },

  _initPrefObserver : function() {
    var prefs = CC[nsPreferences].getService(nsIPrefBranch2);
    prefs.addObserver(PREF_PREFIX, this, false);
  },

  observe : function (aSubject, aTopic, aData) {
    if ((aTopic == kPrefChangeTopic) && (aData == PREF_FLUSH_TIMER)) {
      this._resetFlushTimer();
    }
  },

  notify : function(aTimer) {
    if (this._flushPending) {
      this._doFlush();
    }
  },

  /** Immediately flush the RDF. */
  _doFlush : function() {
    if (this._fileDatasource) {
      this._fileDatasource.Flush();
    }
    this._flushPending = false;
  },

  _scheduleFlush : function() {
    this._flushPending = true;
  },

  /**
   * Either immediately flush the RDF, or schedule a flush with the timer.
   * If \c aForce is \c true, the flush is immediate.
   */

  flush : function(aForce) {
    traceIn("flush");
    try {
      if (aForce) {
        this._doFlush();
      } else {
        this._scheduleFlush();
      }
    } catch (e) {
      logError("flush", e);
    } finally {
      traceOut("flush");
    }
  },

  getDataSource : function() {
    traceIn("getDataSource");
    try {
      return this._datasource;
    } catch (e) {
      logError("getDataSource", e);
    } finally {
      traceOut("getDataSource");
    }
  },

  /**
   * Get the path of file in profile directory
   *
   * @param aName the name of the file
   * @return the file path
   */
  _getProfileFilePath : function(aName) {
    var dirService = CC["@mozilla.org/file/directory_service;1"].
                     getService(CI.nsIProperties);
    var file = dirService.get("ProfD", CI.nsILocalFile);
    file.append(aName);
    if (! file.exists()) {
      file.create(CI.nsIFile.NORMAL_FILE_TYPE, 0600);
    }

    var networkProtocol = CC["@mozilla.org/network/protocol;1?name=file"].
          createInstance(CI.nsIFileProtocolHandler);
    var fileURI = networkProtocol.newFileURI(file);

    return fileURI.spec;
  },

  _fromNSArrayToJSArray : function(nsarray) {
    var tags = nsarray.QueryInterface(CI.nsIArray)
      .enumerate();
    paramTags = new Array();
    while (tags.hasMoreElements()) {
      paramTags.push(tags.getNext().QueryInterface(CI.nsISupportsString).data);
    }

    return paramTags;
  },

  _addBookmark : function(aUrl, aTitle, aCharset, aIsWebPanel, aDescription,
    aShortcut, aPostData, aCountTags, aTags, aShared, localOnly, shouldFlush) {
    var bookmarkResource = this._getBookmarkResource(aUrl, false);
    if (!bookmarkResource) {
        bookmarkResource = this._getBookmarkResource(aUrl, true);
        this._setStringProperty(bookmarkResource, grscName, aTitle);
        this._setStringProperty(bookmarkResource, grscShortcut, aShortcut);
        this._setStringProperty(bookmarkResource, grscDesc, aDescription);
        this._setStringProperty(bookmarkResource, grscCharset, aCharset);
        this._setStringProperty(bookmarkResource, grscPostData, aPostData);
        this._addTags(bookmarkResource, aTags);
    } else {
      // treat this as the edit operation except for the tags.
      this.editBookmark ( aUrl,  { 
                                  name: aTitle,
                                  description: aDescription,
                                  shortcut: aShortcut,
                                  postData: aPostData,
                                  tags: aTags
                                }
                        );
    }    
    this._setSharedFlag(bookmarkResource, aShared);
    this._setLocalOnlyFlag(bookmarkResource, localOnly);

    // this is for the backward compatibility during development process
    var addDate = "" + ((new Date()).getTime() * 1000);
    this._setAddDate(bookmarkResource, addDate);

    if (this._fileDatasource.GetTarget(bookmarkResource,
      grscLastModifiedDate, true) == null) {
      this._fileDatasource.Assert (bookmarkResource,
        grscLastModifiedDate, gRdfService.GetDateLiteral(addDate), true);
    }

    if (this._fileDatasource.GetTarget(bookmarkResource,
      grscVisitCount, true) == null) {
      this._fileDatasource.Assert(bookmarkResource, grscVisitCount,
        gRdfService.GetIntLiteral(0), true);
    }

    return bookmarkResource;
  },

  /**
   * From nsYBookmarkService.js - modified
   *
   */
  _addTags : function(bookmarkResource, aTags) {
    for (var count = 0; count < aTags.length; ++count) {
      if (aTags[count].length != 0) {
        var tagLiteral = gRdfService.GetLiteral(aTags[count]);
        if (! this._fileDatasource.HasAssertion(bookmarkResource,
          grscTag, tagLiteral, true)) {
          this._fileDatasource.Assert(bookmarkResource, grscTag,
            tagLiteral, true);
        }
        this._addBookmarkToTagContainer(aTags[count], bookmarkResource);
      }
    }

    this._addBookmarkToFavoriteTagsContainers(aTags, bookmarkResource);
  },

  /**
   * Change the tag to lower case
   */
  _normalizeTag : function (aTag) {
    if (aTag == "") {
      return aTag;
    }

    return aTag.toLowerCase();
  },

  /**
   * Add bookmark resource to tag container
   */
  _addBookmarkToTagContainer : function (aTag, aBookmarkResource) {
    var tagResource = this._getTagResource(aTag, true);
    var tagContainer = gRdfContainerUtils.MakeSeq(this._fileDatasource,
      tagResource);

    if (tagContainer.IndexOf(aBookmarkResource) == -1) {
      tagContainer.AppendElement(aBookmarkResource);
      this._changeTagTotalChildrenCounter(tagResource, true);
    }
  },

  /**
   * Remove bookmark resource from the tag container
   *
   * @param aTag a tag
   * @param aBookmarkResource a bookmark resource
   */
  _removeBookmarkFromTagContainer : function(aTag, aBookmarkResource) {
    var tagResource = this._getTagResource(aTag, false);
    if (tagResource) {
      var tagContainer = gRdfContainerUtils.MakeSeq(this._fileDatasource,
        tagResource);
      var index = tagContainer.IndexOf(aBookmarkResource);
      if (index != -1) {
        tagContainer.RemoveElementAt(index, false);
        this._changeTagTotalChildrenCounter(tagResource, false);
      }
    }
  },

  /**
   * Count the number of children in a tag container and store the total
   */
  _changeTagTotalChildrenCounter : function(tagResource, isIncrement) {
    var childCounter = this._fileDatasource.GetTarget(
      tagResource, grscChildCount, true);
    if (childCounter) {
      childCounter.QueryInterface(CI.nsIRDFInt);
      var newValue = childCounter.Value;
      if (isIncrement) {
        newValue++;
      } else {
        newValue--;
      }

      if (newValue == 0) {
        this._deleteAllChildren(tagResource);
        this._removeFromTagRoot(tagResource);
      } else {
        var newCounter = gRdfService.GetIntLiteral(newValue);
        this._fileDatasource.Change(tagResource, grscChildCount,
          childCounter, newCounter, true);
      }
    } else {
      // find total number of children in this first.
      var newCounter = gRdfService.GetIntLiteral(1);
      this._fileDatasource.Assert(tagResource, grscChildCount,
        newCounter, true);
    }
  },

  /*********************************************************************
   *                          Favorite Tag Functions                   *
   *********************************************************************/

  _tokenizeFavoriteTag : function(aTag) {
    return this._normalizeTag(aTag).split("+");
  },

  isFavoriteTag : function(aTag) {
    traceIn("isFavoriteTag");
    try {
      return this._getFavoriteTagResouce(aTag, false);
    } catch (e) {
      logError("isFavoriteTag", e);
    } finally {
      traceOut("isFavoriteTag");
    }
  },

  getFavoriteTags : function(aCount) {
    traceIn("getFavoriteTags");
    try {
      var out = [];
      var favTags = this._favoriteTagsRoot.GetElements();

      while (favTags.hasMoreElements()) {
        var ft = favTags.getNext();
        var ftNode = this._fileDatasource.GetTarget(ft, grscFavoriteTagValue, true);
        ftNode.QueryInterface(CI.nsIRDFLiteral);
        out.push(ftNode.Value);
      }
      aCount.value = out.length;
      return out;
    } catch (e) {
      logError("getFavoriteTags", e);
    } finally {
      traceOut("getFavoriteTags");
    }
  },

  getFavoriteTagOrder : function(aTag) {
    traceIn("getFavoriteTagOrder");
    try {
      var favTagResource = this._getFavoriteTagResouce(aTag);
      if (favTagResource) {
        var favTagOrderResource = this._fileDatasource.GetTarget(favTagResource,
          grscFavoriteTagOrder, true);
        if (favTagOrderResource) {
          favTagOrderResource.QueryInterface(CI.nsIRDFLiteral);
          return favTagOrderResource.Value;
        }
      }
      return FAVTAG_ORDER_DEFAULT;
    } catch (e) {
      logError("getFavoriteTagOrder", e);
    } finally {
      traceOut("getFavoriteTagOrder");
    }
  },

  setFavoriteTagOrder : function(aTag, aOrder) {
    traceIn("setFavoriteTagOrder");
    try {
      var favTagResource = this._getFavoriteTagResouce(aTag);
      if (favTagResource) {
        this._setStringProperty(favTagResource, grscFavoriteTagOrder, aOrder);
        this._scheduleFlush();
      }
    } catch (e) {
      logError("setFavoriteTagOrder", e);
    } finally {
      traceOut("setFavoriteTagOrder");
    }
  },

  clearFavoriteTags : function() {
    traceIn("clearFavoriteTags");
    try {
      this._deleteAllContentsAndChildren(this._favoriteTagsRoot);
      this._scheduleFlush();
    } catch (e) {
      logError("clearFavoriteTags", e);
    } finally {
      traceOut("clearFavoriteTags");
    }
  },
  
  cleanOutFavoriteTags : function() {
    traceIn("cleanOutFavoriteTags");
    try {
      var favTags = this._favoriteTagsRoot.GetElements();
      while (favTags.hasMoreElements()) {
        var favTagRsrc = favTags.getNext().QueryInterface(Components.interfaces.nsIRDFResource);
        var bmSeq = gRdfContainerUtils.MakeSeq(this._fileDatasource, favTagRsrc);
        var bmEnum = bmSeq.GetElements();
        var elts = []; // why? cuz it's bad to change the underlying resource while iterating
        while (bmEnum.hasMoreElements()) {
          elts.push(bmEnum.getNext());
        }
        for (var i=0; i < elts.length; i++) {
          bmSeq.RemoveElement(elts[i], true);
        }
      }
      this._scheduleFlush();
    } catch (e) {
      logError("cleanOutFavoriteTags", e);
    } finally {
      traceOut("cleanOutFavoriteTags");
    }
  },

  addFavoriteTag : function(aTag) {
    traceIn("addFavoriteTag");
    try {
      var favTagResource = this._getFavoriteTagResouce(aTag, true);
      this._initFavoriteTag(favTagResource, aTag);
      this._scheduleFlush();
    } catch (e) {
      logError("addFavoriteTag", e);
    } finally {
      traceOut("addFavoriteTag");
    }
  },

  /*
   * Populates a Favorite tag with all the appropriate tags
   */
  _initFavoriteTag : function(favTagResource, aTag) {
    var tags = this._tokenizeFavoriteTag(aTag);
    var args = [];
    for (var i = 0; i < tags.length; i++) {
      var tagResource = this._getTagResource(tags[i], false);
      if (tagResource) {
        var bookmarksEnum = gRdfContainerUtils.MakeSeq(this._fileDatasource,
          tagResource).GetElements();
        args.push(bookmarksEnum);
      } else {
        args = null;
        break;
      }
    }

    if (args) {
      var bookmarks = this._getIntersectingBookmarks(args);
      var favTagContainer = gRdfContainerUtils.MakeSeq(this._fileDatasource,
        favTagResource);

      for (var i = 0; i < bookmarks.length; i++) {
        var bm = bookmarks[i];
        if (favTagContainer.IndexOf(bm) == -1) {
          favTagContainer.AppendElement(bm);
        }
      }
    }
  },

  /**
   * Return the intersection of bookmarks
   * aArrays - an Array of nsISimpleEnumeration that contain bookmark Resources
   */
  _getIntersectingBookmarks : function(aArrays) {
    var bookmarks = {};
    var result = [];

    for (var i = 0; i < aArrays.length; i++) {
      var bmEnum = aArrays[i];
      while (bmEnum.hasMoreElements()) {
        var bm = bmEnum.getNext();
        bm.QueryInterface(CI.nsIRDFResource);
        var key = bm.Value;
        if (! bookmarks[key]) {
          bookmarks[key] = { count : 1, bm : bm };
        } else {
          bookmarks[key].count++;
        }
      }
    }

    for each (var bm in bookmarks) {
      if (bm.count == aArrays.length) {
        result.push(bm.bm);
      }
    }
    return result;
  },

  deleteFavoriteTag : function (aTag) {
    traceIn("deleteFavoriteTag");
    try {
      var favTagResource = this._getFavoriteTagResouce(aTag, false);

      if (favTagResource) {
        this._removeMatchingContent(this._favoriteTagsRoot.Resource,
          favTagResource);
        this._deleteAllChildren(favTagResource);
        this._scheduleFlush();
      }
    } catch (e) {
      logError("deleteFavoriteTag", e);
    } finally {
      traceOut("deleteFavoriteTag");
    }
  },

  moveFavoriteTag : function (aTag, aIndex) {
    traceIn("moveFavoriteTag");
    try {
      var favTagResource = this._getFavoriteTagResouce(aTag);

      if (favTagResource &&
        (this._favoriteTagsRoot.IndexOf(favTagResource) != -1)) {
        this._favoriteTagsRoot.RemoveElement(favTagResource, true);
        this._favoriteTagsRoot.InsertElementAt(favTagResource, aIndex, true);
        this._scheduleFlush();
      }
    } catch (e) {
      logError("moveFavoriteTag", e);
    } finally {
      traceOut("moveFavoriteTag");
    }
  },

  getBookmarksFromFavoriteTag : function(aTag, aCount) {
    traceIn("getBookmarksFromFavoriteTag");
    try {
      var favTagResource = this._getFavoriteTagResouce(aTag);
      var out = [];

      if (favTagResource) {
        var tagContainer = gRdfContainerUtils.MakeSeq(this._fileDatasource,
          favTagResource);
        var favTags = tagContainer.GetElements();
        while (favTags.hasMoreElements()) {
          var ft = favTags.getNext();
          var bookmark = this.getBookmarkFromResource(ft);
          if (bookmark && bookmark.url) {
            out.push(bookmark);
          } else {
            yDebug.print("Favorite Tag '" + aTag + "' has a strange resource: " + ft.Value, YB_LOG_MESSAGE);
          }
        }
      }

      if (aCount) {
        aCount.value = out.length;
      }

      return out;
    } catch (e) {
      logError("getBookmarksFromFavoriteTag", e);
    } finally {
      traceOut("getBookmarksFromFavoriteTag");
    }
    return [];
  },

  _addBookmarkToFavoriteTagsContainers : function (aTags, aBookmarkResource) {
    try {
      var lookup = {};

      for (var i = 0; i < aTags.length; i++) {
        var tag = this._normalizeTag(aTags[i]);
        if (tag) {
          lookup[tag] = true;
        }
      }

      var favTags = this._favoriteTagsRoot.GetElements();
      while (favTags.hasMoreElements()) {
        var favTagResource = favTags.getNext();
        favTagResource.QueryInterface(CI.nsIRDFResource);
        var favTagValueNode = this._fileDatasource.GetTarget(favTagResource,
          grscFavoriteTagValue, true);
        favTagValueNode.QueryInterface(CI.nsIRDFLiteral);
        var favTagValue = favTagValueNode.Value;

        var fts = this._tokenizeFavoriteTag(favTagValue);
        var addToFavTag = true;

        if (fts.length > 0) {
          for (var i = 0; i < fts.length; i++) {
            if (!lookup[fts[i]]) {
              addToFavTag = false;
              break;
            }
          }
          if (addToFavTag) {
            var favTagContainer = gRdfContainerUtils.MakeSeq(
              this._fileDatasource, favTagResource);
            if (favTagContainer.IndexOf(aBookmarkResource) == -1) {
              favTagContainer.InsertElementAt(aBookmarkResource, 1, true);
            }
          }
        }
      }
    } catch (e) {
        yDebug.print("_addBookmarkToFavoriteTagsContainers(): " + e);
    }

  },

  /*********************************************************************
   *                        Bookmark Functions                         *
   *********************************************************************/

  /**
   * Add bookmark to the _fileDatasource. Call Flush if shouldFlush parameter
   * is set to true.
   * If bookmark already exists, do nothing.
   *
   * @param aUrl url of the bookmark. url cannot be changed once added
   * @param aTitle title of the bookmark
   * @param aCharset charset for the url
   * @param aIsWebPanel unknown. Just copied from the existing bookmark
   * @param aDescription short description for this bookmark
   * @param aShortcut shortcut for the bookmark
   * @param aPostData post data for a post form shortcut
   * @param aCountTags number of items in the next array parameter
   * @param aTags tags for this bookmark. Array of string
   * @param aShared whether or not this bookmark is shared with public
   * @param localOnly whether or not this bookmark should be stored in
   * local only
   * @param shouldFlush flag to indicate whether or not to call Flush
   * after adding bookmark.
   *
   */
  addBookmark : function(aUrl, aTitle, aCharset, aIsWebPanel, aDescription,
    aShortcut, aPostData, aCountTags, aTags, aShared, localOnly, shouldFlush) {
    traceIn("addBookmark");
    try {
      var bookmarkResource = this._addBookmark(aUrl, aTitle, aCharset, aIsWebPanel, aDescription,
        aShortcut, aPostData, aCountTags, aTags, aShared, localOnly);
      this._setProperty(bookmarkResource, grscType, grscBookmarkType);
      if (shouldFlush) {
        this._scheduleFlush();
      }
    } catch (e) {
      logError("addBookmark", e);
    } finally {
      traceOut("addBookmark");
    }
  },

  /**
   * Add new bookmark to rdf:bookmark _fileDatasource
   */
  addBookmarkObject : function (aBookmarkObject, shouldFlush) {
    traceIn("addBookmarkObject");
    try {
      var jsarray = this._fromNSArrayToJSArray(aBookmarkObject.tags);
      var bookmarkResource = this._addBookmark(aBookmarkObject.url,
        aBookmarkObject.name, "", false, aBookmarkObject.description,
        aBookmarkObject.shortcut, aBookmarkObject.postData,
        jsarray.length, jsarray, aBookmarkObject.shared,
        aBookmarkObject.localOnly);
      this._setProperty(bookmarkResource, grscType, grscBookmarkType);

      this._setDateProperty(bookmarkResource, grscLastModifiedDate,
        aBookmarkObject.last_modified);
      this._setDateProperty(bookmarkResource, grscAddDate,
        aBookmarkObject.added_date);
  
      if (shouldFlush) {
        this._scheduleFlush();
      }
    } catch (e) {
      logError("addBookmarkObject", e);
    } finally {
      traceOut("addBookmarkObject");
    }
  },

  /**
   * Add new livemarks to bookmarks _datasource
   *
   * @param aUrl the url of where the livemark comes from
   * @parma aTitle the title of the livemark
   * @param aFeedUrl the feed url
   * @param aDescription the description of the livemark
   * @param aCountTags size of tags array
   * @param aTags array of tags
   * @param aShared whether or not this bookmark is shared with public
   * @param localOnly whether or not this bookmark should be stored in
   * local only
   * @param shouldFlush should flush the livemarks _datasource or not
   */
  addLivemark : function(aUrl, aTitle, aFeedUrl, aDescription, aCountTags,
    aTags, aShared, localOnly, shouldFlush) {
    traceIn("addLivemark");
    try {
      var bookmarkResource = this.isLivemarked(aFeedUrl);
      if (!bookmarkResource) {
        bookmarkResource = this._getBookmarkResource(aUrl, true);
        this._feedsRoot.AppendElement(bookmarkResource);
      }

      this._setStringProperty(bookmarkResource, grscUrl, aUrl);
      this._setStringProperty(bookmarkResource, grscName, aTitle);
      this._setStringProperty(bookmarkResource, grscFeedUrl, aFeedUrl);
      this._setStringProperty(bookmarkResource, grscDesc, aDescription);
      this._addTags(bookmarkResource, aTags);
      this._setSharedFlag(bookmarkResource, aShared);
      this._setLocalOnlyFlag(bookmarkResource, localOnly);
      this._setProperty(bookmarkResource, grscType, grscLivemarkType);

      if (shouldFlush) {
        this._scheduleFlush();
      }
      this._updateLivemarkChildren(bookmarkResource);
    } catch (e) {
      logError("addLivemark", e);
    } finally {
      traceOut("addLivemark");
    }
  },

  /**
   * Edit the given bookmark. New values are provided as a nsIYBookmark object.
   * URL should not be allowed to be edited. Implementation is free to
   * decide on the editable attributes.
   *
   * @param aUrl url to be edited.
   * @param args object of nsIYBookmark. This is key value pair represented
   * as a JSON object.
   *
   * @return false if aUrl is not present in the database, true otherwise.
   *
   * NOTE: Method may throw an exception.
   *
   */
  editBookmark : function(aUrl, args) {
    traceIn("editBookmark");
    try {
      var bookmarkResource = this.isLivemarked(aUrl);

      if (!bookmarkResource) {
        bookmarkResource = this._getBookmarkResource(aUrl, false);
        if (!bookmarkResource) {
          yDebug.print("editBookmark: Bookmark not found. Returning...",
            B_LOG_MESSAGE);
          return false;
        }
      }

      var isChanged = false;
      for (var part in gResourceMap) {
        if (args[part]) {
          var currentValue = this._fileDatasource.GetTarget(bookmarkResource,
            gResourceMap[part], true);
          if (currentValue) {
            this._fileDatasource.Change(bookmarkResource, gResourceMap[part],
              currentValue, gRdfService.GetLiteral(args[part]), true);
          } else {
            this._fileDatasource.Assert(bookmarkResource, gResourceMap[part],
              gRdfService.GetLiteral(args[part]), true);
          }
          isChanged = true;
        }
      }

      //check for deleted shortcuturls
      if (!args.shortcut) {
        var shortcutRsrc  = this._fileDatasource.GetTarget(bookmarkResource, grscShortcut, true);
        if (shortcutRsrc) {
          this._fileDatasource.Unassert(bookmarkResource, grscShortcut, shortcutRsrc);
        }
      }
      
      var isFeed = false;

      if (args["tags"]) {
        var paramTags = [];
        try {
          var tags = args["tags"];
          tags = tags.QueryInterface(CI.nsIArray).enumerate();
          while (tags.hasMoreElements()) {
            paramTags.push(tags.getNext().
              QueryInterface(CI.nsISupportsString).data);
          }
        } catch (e) {
          paramTags = args["tags"];
        }

        isFeed = (ybookmarksUtils.containsTag(paramTags.join(' '),
          "firefox:rss") >= 0) ? true : false;

        this._removeAllTagsForResource(bookmarkResource);
        this.addTag(paramTags.length, paramTags, aUrl, false);
        isChanged = true;
      }

      if (isChanged) {
        var modDate = (new Date()).getTime() * 1000;
        this._setDateProperty(bookmarkResource, grscLastModifiedDate, modDate);
        this._scheduleFlush();
      }

      if (isFeed && this._feedsRoot.IndexOf(bookmarkResource) == -1) {
        this._feedsRoot.AppendElement(bookmarkResource);
      }
      this._updateLivemarkChildren(bookmarkResource);
      return true;
    } catch (e) {
      logError("editBookmark", e);
    } finally {
      traceOut("editBookmark");
    }
    return false;
  },

  /**
   * Delete the bookmark and all its associated tags from the database.
   * If same tag is used by multiple bookmarks, only the association
   * between bookmark and the tag is removed. Tag is
   * retained in the system.
   *
   * @param aUrl url to be removed from the system.
   *
   * @return false if aUrl is not present in the system, true otherwise.
   *
   */
  deleteBookmark : function(aUrl) {
    traceIn("deleteBookmark");
    try {
      var bookmarkResource = this._getBookmarkResource(aUrl, false);
      if (!bookmarkResource) {
        return true;
      }

      this._fileDatasource.beginUpdateBatch();
      this._deleteAllChildren(bookmarkResource);
      this._removeFromBookmarksRoot(bookmarkResource);

      var allTagResources = this._getTagRoot().GetElements();
      while (allTagResources.hasMoreElements()) {
        var tagResource = allTagResources.getNext();
        if (this._removeMatchingContent(tagResource, bookmarkResource)) {
          this._changeTagTotalChildrenCounter(tagResource, false);
        }
      }

      allTagResources = this._favoriteTagsRoot.GetElements();
      while (allTagResources.hasMoreElements()) {
        tagResource = allTagResources.getNext();
        this._removeMatchingContent(tagResource, bookmarkResource);
      }

      // remove the bookmark from the feed container if present
      var index = this._feedsRoot.IndexOf(bookmarkResource);
      if (index != -1) {
        this._feedsRoot.RemoveElementAt(index, false);
      }

      this._fileDatasource.endUpdateBatch();
      this._scheduleFlush();

      var os = Components.classes["@mozilla.org/observer-service;1"].
                  getService(Components.interfaces.nsIObserverService);
      var notifyData = aUrl;
      os.notifyObservers(null, "ybookmark.bookmarkDeleted", notifyData);
      
      return true;
    } catch (e) {
      logError("deleteBookmark", e);
    } finally {
      traceOut("deleteBookmark");
    }
    return false;
  },

  getBookmark : function (aUrl) {
    traceIn("getBookmark");
    try {
      var bookmarkResource = this._getBookmarkResource(aUrl, false);
      if (!bookmarkResource) {
        return null;
      }
      return this.getBookmarkFromResource(bookmarkResource);
    } catch (e) {
      logError("getBookmark", e);
    } finally {
      traceOut("getBookmark");
    }
    return null;
  },

  getBookmarkFromResource : function (aBookmarkResource) {
    traceIn("getBookmarkFromResource");
    try {
      var name = this._getTargetLiteral(aBookmarkResource, grscName);
      var title = name;
      var url = this._getTargetLiteral(aBookmarkResource, grscUrl);
      var desc = this._getTargetLiteral(aBookmarkResource, grscDesc);
      var charset = this._getTargetLiteral(aBookmarkResource, grscCharset);
      if (charset == "") {
          charset = "UTF-8";
      }
      var icon = this._getTargetLiteral(aBookmarkResource, grscIcon);
      var type = this._getTargetResource(aBookmarkResource, grscType);
      var modifiedDate = this._getTargetDate(aBookmarkResource,
          grscLastModifiedDate);
      var addDate = this._getTargetDate(aBookmarkResource, grscAddDate);
      var visitDate = this._getTargetDate(aBookmarkResource, grscLastVisitDate);
      var visitCount = this._getTargetInt(aBookmarkResource, grscVisitCount);
      var shared = this._getTargetLiteral(aBookmarkResource, grscShared);
      var localOnly = this._getTargetLiteral(aBookmarkResource, grscLocalOnly);
      var shortcut = this._getTargetLiteral(aBookmarkResource, grscShortcut);
      var postData = this._getTargetLiteral(aBookmarkResource, grscPostData);

      var tags = this._getTargetLiterals(aBookmarkResource, grscTag);
      var id = aBookmarkResource.QueryInterface(CI.nsIRDFResource).Value;

      return {
        id : id,
        name : name,
        title : title,
        url : url,
        type : type,
        description : desc,
        charset : charset,
        last_visited : visitDate,
        last_modified : modifiedDate,
        added_date : addDate,
        visit_count : visitCount,
        tags : tags,
        icon : icon,
        shortcut : shortcut,
        postData : postData,
        shared : shared,
        localOnly : localOnly
      };
    } catch (e) {
      logError("getBookmarkFromResource", e);
    } finally {
      traceOut("getBookmarkFromResource");
    }
    return null;
  },

  _getLivemarkBookmark : function(resource) {
    var title = this._getTargetLiteral2(this._datasource, resource, grscName);
    var url = this._getTargetLiteral2(this._datasource, resource, grscUrl);
    return {
      name : title,
      title : title,
      url : url
    };
  },

  getBookmarksForLivemark : function(aUrl, aCount) {
    traceIn("getBookmarksForLivemark");
    try {
      var out = [];
      var livemarkResource = this._getBookmarkResource(aUrl, false);
      if (livemarkResource) {
        var livemarkContainer = gRdfContainerUtils.MakeSeq(this._datasource,
          livemarkResource);
        var bookmarks = livemarkContainer.GetElements();
        while (bookmarks.hasMoreElements()) {
          var bm = bookmarks.getNext();
          var bookmark = this._getLivemarkBookmark(bm);
          if (bookmark) {
            out.push(bookmark);
          }
        }
      }

      if (aCount) {
        aCount.value = out.length;
      }
      return out;
    } catch (e) {
      logError("getBookmarksForLivemark", e);
    } finally {
      traceOut("getBookmarksForLivemark");
    }
    return null;
  },
  
  /**
   * Get the total number of bookmarks
   *
   * @return the number of bookmarks
   */
  getTotalBookmarks : function() {
      return this._getBookmarkRoot().GetCount();
  },

  /**
   * Delete all bookmarks if the shouldDeleteAllBookmarks flag is true
   * bug fixed : cannot remove bookmarks when the xpcom starts
   */
  deleteAllBookmarks : function(shouldFlush) {
    traceIn("deleteAllBookmarks");
    try {
      if (this._allowDeleteAllBookmarks) {
        this._fileDatasource.beginUpdateBatch();
        var os = CC["@mozilla.org/observer-service;1"].
                    getService(CI.nsIObserverService);
        var notifyData = "remove-extra";  // FIXME: Is the name okay?
        os.notifyObservers(null, "ybookmark.syncBegin", notifyData);

        this._deleteAllContentsAndChildren(gRdfContainerUtils.MakeSeq(this._fileDatasource,
          grscBookmarksRoot));
        this._deleteAllContentsAndChildren(this._getTagRoot());
        emptyContainer(this._feedsRoot);

        var favTags = this._favoriteTagsRoot.GetElements();
        while (favTags.hasMoreElements()) {
          var favTag = favTags.getNext();
          favTag.QueryInterface(CI.nsIRDFResource);
          var favTagContainer = gRdfContainerUtils.MakeSeq(this._fileDatasource,
            favTag);
          emptyContainer(favTagContainer);
        }

        //cleanup things
        this.removeAllTransactions(10);
        this.setLastUpdateTime("");

        this._fileDatasource.endUpdateBatch();
        os.notifyObservers(null, "ybookmark.syncDone", notifyData);

        if (shouldFlush) {
          this._scheduleFlush();
        }
      }
    } catch (e) {
      logError("deleteAllBookmarks", e);
      this._allowDeleteAllBookmarks = false;
    } finally {
      traceOut("deleteAllBookmarks");
    }
  },

  /*********************************************************************
   *                      Bookmark Tag Functions                       *
   *********************************************************************/

  addTag : function(aCountTags, aTags, aUrl, shouldFlush) {
    traceIn("addTag");
    try {
      var bookmarkResource = this._getBookmarkResource(aUrl, false);
      if ( !bookmarkResource ) {
        yDebug.print("addTag: " + aUrl + " is not in the bookmark database",
          YB_LOG_MESSAGE );
        return false;
      }
      this._addTags(bookmarkResource, aTags);

      if (shouldFlush) {
        this._scheduleFlush();
      }

      return true;
    } catch (e) {
      logError("addTag", e);
    } finally {
      traceOut("addTag");
    }
  },

  /**
   * Get the tags for a given url. If url parameter is null, return all
   * the tags in the system.
   *
   * @param aUrl url for which tags are requested.
   * @param aCount parameter which will be set to the number of items in
   * the returned array.
   *
   * @return an array of string having the tags for the given aUrl.
   * An empty array if aUrl is not present in the system or aUrl do not
   * have any tags.
   *
   */
  getTags : function(aUrl, aCount) {
    traceIn("getTags");
    var out = new Array();
    try {
      if (aUrl) {
        var bookmarkResource = this._getBookmarkResource(aUrl, false);
        if (bookmarkResource) {
          var tags = this._fileDatasource.GetTargets(bookmarkResource,
            grscTag, true);
          while (tags.hasMoreElements()) {
            var value = tags.getNext().QueryInterface(CI.nsIRDFLiteral).Value;
            out.push(value);
          }
        }
      } else {
        var tags = this._getTagRoot().GetElements();
        while (tags.hasMoreElements()) {
          var tagValue = this._fileDatasource.GetTarget(tags.getNext(),
            grscTagValue, true).QueryInterface(CI.nsIRDFLiteral).Value;
          out.push(tagValue);
        }
      }
      aCount.value = out.length;
    } catch (e) {
      logError("getTags", e);
    } finally {
      traceOut("getTags");
    }
    return out;
  },

  /*********************************************************************
   *                              Tag Functions                        *
   *********************************************************************/

  /*
   * Get the total number of tags
   *
   * @return the number of tags
   */
  getTotalTags : function() {
      return this._getTagRoot().GetCount();
  },

  /**
   * Get the total number of bookmarks for tag
   *
   * @return the number of bookmarks
   */
  getTotalBookmarksForTag : function(aTag) {
    var tagResource = this._getTagResource(aTag, false);

    if (tagResource) {
      var childCounter = this._fileDatasource.GetTarget(tagResource,
        grscChildCount, true);
      if (childCounter) {
        childCounter.QueryInterface(CI.nsIRDFInt);
        return childCounter.Value;
      } else {
        return 0;
      }
    }
  },

  /**
   * Returned tag resource name can be used in the ref attribute of the
   * template in XUL.
   *
   * @param aTag tag for which tag resource name is requested
   *
   * @return the resource name used (anonymous) for the tag in the local store.
   */
  getTagResourceName : function (aTag) {
    traceIn("getTagResourceName");
    try {
      var tagResource = this._getTagResource(aTag, false);
      if (tagResource) {
        return tagResource.QueryInterface(CI.nsIRDFResource).Value;
      } else {
        return null;
      }
    } catch (e) {
      logError("getTagResourceName", e);
    } finally {
      traceOut("getTagResourceName");
    }
  },

  /*********************************************************************
   *                           Private Functions                       *
   *********************************************************************/

  /** Deletes all predicates and objects of the given subject */
  _deleteAllChildren : function(parent) {
    var children = this._fileDatasource.ArcLabelsOut(parent);
    while (children.hasMoreElements()) {
      var predicate = children.getNext();
      predicate.QueryInterface(CI.nsIRDFResource);
      var objects = this._fileDatasource.GetTargets(parent, predicate, true);
      while (objects.hasMoreElements()) {
        this._fileDatasource.Unassert(parent, predicate, objects.getNext());
      }
    }
  },

  /** Deletes all contents and their children for the given container */
  _deleteAllContentsAndChildren : function(container) {
      var contents = container.GetElements();
      while (contents.hasMoreElements()) {
        var content = contents.getNext();
        this._deleteAllChildren(content);
        container.RemoveElement(content, false);
      }
  },

  /** Removes a bookmark resource from bookmarks root */
  _removeFromBookmarksRoot : function(bookmarkResource) {
    if (bookmarkResource) {
      this._getBookmarkRoot().RemoveElement(bookmarkResource, false);
    }
  },

  /** Removes a tag resource from tags root */
  _removeFromTagRoot : function (tagResource) {
    if (tagResource) {
      this._getTagRoot().RemoveElement(tagResource, false);
    }
  },

  /** Removes a tag resource from tags root */
  _removeFromBundlesRoot : function (bnResource) {
    if (bnResource) {
      this._bundleRoot.RemoveElement(bnResource, true);
    }
  },

  /**
   * Walks through the contents of the given resource and removes
   * the content that matches the given one.
   */
  _removeMatchingContent : function(resource, content) {
    var container = gRdfContainerUtils.MakeSeq(this._fileDatasource, resource);
    var index = container.IndexOf(content);
    if (index != -1) {
      container.RemoveElementAt(index, false);
      return true;
    }
    return false;
  },

  _gatherContents : function (container) {
    var result = [];
    var contents = container.GetElements();
    while (contents.hasMoreElements()) {
      var content = this.getBookmarkFromResource(contents.getNext());
      if (content) {
        result.push(content);
      }
    }
    return result;
  },

  /**
   * Get the bookmarks for a given tag. If aTag is null,
   * return all the bookmarks.
   *
   * @param aTag tag for which bookmark is requested.
   * @param aCount parameter which will be set to the number of items
   * in the returned array.
   * @return an array of nsIYBookmark object. Each object is a key value pair.
   * An empty array if no urls tagged with the given tag or aTag is not
   * present in the database.
   *
   */
  getBookmarks : function(aTag, aCount) {
    traceIn("getBookmarks");
    var result = new Array();
    try {
      if (aTag) {
        var tagResource = this._getTagResource(aTag);
        if (tagResource) {
          result = this._gatherContents(
            contents = gRdfContainerUtils.MakeSeq(this._fileDatasource, tagResource));
        }
      } else {
        result = this._gatherContents(this._getBookmarkRoot());
      }

      if (aCount) {
        aCount.value = result.length;
      }
    } catch (e) {
      logError("getBookmarks", e);
    } finally {
      traceOut("getBookmarks");
    }

    return result;
  },


  _setAddDate : function (aUrl, aDate) {
    this._setDateProperty(aUrl, grscAddDate, aDate);
  },

  _getTargetLiteral2 : function(datasource, source, predicate) {
    var target = datasource.GetTarget(source, predicate, true);
    if (target) {
      return target.QueryInterface(CI.nsIRDFLiteral).Value;
    } else {
      //yDebug.print("Predicate '" + predicate.Value + "' not found for '" + source.Value + "'");
      return "";
    }
  },

  _getTargetLiteral : function(source, predicate) {
    return this._getTargetLiteral2(this._fileDatasource, source, predicate);
  },

  _getTargetBoolean : function(source, predicte) {
    return (this._getTargetLiteral(source, predicte) == "true") ? true : false;
  },

  _getTargetDate : function(source, predicate) {
    var target = this._fileDatasource.GetTarget(source, predicate, true);
    if (target) {
      return target.QueryInterface(CI.nsIRDFDate).Value;
    } else {
      return 0;
    }
  },

  _getTargetInt : function(source, predicate) {
    var target = this._fileDatasource.GetTarget(source, predicate, true);
    if (target) {
      return target.QueryInterface(CI.nsIRDFInt).Value;
    } else {
      return 0;
    }
  },

  _getTargetResource : function(source, predicate) {
    var target = this._fileDatasource.GetTarget(source, predicate, true);
    if (target) {
      return target.QueryInterface(CI.nsIRDFResource).Value;
    } else {
      return "";
    }
  },

  _getTargetLiterals : function(source, predicate) {
    var t = this._fileDatasource.GetTargets(source, predicate, true);
    var result = new NSArray();
    while (t.hasMoreElements()) {
      var value = t.getNext().QueryInterface(CI.nsIRDFLiteral).Value;
      var nsValue = new NSString();
      nsValue.data = value;
      result.appendElement(nsValue, false);
    }
    return result.QueryInterface(CI.nsIArray);
  },

  /**
   *  Get the type of a resource
   *
   *  @param aResource a bookmark resource
   *
   *  @return string the type of the resource
   */
  resolveBookmarkResourceType : function (aResource) {
    traceIn("resolveBookmarkResourceType");
    try {
      var t = this._datasource.GetTarget(aResource, grscType, true);
      return (t == grscLiveBookmarkType) ? "LiveBookmark" 
        : ((t == grscLivemarkType) ? "Livemark" : 
        ((t == grscBookmarkType) ? "Bookmark" : ""));
    } catch (e) {
      logError("resolveBookmarkResourceType", e);
    } finally {
      traceOut("resolveBookmarkResourceType");
    }
    return "";
  },

  /**
   * Whenever website is visited via the bookmark link the count on the
   * bookmark is increased.
   * This should also update the last visited time (if maintained).
   *
   * @param aUrl url visited
   */
  incrementVisitCount : function(aUrl) {
    traceIn("incrementVisitCount");
    try {
      var bookmarkResource = this._getBookmarkResource(aUrl, false);
      if (bookmarkResource) {
        var count = this._fileDatasource.GetTarget(bookmarkResource,
          grscVisitCount, true);
        if (count) {
          count.QueryInterface(CI.nsIRDFInt);
          this._fileDatasource.Change(bookmarkResource, grscVisitCount,
            count, gRdfService.GetIntLiteral(count.Value + 1), true);
        } else {
          this._fileDatasource.Assert(bookmarkResource, grscVisitCount,
            gRdfService.GetIntLiteral(1), true);
        }
        var nowDate = (new Date()).getTime() * 1000;
        this._setDateProperty(bookmarkResource, grscLastVisitDate, nowDate);
        this._scheduleFlush();
      }
    } catch (e) {
      logError("incrementVisitCount", e);
    } finally {
      traceOut("incrementVisitCount");
    }
  },

  /**
   * Returns the source for the given predicate and value.
   */
  _getSource : function(predicate, value) {
    return this._fileDatasource.GetSource(predicate, value, true);
  },
  /**
   * Check if the given url is present in the bookmark database.
   *
   * @param aUrl url of the bookmark to be checked.
   *
   * @return bookmark resource if present, null otherwise.
   *
   */
  isBookmarked : function(aUrl) {
    traceIn("isBookmarked");
    try {
      return this._getBookmarkResource(aUrl, false);
    } catch (e) {
      logError("isBookmarked", e);
    } finally {
      traceOut("isBookmarked");
    }
    return null;
  },

  /* Check if the given feed url is present in the bookmark database.
   *
   * @param aFeedUrl url of the livemark to be checked.
   *
   * @return bookmark resource if present, null otherwise.
   */
  isLivemarked : function(aFeedUrl) {
    traceIn("isLivemarked");
    try {
      return this._getSource(grscFeedUrl, gRdfService.GetLiteral(aFeedUrl));
    } catch (e) {
      logError("isLivemarked", e);
    } finally {
      traceOut("isLivemarked");
    }
    return null;
  },

  /*********************************************************************
   *                     Setter and Getter Functions                   *
   *********************************************************************/

  setBookmarkKeyAsString : function(aUrl, aKey, aValue) {
    try {
      traceIn("setBookmarkKeyAsString");
      this._setBookmarkKey(aUrl, aKey, gRdfService.GetLiteral(aValue));
    } catch (e) {
      logError("setBookmarkKeyAsString", e);
    } finally {
      traceOut("setBookmarkKeyAsString");
    }
  },

  setBookmarkKeyAsDate : function(aUrl, aKey, aValue) {
    traceIn("setBookmarkKeyAsDate");
    try {
      this._setBookmarkKey(aUrl, aKey, gRdfService.GetDateLiteral(aValue));
    } catch (e) {
      logError("setBookmarkKeyAsDate", e);
    }
  },

  setBookmarkKeyAsInt : function(aUrl, aKey, aValue) {
    traceIn("setBookmarkKeyAsInt");
    try {
      this._setBookmarkKey(aUrl, aKey, gRdfService.GetIntLiteral(aValue));
    } catch (e) {
      logError("setBookmarkKeyAsInt", e);
    } finally {
      traceOut("setBookmarkKeyAsInt");
    }
  },

  setBookmarkKeysAsString : function(aUrl, aLength, aKeys, aValues) {
    traceIn("setBookmarkKeysAsString");
    try {
      var bookmarkResource = this._getBookmarkResource(aUrl, false);
      if (bookmarkResource) {
        this._checkKeyAndValues(aKeys, aValues, aLength);
        for (var counter = 0; counter < aLength; ++counter) {
          this._setBookmarkResourceKey(bookmarkResource, aKeys[counter],
            gRdfService.GetLiteral(aValues[counter]));
        }
      }
    } catch (e) {
      logError("setBookmarkKeysAsString", e);
    } finally {
      traceOut("setBookmarkKeysAsString");
    }
  },

  setBookmarkKeysAsDate : function(aUrl, aLength,  aKeys, aValues) {
    traceIn("setBookmarkKeysAsDate");
    try {
      var bookmarkResource = this._getBookmarkResource(aUrl, false);
      if (bookmarkResource) {
        this._checkKeyAndValues(aKeys, aValues, aLength);
        for (var counter = 0; counter < aLength; ++counter) {
          this._setBookmarkResourceKey(bookmarkResource, aKeys[counter],
            gRdfService.GetDateLiteral(aValues[counter]));
        }
      }
    } catch (e) {
      logError("setBookmarkKeysAsDate", e);
    } finally {
      traceOut("setBookmarkKeysAsDate");
    }
  },

  setBookmarkKeysAsInt : function(aUrl, aLength,  aKeys, aValues) {
    traceIn("setBookmarkKeysAsInt");
    try {
      var bookmarkResource = this._getBookmarkResource(aUrl, false);
      if (bookmarkResource) {
        this._checkKeyAndValues(aKeys, aValues, aLength);
        for (var counter = 0; counter < aLength; ++counter) {
          this._setBookmarkResourceKey(bookmarkResource, aKeys[counter],
            gRdfService.GetIntLiteral(aValues[counter]));
        }
      }
    } catch (e) {
      logError("setBookmarkKeysAsInt", e);
    } finally {
      traceOut("setBookmarkKeysAsInt");
    }
  },

  getBookmarkStringValues : function(aUrl, aInCount, aKeys, aOutCount) {
    traceIn("getBookmarkStringValues");
    try {
      return this._getBookmarkKeyValues(aUrl, aInCount, aKeys, aOutCount,
        Components.interfaces.nsIRDFLiteral);
    } catch (e) {
      logError("getBookmarkStringValues", e);
    } finally {
      traceOut("getBookmarkStringValues");
    }
  },

  getBookmarkIntValues : function(aUrl, aInCount, aKeys, aOutCount) {
    traceIn("getBookmarkIntValues");
    try {
      return this._getBookmarkKeyValues(aUrl, aInCount, aKeys, aOutCount,
        Components.interfaces.nsIRDFInt);
    } catch (e) {
      logError("getBookmarkIntValues", e);
    } finally {
      traceOut("getBookmarkIntValues");
    }
  },

  getBookmarkDateValues : function(aUrl, aInCount, aKeys, aOutCount) {
    traceIn("getBookmarkDateValues");
    try {
      return this._getBookmarkKeyValues(aUrl, aInCount, aKeys, aOutCount,
        Components.interfaces.nsIRDFDate);
    } catch (e) {
      logError("getBookmarkDateValues", e);
    } finally {
      traceOut("getBookmarkDateValues");
    }
  },

  _getBookmarkKeyValues : function(aUrl, aInCount, aKeys, aOutCount,
    aInterface) {
    bookmarkResource = this._getBookmarkResource(aUrl, false);
    if (!bookmarkResource) {
      aOutCount.value = 0;
      return [];
    }

    if (aKeys.length < aInCount) {
      throw Components.Exception(
        "Keys is not having enough elements. Expected: " + aInCount + " Got: "
          + aKeys.length);
    }

    var outArray = new Array();

    for (var counter = 0; counter < aInCount; ++counter) {
      outArray.push(this._getProperty(bookmarkResource,
        gRdfService.GetResource(NS_BOOKMARK_BASE + aKeys[counter]),
          aInterface));
    }
    aOutCount.value = outArray.length;
    return outArray;
  },

  _getProperty : function(resource, predicate, aInterface) {
    var value = this._fileDatasource.GetTarget(resource, predicate, true);
    if (! value) {
      yDebug.print("value for " + predicate.Value +
        " not found. Setting it to null");
      return null;
    } else {
      value.QueryInterface(aInterface);
      return value.Value;
    }
  },

  setLastUpdateTime : function(aTimeString) {
    traceIn("setLastUpdateTime");
    try {
      this._setStringProperty(this._getBookmarkRoot().Resource,
        grscLastUpdateDate, aTimeString);
      this._scheduleFlush();
    } catch (e) {
      logError("setLastUpdateTime", e);
    } finally {
      traceOut("setLastUpdateTime");
    }
  },

  getLastUpdateTime : function() {
    traceIn("getLastUpdateTime");
    try {
      return this._getProperty(this._getBookmarkRoot().Resource,
        grscLastUpdateDate, CI.nsIRDFLiteral);
    } catch (e) {
      logError("getLastUpdateTime", e);
    } finally {
      traceOut("getLastUpdateTime");
    }
  },

  _checkKeyAndValues : function(aKeys, aValues, aLength) {
    if ((aKeys.length < aLength) || (aValues.length < aLength)) {
      throw Components.Exception("Either keys or values are not having "
        + aLength + " number of items");
    }
  },

  _setBookmarkResourceKey : function(bookmarkResource, aKey, newValue) {
    this._setProperty(bookmarkResource,
      gRdfService.GetResource(NS_BOOKMARK_BASE + aKey), newValue);
    this._scheduleFlush();
  },

  _setBookmarkKey : function (aUrl, aKey, newValue) {
    var bookmarkResource = this._getBookmarkResource(aUrl, false);
    if (bookmarkResource) {
      this._setBookmarkResourceKey(bookmarkResource, aKey, newValue);
    }
  },

  /**
   *  Create a new empty _datasource which would be used to hold the
   *  search results
   */
  getSearchDataSource : function () {
    traceIn("getSearchDataSource");
    try {
      return this._searchDatasource;
    } catch (e) {
      logError("getSearchDataSource", e);
    } finally {
      traceOut("getSearchDataSource");
    }
  },

  /**
   * Create a new container to store search results if it does not exist
   * in the search _datasource @param aStoreNumber number to identify the
   * store e.g 1 for sidebar,  2 for popup
   */
  _createSearchStore : function (aStoreNumber) {
    var searchRootRes = gRdfService.GetResource("NC:YBSearch" + aStoreNumber);
    var tagSearchRootRes = gRdfService.GetResource("NC:YBTagSearch"
      + aStoreNumber);
    var bookmarkSearchRootRes = gRdfService.GetResource("NC:YBBookmarkSearch" +
      aStoreNumber);

    var tagSearchRoot = gRdfContainerUtils.MakeSeq(this._searchDatasource,
      tagSearchRootRes);
    var bookmarkSearchRoot = gRdfContainerUtils.MakeSeq(this._searchDatasource,
      bookmarkSearchRootRes);

    if (!gRdfContainerUtils.IsSeq(this._searchDatasource, searchRootRes)) {
      var searchRoot = gRdfContainerUtils.MakeSeq(this._searchDatasource,
        searchRootRes);
      searchRoot.AppendElement(tagSearchRootRes);
      searchRoot.AppendElement(bookmarkSearchRootRes);
    }

    return {
      tagSearchRoot : tagSearchRoot,
      bookmarkSearchRoot : bookmarkSearchRoot
    };
  },

  /**
   * Search bookmarks and tags, and set the results in the search _datasource
   * (NC:YBSearch + aStoreNumber)
   *
   * @param aKeyword keyword to be searched
   * @param aStoreNumber number to identify the store e.g 1 for sidebar,
   * 2 for popup
   */
  search : function (aKeyword, aStoreNumber) {
    traceIn("search");
    try {
      var tagCounter = this.searchTags(aKeyword, aStoreNumber);
      var bookmarkCounter = this.searchBookmarks(aKeyword, aStoreNumber);

      return tagCounter + bookmarkCounter;
    } catch (e) {
      logError("search", e);
    } finally {
      traceOut("search");
    }
    return 0;
  },

  /**
   * Search tag folders and add them to the search _datasource
   * (NC:YBTagsSearch + aStoreNumber)
   * if their name contains the keyword
   *
   * @param aKeyword keyword to be searched
   * @param aStoreNumber number to identify the store e.g 1 for sidebar,
   * 2 for popup
   */
  searchTags : function (aKeyword, aStoreNumber) {
    traceIn("searchTags");
    try {
      if (this._tagSearchTimeout) {
        this._hiddenWindow.clearTimeout(this._tagSearchTimeout);
        this._tagSearchTimeout = null;
      } else {
        if (this._isTagSearching) {
          this._stopTagSearching = true;
          var self = this;
          this._hiddenWindow.setTimeout(function(self, aKeyword, aStoreNumber) {
               self.searchTags(aKeyword, aStoreNumber); }, 10,
               self, aKeyword, aStoreNumber);
          return 0;
        } else {
         this._stopTagSearching = false;
        }
      }

      this._isTagSearching = true;
      var store = this._createSearchStore(aStoreNumber);
      var tagSearchRoot = store.tagSearchRoot;
      var totalSearched = this._getTotalElementsToSearch();

      // Clear those left over by the previous search
      emptyContainer(tagSearchRoot);

      //get the new search results
      var keyword = aKeyword.toLowerCase();
      var tags = this._getTagRoot().GetElements();
      var tagResource;
      var name;
      var totalMatched = 0;

      var os = Components.classes["@mozilla.org/observer-service;1"].
                  getService(Components.interfaces.nsIObserverService);

      this._postSearchTagsBegin(os, keyword);
      this._isTagSearching = false;
      this._startSearchTagsTimer(tags, keyword, totalSearched,
        totalMatched, tagSearchRoot);
    } catch (e) {
      logError("searchTags", e);
    } finally {
      traceOut("searchTags");
    }
    return 0;
  },

  /**
   * searches given string for keywords. By default, it does a
   * disjunction search (returns true if str contains _ANY_ of
   * the keywords). Conjunction search can be specified using
   * the last arg
   */
  _searchStringForKeywords : function(str, keywords, conjunction) {
    if (keywords.length == 0) {
      return false;
    }
    if (conjunction == null) {
      conjunction = false;
    }

    str = str.toLowerCase();
    var nValidKeywords = 0, nMatches = 0;
    for (var i = 0; i < keywords.length; ++i) {
      if (keywords[i].length > 0) {
        ++nValidKeywords;
        if (str.indexOf(keywords[i]) != -1) {
          if (!conjunction) {
            return true;
          } else {
            ++nMatches;
          }
        }
      }
    }
    if (nMatches == nValidKeywords) {  // can only be conjunction
      return true;
    }
    return false;
  },

  _searchTags : function(tags, keyword, totalSearched, totalMatched,
    tagSearchRoot) {
    try {
      this._isTagSearching = true;

      var os = Components.classes["@mozilla.org/observer-service;1"].
                getService(Components.interfaces.nsIObserverService);
      var sofarSearched = 1;
      var allTagsSearched = false;
      if (keyword.indexOf('+') != -1) {
        // user is typing a conjunction search - no results here
        allTagsSearched = true;
      }

      var keywordLets = keyword.split(' ');
      if (! allTagsSearched) {
        while (tags.hasMoreElements()) {
          if (sofarSearched++ % SOFAR_SEARCHED == 0) {
            this._postSearchTagsProgress(os, totalSearched,
              sofarSearched, keyword);
            break;
          }

          var tagResource = tags.getNext();
          var found = this._findKeywords(tagResource, grscTagValue, keywordLets);

          if (found) {
            if (tagSearchRoot.IndexOf(tagResource) == -1) {
              tagSearchRoot.AppendElement(tagResource);
              totalMatched++;
            }
          }
        }
        if (! tags.hasMoreElements()) {
          allTagsSearched = true;
        }
      }

      this._isTagSearching = false;
      if (! this._stopTagSearching) {
        if (allTagsSearched) {
          this._postTagsEnd(os, totalMatched, keyword);
        } else {
          this._startSearchTagsTimer(tags, keyword, totalSearched,
            totalMatched, tagSearchRoot);
        }
      }
    } catch (e) {
      logError("_searchTags", e);
    }
  },

  /**
   * ASSUMPTION: All bookmarks and tags are searched
   *
   */
  _getTotalElementsToSearch : function() {
    return this.getTotalBookmarks() + this.getTotalTags();
  },

  /**
   * Search bookmarks and add them to the search _datasource
   * (NC:YBBookmarksSearch + aStoreNumner)
   * if their name, url or tags contains the keyword
   *
   * @param aKeyword keyword to be searched
   * @param aStoreNumber number to identify the store e.g 1 for sidebar,
   * 2 for popup
   */
  searchBookmarks : function (aKeyword, aStoreNumber) {
    traceIn("searchBookmarks");
    try {
      if (this._bookmarkSearchTimeout) {
        this._hiddenWindow.clearTimeout(this._bookmarkSearchTimeout);
        this._bookmarkSearchTimeout = null;
      } else {
        if (this._isBookmarkSearching) {
          this._stopBookmarkSearching = true;
          var self = this;
          this._hiddenWindow.setTimeout(function(self, aKeyword, aStoreNumber) {
             self.searchBookmarks(aKeyword, aStoreNumber);
          }, 10, self, aKeyword, aStoreNumber);
          return;
        } else {
          this._stopBookmarkSearching = false;
        }
      }

      this._isBookmarkSearching = true;
      yDebug.print ("Searching for " + aKeyword);
      var store = this._createSearchStore(aStoreNumber);
      var bookmarkSearchRoot = store.bookmarkSearchRoot;

      // remove all resources created by previous search
      emptyContainer(bookmarkSearchRoot);

      // get the new search results
      var keyword = aKeyword.toLowerCase();
      var bookmarks = this._getBookmarkRoot().GetElements();
      var totalSearched = this._getTotalElementsToSearch();
      var totalMatched = 0;

      var os = Components.classes["@mozilla.org/observer-service;1"].
                  getService(Components.interfaces.nsIObserverService);

      this._postSearchBookmarksBegin(os, keyword);
      this._isBookmarkSearching = false;
      this._startSearchBookmarksTimer(bookmarks, keyword, 
        totalSearched, totalMatched, bookmarkSearchRoot);
    } catch (e) {
      logError("searchBookmarks", e);
    } finally {
      traceOut("searchBookmarks");
    }
    return 0;
  },

  getTagsSearchResults: function(aStoreNumber, aCount) {

    var myTags = [];
    var tagsRoot = gRdfContainerUtils.MakeSeq(this._searchDatasource, gRdfService.GetResource("NC:YBTagSearch" + aStoreNumber));
    var tags = tagsRoot.GetElements();
    var hasMoreElements = tags.hasMoreElements;
    var getNext = tags.getNext;

    while ( hasMoreElements() ) {
        myTags[myTags.length] = this._getTargetLiteral(getNext(), grscTagValue);
    }

    aCount.value = myTags.length;
    return myTags;
  },

  getBookmarksSearchResults: function(aStoreNumber, aCount) {

      var myBookmarks = [];
      var bookmarkSearchRoot = gRdfContainerUtils.MakeSeq(this._searchDatasource, gRdfService.GetResource("NC:YBBookmarkSearch" + aStoreNumber));
      var bookmarkResources = bookmarkSearchRoot.GetElements();
      var hasMoreElements = bookmarkResources.hasMoreElements;
      var getNext = bookmarkResources.getNext;

      while ( hasMoreElements() ) {
          myBookmarks[myBookmarks.length] = getNext();    
      }

      aCount.value = myBookmarks.length;
      return myBookmarks;
  },

  _findKeywords : function(source, predicate, keywordLets, conjunction) {
    var s = this._fileDatasource.GetTarget(source, predicate, true);
    if (s) {
      s = s.QueryInterface(CI.nsIRDFLiteral).Value;
      return this._searchStringForKeywords(s, keywordLets, conjunction);
    }
    return false;
  },

  _searchBookmarks : function(bookmarks, keyword, 
    totalSearched, totalMatched, bookmarkSearchRoot) {
    try {
      this._isBookmarkSearching = true;
      var os = Components.classes["@mozilla.org/observer-service;1"].
                getService(Components.interfaces.nsIObserverService);
      var sofarSearched = 1;

      var conjuction = true;
      var keywordLets = keyword.split('+');
      var nKeywordLets = keywordLets.length;
      if (nKeywordLets == 1) {
        keywordLets = keyword.split(' ');
        nKeywordLets = keywordLets.length;
        conjuction = false;
      }
      var i, j, nMatches;

      while (bookmarks.hasMoreElements()) {
        if (sofarSearched++ % SOFAR_SEARCHED == 0) {
          this._postSearchBookmarksProgress(os, totalSearched,
            sofarSearched, keyword);
          break;
        }
        var bkResource = bookmarks.getNext();
        var found =
          this._findKeywords(bkResource, grscName, keywordLets, conjuction) ||
          this._findKeywords(bkResource, grscUrl, keywordLets, conjuction) ||
          this._findKeywords(bkResource, grscDesc, keywordLets, conjuction) ||
          this._findKeywords(bkResource, grscShortcut, keywordLets, conjuction);

        if (!found) {
          var tagsArr = [];
          var tags = this._fileDatasource.GetTargets(bkResource, grscTag, true);
          while (tags.hasMoreElements()) {
            var tagValue = tags.getNext().QueryInterface(CI.nsIRDFLiteral)
              .Value;
            var normTag = this._normalizeTag(tagValue);
            if (conjuction) { // save it for later use
              tagsArr.push(normTag);
            } else {
              found = this._searchStringForKeywords(normTag, keywordLets, false);
              if (found) {
                break;
              }
            }
          }
          if (conjuction) {
            nMatches = 0;
            var nTagsToSearch = nKeywordLets;
            for (i = 0; i < tagsArr.length; ++i) {
              for (j = 0; j < nTagsToSearch; ++j) {
                if (tagsArr[i].indexOf(keywordLets[j]) != -1) {
                  ++nMatches;
                  // push the current tag to the non searchable part of the
                  // array to prevent repeat hits, keeping it in the array
                  // ensures that it'll be searched for the next bookmark
                  var temp = keywordLets[nTagsToSearch - 1];
                  keywordLets[nTagsToSearch - 1]= keywordLets[j];
                  keywordLets[j] = temp;
                  --nTagsToSearch;

                  break;
                }
              }
              if (nMatches == nKeywordLets) {
                found = true;
                break;
              }
            }
          }
        }

        if (found && bookmarkSearchRoot.IndexOf(bkResource) == -1) {
          bookmarkSearchRoot.AppendElement(bkResource);
          totalMatched++;
        }
      }

      this._isBookmarkSearching = false;
      if (! this._stopBookmarkSearching) {
        if (!bookmarks.hasMoreElements()) {
          this._postSearchBookmarksEnd(os, totalMatched, keyword);
        } else {
            this._startSearchBookmarksTimer(bookmarks, keyword,
              totalSearched, totalMatched, bookmarkSearchRoot);
        }
      }
    } catch (e) {
      logError("_searchBookmarks", e);
    }
  },

  _startSearchBookmarksTimer : function(bookmarks, keyword, 
    totalSearched, totalMatched, bookmarkSearchRoot) {
    var self = this;
    this._bookmarkSearchTimeout =
      this._hiddenWindow.setTimeout(
      function(self, bookmarks, keyword, totalSearched,
        totalMatched, bookmarkSearchRoot) {
        self._searchBookmarks(bookmarks, keyword, 
          totalSearched, totalMatched, bookmarkSearchRoot);
      }, SEARCH_TIMEOUT, self, bookmarks, keyword, 
        totalSearched, totalMatched, bookmarkSearchRoot);
  },

  _startSearchTagsTimer : function(tags, keyword, 
    totalSearched, totalMatched, tagSearchRoot) {
    var self = this;
    this._tagSearchTimeout = this._hiddenWindow.setTimeout(
        function(self, tags, keyword, totalSearched,
          totalMatched, tagSearchRoot) {
            self._searchTags(tags, keyword, totalSearched,
              totalMatched, tagSearchRoot);
        }, SEARCH_TIMEOUT,
        self, tags, keyword, totalSearched, totalMatched,
          tagSearchRoot);
  },

  _postSearchEnd : function(os, totalMatched, keyword, name) {
    var subject = {
      type : name,
      totalMatched : totalMatched,
      keyword : keyword
    };
    subject.wrappedJSObject = subject;
    os.notifyObservers(subject, "ybookmarkSearch.end", name);
  },

  _postSearchBookmarksEnd : function(os, totalMatched, keyword) {
    this._postSearchEnd(os, totalMatched, keyword, BOOKMARKS);
  },

  _postTagsEnd : function(os, totalMatched, keyword, topic) {
    this._postSearchEnd(os, totalMatched, keyword, TAGS);
  },

  _postSearchBegin : function(os, keyword, name) {
    var subject = { type : name, keyword : keyword };
    subject.wrappedJSObject = subject;
    os.notifyObservers(subject, "ybookmarkSearch.begin", name);
  },

  _postSearchBookmarksBegin : function(os, keyword) {
    this._postSearchBegin(os, keyword, BOOKMARKS);
  },

  _postSearchTagsBegin : function(os, keyword) {
    this._postSearchBegin(os, keyword, TAGS);
  },

  _postSearchProgress : function(os, totalSearched,
    sofarSearched, keyword, name) {
    var subject = {
      type : name,
      total : totalSearched,
      sofar : sofarSearched,
      keyword : keyword
    };
    subject.wrappedJSObject = subject;
    os.notifyObservers(subject, "ybookmarkSearch.inProgress", name);
  },

  _postSearchBookmarksProgress : function(os, totalSearched,
    sofarSearched, keyword) {
    this._postSearchProgress(os, totalSearched, sofarSearched, keyword,
      BOOKMARKS);
  },

  _postSearchTagsProgress : function(os, totalSearched,
    sofarSearched, keyword) {
    this._postSearchProgress(os, totalSearched, sofarSearched, keyword,
      TAGS);
  },
  /*
   * Get the tags suggestion based on the keyword input
   *
   * @param aKeyword keyword input
   *
   */
  getTagSuggestions : function(aKeyword) {
    traceIn("getTagSuggestions");
    var nsArray = new NSArray();
    try {
      if (! aKeyword || aKeyword.length == 0) {
        return nsArray;
      }

      var keyword = aKeyword.toLowerCase();
      var plusIndex = keyword.lastIndexOf('+');
      if (plusIndex == keyword.length - 1) { // the user has typed nothing useful
        return nsArray;
      }
      if (plusIndex > -1) {
        // reducing search prefix to the last constituent
        keyword = keyword.substring(plusIndex + 1, keyword.length);
      }

      var jsArray = [];
      var tags = this._getTagRoot().GetElements();
      var found = false;
      while (tags.hasMoreElements()) {
        found = false;
        var tagResource = tags.getNext();
        var tag = this._getTargetValue(tagResource, grscTagValue);
        if (tag) {
          tag = tag.toLowerCase();
          if (tag.indexOf(keyword) == 0 && tag.length != keyword.length) {
             childCount = this._getTargetValue(tagResource, grscChildCount);
             if (childCount > 0) {
               jsArray.push({ tag : tag , count : childCount });
             }
          }
        }
      }

      // sort the array
      jsArray.sort(function(a, b) {
        var x = a.count;
        var y = b.count;

        var w = a.tag;
        var v = b.tag;

        return ((x == y) ? ((w < v) ? -1 : ((w > v) ? 1 : 0)) :
          ((x > y) ? -1 : ((x < y) ? 1 : 0)));
      });

      for (var i = 0; i < jsArray.length; i++) {
        var propertyBag = new HashPropertyBag();
        propertyBag.setProperty("tag", jsArray[i].tag);
        propertyBag.setProperty("count", jsArray[i].count);
        nsArray.appendElement(propertyBag, false);
      }
    } catch (e) {
      logError("getTagSuggestions", e);
    } finally {
      traceOut("getTagSuggestions");
    }

    return nsArray;
  },

  /*
   * Remove all tags for a given URL. This is useful when bookmark is
   * synched with the service.
   * Most services do not provide the data like since the last update
   * what tags were added and what tags were deleted. Using the new tags
   * list and removing the tags not in the list.  Then, adding the new ones in.
   *
   * @param bookmarkResource The bookmark for which tags to be removed.
   *
   */
  _removeAllTagsForResource : function (bookmarkResource) {
    var tags = this._fileDatasource.GetTargets(bookmarkResource, grscTag, true);
    while (tags.hasMoreElements()) {
      var tag = tags.getNext().QueryInterface(CI.nsIRDFLiteral);
      this._fileDatasource.Unassert(bookmarkResource, grscTag, tag, true);
      this._removeBookmarkFromTagContainer(tag.Value, bookmarkResource);
    }
    var favTags = this._favoriteTagsRoot.GetElements();
    while (favTags.hasMoreElements()) {
      var favTag = favTags.getNext();
      favTag.QueryInterface(Components.interfaces.nsIRDFResource);
      this._removeMatchingContent(favTag, bookmarkResource);
    }
  },

  _getResourceByPredicate : function (aName, predicate,
    insertIfAbsent, root) {
    var target = gRdfService.GetLiteral(aName);
    var resource = this._fileDatasource.GetSource(predicate, target, true);

    if (! resource) {
      if (insertIfAbsent) {
        resource = gRdfService.GetAnonymousResource();
        this._fileDatasource.Assert(resource, predicate, target, true);
        root.AppendElement(resource);
      }
    }
    return resource;
  },

  _getTagResource : function(aTag, insertIfAbsent) {
    /*
     * tags in the tagRoot are stored in lower case. But in bookmarks
     * it is stored as we got from the service provider.
     */
    var norTag = this._normalizeTag(aTag);
    return this._getResourceByPredicate(norTag, grscTagValue, insertIfAbsent,
      this._getTagRoot());
  },

  _getBookmarkResource : function(aUrl, insertIfAbsent) {
    return this._getResourceByPredicate(aUrl, grscUrl,
      insertIfAbsent, this._getBookmarkRoot());
  },

  _getFavoriteTagResouce : function(aTag, insertIfAbsent) {
    var norTag = this._normalizeTag(aTag);
    return this._getResourceByPredicate(norTag, grscFavoriteTagValue,
      insertIfAbsent, this._favoriteTagsRoot);
  },

  _getBundleResource : function(aName, insertIfAbsent) {
    var norName = this._normalizeTag(aName);
    return this._getResourceByPredicate(norName, grscBundleValue,
      insertIfAbsent, this._bundleRoot);
  },


  /*********************************************************************
   *                           Transaction Functions                   *
   *********************************************************************/

  /**
   *  Add a  transaction (e.g. add, edit and delete bookmark) to the _datasource
   *
   *  @param aType the type of the transaction
   *  @param aState the state of the transaction   i.e. 0 - uninitialized,
   *  1 = sent, 2 = completed
   *  @param aJSON the object which contains the bookmark's information
   *
   */
  addTransaction : function (aType, aState, aJSON) {
    traceIn("addTransaction");
    try {
      if (aJSON.wrappedJSObject) {
       aJSON = aJSON.wrappedJSObject;
      }

      if (aJSON["localOnly"] && aJSON["localOnly"] == "true") {
        switch(aType) {
          case "addBookmark":
            return;
          break;
          case "editBookmark":
            // change the type to a delete operation to ensure this is not on
            // remote
            aType = "deleteBookmark";
          break;
        }
      }

      var transactionResource = gRdfService.GetAnonymousResource();
      for (var name in aJSON) {
        if (name == "wrappedJSObject") {
          continue;
        }

        var val = "";
        if (name == "tags") {
          if (aJSON[name].enumerate) {
            var iter = aJSON[name].enumerate();
            while (iter.hasMoreElements()) {
              var str = iter.getNext();
              str.QueryInterface(Components.interfaces.nsISupportsString);
              if (val.length > 0) {
                val += " ";
              }
              val += str.data;
            }
          } else {
            val = aJSON[name].join(' ');
          }
        } else {
          val = aJSON[name];
        }
        if (val) {
          this._fileDatasource.Assert(transactionResource,
            gRdfService.GetResource(NS_TRANSACTION_BASE + name),
            gRdfService.GetLiteral(val), true);
        }
      }

      this._fileDatasource.Assert(transactionResource,
        gRdfService.GetResource(NS_TRANSACTION_BASE + "transactionType"),
        gRdfService.GetLiteral(aType), true);

      this._fileDatasource.Assert(transactionResource,
        gRdfService.GetResource(NS_TRANSACTION_BASE + "transactionState"),
        gRdfService.GetIntLiteral(aState), true);

      var time = parseInt(((new Date()).getTime())/1000) + "";
      this._fileDatasource.Assert(transactionResource,
        gRdfService.GetResource(NS_TRANSACTION_BASE + "transactionTime"),
        gRdfService.GetLiteral(time), true);
      this._transactionRoot.AppendElement(transactionResource);

      this._scheduleFlush();
    } catch (e) {
      logError("addTransaction", e);
    } finally {
      traceOut("addTransaction");
    }
  },

  /**
   *  Remove a transaction from the datasource
   *
   *  @param aType the type of the transaction
   *  @param aUrl the bookmark url
   *
   */
  removeTransaction : function (aType, aUrl) {
    traceIn("removeTransaction");
    try {
      var urlRes = gRdfService.GetResource(NS_TRANSACTION_BASE + "url");
      var typeRes = gRdfService.GetResource(NS_TRANSACTION_BASE +
        "transactionType");
      var stateRes = gRdfService.GetResource(NS_TRANSACTION_BASE +
        "transactionState");
      var txnResources = this._fileDatasource.GetSources(urlRes,
        gRdfService.GetLiteral(aUrl), true);

      while (txnResources.hasMoreElements()) {
        var txnResource = txnResources.getNext();
        var txnType = this._getTargetValue(txnResource, typeRes);
        if (txnType == aType) {
          this._deleteAllChildren(txnResource);
          this._transactionRoot.RemoveElement(txnResource, false);
          this._scheduleFlush();
          break;
        }
      }
    } catch (e) {
      logError("removeTransaction", e);
    } finally {
      traceOut("removeTransaction");
    }
  },
  /**
   *  Remove a transaction from the _datasource
   *
   *  @param aType the type of the transaction
   *  @param aUrl the bookmark url
   *
   */
  _removeTransactions : function (aType, aUrl) {
    var urlRes = gRdfService.GetResource(NS_TRANSACTION_BASE + "url");
    var typeRes = gRdfService.GetResource(NS_TRANSACTION_BASE +
      "transactionType");
    var txnResources = this._fileDatasource.GetSources(urlRes,
      gRdfService.GetLiteral(aUrl), true);

    while (txnResources.hasMoreElements()) {
      var txnResource = txnResources.getNext();

      var txnType = this._getTargetValue(txnResource, typeRes);
      var txnState = this._getTargetValue(txnResource, grscState);

      if (txnType == aType) {
        this._deleteAllChildren(txnResource);
        this._transactionRoot.RemoveElement(txnResource, false);
        this._scheduleFlush();
        break;
      }
    }
  },

  /**
   *  Remove all transactions in particular state.
   *
   *  @param aState the state of the transactions.
   *  i.e. 0 - uninitialized, 1= sent, 2 = completed, 10 = all
   */
  removeAllTransactions : function (aState) {
    traceIn("removeAllTransactions");
    try {
      var needFlush = false;
      var txnResources = this._transactionRoot.GetElements();
      while (txnResources.hasMoreElements()) {
        var txnResource = txnResources.getNext();
        var txnState = this._getTargetValue(txnResource, grscState);
        if (aState == 10 || txnState == aState) {
          this._deleteAllChildren(txnResource);
          this._transactionRoot.RemoveElement(txnResource, false);
          needFlush = true;
        }
      }

      if (needFlush) {
        this._scheduleFlush();
      }
    } catch (e) {
      logError("removeAllTransactions", e);
    } finally {
      traceOut("removeAllTransactions");
    }
  },

  /**
   *  Set the state of a transaction
   *
   *  @param aType the type of the transaction
   *  @param aUrl the bookmark url
   *  @param aState the state of the transactions. i.e.
   *  0 - uninitialized, 1 - sent, 2 - completed, 3 - failed
   */
  setTransactionState : function (aType, aUrl, aState) {
    traceIn("setTransactionState");
    try {
      var urlRes = gRdfService.GetResource(NS_TRANSACTION_BASE + "url");
      var typeRes = gRdfService.GetResource(NS_TRANSACTION_BASE +
        "transactionType");

      var txnResources = this._fileDatasource.
        GetSources(gRdfService.GetResource(NS_TRANSACTION_BASE + "url"),
        gRdfService.GetLiteral(aUrl), true);
      var newState = gRdfService.GetIntLiteral(aState);
      var time = parseInt(((new Date()).getTime())/1000) + "";
      var newTime = gRdfService.GetLiteral(time);

      while (txnResources.hasMoreElements()) {
        var txnResource = txnResources.getNext();

        url = this._getTargetValue(txnResource, urlRes);
        var txnType = this._getTargetValue(txnResource, typeRes);
        var txnState = this._getTargetValue(txnResource, grscState, true);


        if (url == aUrl && txnType == aType && txnState != aState) {
          this._fileDatasource.Change(txnResource, grscState,
            gRdfService.GetIntLiteral(txnState), newState, true);
          if (aState == 2) {
            this._removeTransactions(aType, aUrl);
          } else {
            var txnTime = this._fileDatasource.GetTarget(txnResource, grscTime, true);
            if (txnTime) {
              this._fileDatasource.Change(txnResource, grscTime, txnTime,
                newTime, true);
            } else {
              this._fileDatasource.Assert(txnResource, grscTime, newTime, true);
            }
          }
          this._scheduleFlush();
          break;
        }
      }
    } catch (e) {
      logError("setTransactionState", e);
    } finally {
      traceOut("setTransactionState");
    }
  },

  /**
   *  Set the state of all transactions
   *
   *  @param aState the state of the transaction.
   *  i.e. 0 - uninitialized, 1 - sent, 2 - completed. 3 - failed
   */
  _setAllTransactionsState : function (aState) {
    var transactionResources = this._transactionRoot.GetElements();
    var time = parseInt(((new Date()).getTime()) / 1000) + "";
    var newTime = gRdfService.GetLiteral(time);
    var newState = gRdfService.GetIntLiteral(aState);
    var toFlush = false;

    while (transactionResources.hasMoreElements()) {
      var transactionResource = transactionResources.getNext();
      var transactionState = this._getTargetValue(transactionResource,
        grscState);
      if (transactionState != aState) {
        this._fileDatasource.Change(transactionResource, grscState,
        gRdfService.GetIntLiteral(transactionState), newState, true);

        var transactionTime = this._fileDatasource.GetTarget(transactionResource,
          grscTime, true);
        if (transactionTime) {
          this._fileDatasource.Change(transactionResource, grscTime,
            transactionTime, newTime, true);
        } else {
          this._fileDatasource.Assert(transactionResource, grscTime, newTime, true);
        }
        toFlush = true;
      }
    }
    if (toFlush) {
      this._scheduleFlush();
    }
  },

  /**
   *  Get all transactions from the _datasource
   *
   *  @return the MutableArray contains all transactions in hashpropertybag
   *  format
   *
   */
  getTransactions : function () {
    traceIn("getTransactions");
    var nsArray = new NSArray();
    try {
      var txnResources = this._transactionRoot.GetElements();
      while (txnResources.hasMoreElements()) {
        var txnResource = txnResources.getNext();

        var propertyBag = new HashPropertyBag();
        var url = null;

        var txnProps = this._fileDatasource.ArcLabelsOut(txnResource);
        while (txnProps.hasMoreElements()) {
          var predicate = txnProps.getNext();
          var name = this._getResourcePropertyValue(predicate);
          name  = name.split("#")[1];
          var val = this._getTargetValue(txnResource, predicate);
          propertyBag.setProperty(name, val);
          if (name.match(/^url/)) {
            url = val;
          }

          yDebug.print("name:" + name + "   , val:" + val);
        }

        // check if the bookmark is having microsummary. If so,
        // set microsummary property to the URL for generator URI
        if (url && Components.classes[kMicrosummaryContractID]) {
          var msService = Components.classes[kMicrosummaryContractID].
            getService(kIMicrosummaryService);
          var bookmarkResource = this._getBookmarkResource(url, false);
          if (bookmarkResource) {
            var microsummary = msService.getMicrosummary(bookmarkResource);
            if (microsummary) {
              propertyBag.setProperty("microsummary",
                microsummary.generator.uri.spec);
            } else {
              yDebug.print("MICROSUMMARY NOT SET");
            }
          } else {
            yDebug.print("BOOKMARK IS NOT PRESENT");
          }
        } else {
          yDebug.print("EITHER URL IS EMPTY OR MICROSUMMARY NOT ENABLED",
            YB_LOG_MESSAGE);
        }
        nsArray.appendElement(propertyBag, false);
      }
    } catch (e) {
      logError("getTransactions", e);
    } finally {
      traceOut("getTransactions");
    }
    return nsArray;
  },

  /**
   *  Get the number of transactions in the _datasource
   *
   *  @param aType the type of the transaction. i.e. addBookmark,
   *    editBookmark, deleteBookmark, all/""
   *  @param aState the state of the transactions.
   *  i.e. 0 - uninitialized, 1 - sent, 2 - completed, 3 - failed, 10 - all
   *
   *  @return number the number of transactions
   *
   */
  getNumberOfTransactions : function(aType, aState) {
    traceIn("getNumberOfTransactions");
    try {
      var urlRes = gRdfService.GetResource(NS_TRANSACTION_BASE + "url");
      var typeRes = gRdfService.GetResource(NS_TRANSACTION_BASE
        + "transactionType");

      var result = 0;

      var txnResources = this._transactionRoot.GetElements();
      while (txnResources.hasMoreElements()) {
        var txnResource = txnResources.getNext();
        txnType = this._getTargetValue(txnResource, typeRes);
        txnState = this._getTargetValue(txnResource, grscState);

        if (aType == "all" || aType.length == 0 || txnType == aType) {
          if (txnState == aState || aState == 10) {
            result ++;
          }
        }
      }
      return result;
    } catch (e) {
      logError("getNumberOfTransactions", e);
    } finally {
      traceOut("getNumberOfTransactions");
    }
    return 0;
  },

  /**
   *  Reset the 'sent' and 'failed' transactions to 'uninitialized'
   *  after a period of time
   *
   */
  restateTransactions : function () {
    traceIn("restateTransactions");
    try {
      var urlRes = gRdfService.GetResource(NS_TRANSACTION_BASE + "url");
      var typeRes = gRdfService.GetResource(NS_TRANSACTION_BASE +
        "transactionType");

      var time = (new Date).getTime();
      const timeDiff = 60 * 1000;

      var txnResources = this._transactionRoot.GetElements();
      while (txnResources.hasMoreElements()) {
        var txnResource = txnResources.getNext();
        var url = this._getTargetValue(txnResource, urlRes);
        var txnState = this._getTargetValue(txnResource, grscState);
        var txnTime = this._getTargetValue(txnResource, grscTime);
        txnTime = parseInt(txnTime);
        if ((isNaN(txnTime) || ((txnTime * 1000) + timeDiff) < time) &&
          (txnState == 1 || txnState == 3)) {
          var txnType = this._getTargetValue(txnResource, typeRes);
          this.setTransactionState(txnType, url, 0);
          yDebug.print("Restate transaction to 0: " + url);
        } else {
          yDebug.print("Transaction too new to restate: " + url);
        }
      }
    } catch (e) {
      logError("restateTransactions", e);
    } finally {
      traceOut("restateTransactions");
    }
  },

  /**
   *  Reset all transactions at the browser startup.
   *  Operations include removing all completed transactions and
   *  reset other transactions' state to uninitialized
   */
  _resetTransactions : function() {
    this.removeAllTransactions(2);
    this._setAllTransactionsState(0);
  },

  /**
   *  Get the resource's property value
   *
   *  @param node the resource's property
   *
   *  @return the resource's property value
   */
  _getResourcePropertyValue : function(node) {
    if (node) {
      try {
        node = node.QueryInterface(Components.interfaces.nsIRDFLiteral);
        return node.Value;
      } catch (e) {
        try {
          node = node.QueryInterface(Components.interfaces.nsIRDFInt);
          return node.Value;
        } catch (e) {
          node = node.QueryInterface(Components.interfaces.nsIRDFResource);
          return node.Value;
        }
      }
    }
    return "";
  },

  _getTargetValue : function(source, predicate) {
    return this._getResourcePropertyValue(
      this._fileDatasource.GetTarget(source, predicate, true));
    return "";
  },
  /**
   *  Get all bookmarks' metahash and urlhash from the _datasource
   *
   *  @return the MutableArray contains all transactions
   *  and each of them is in hashPropertyBag format
   *
   */
  getBookmarkHashes : function () {
    traceIn("getBookmarkHashes");
    var nsArray = new NSArray();
    try {
      var bookmarks = this._getBookmarkRoot().GetElements();
      counter = 0;
      while (bookmarks.hasMoreElements()) {
        counter++;
        var bookmarkResource = bookmarks.getNext();
        var url = this._getTargetValue(bookmarkResource, grscUrl, true);
        var localOnly = this._getTargetValue(bookmarkResource, grscLocalOnly);
        if (localOnly == "true") {
          yDebug.print("====>getBookmarkHashes (Local only) <== " + url,
            YB_LOG_MESSAGE);
        } else {
          var hash = this._getTargetValue(bookmarkResource, grscHash);
          if (hash) {
            var metahash = this._getTargetValue(bookmarkResource, grscMetaHash);
            var data = new HashPropertyBag();
            data.setProperty("hash", hash);
            data.setProperty("metahash", metahash);
            nsArray.appendElement(data, false);
            if (!metahash) {
              yDebug.print("====>getBookmarkHashes metahash is missing <== "
                + url, YB_LOG_MESSAGE);
            }
          } else {
            yDebug.print("====>getBookmarkHashes hash is missing <== " + url,
              YB_LOG_MESSAGE);
          }
        }
      }

      yDebug.print("Local hashes counter :" + counter, YB_LOG_MESSAGE);
    } catch (e) {
      logError("getBookmarkHashes", e);
    } finally {
      traceOut("getBookmarkHashes");
    }
    return nsArray;
  },

  /**
   * Delete the bookmark and all its associated tags from the database.
   * If same tag is used by multiple bookmarks, only the association
   * between bookmark and the tag is removed. Tag is retained in the system.
   *
   * @param aHash boookmark which contain this url hash would be removed from
   * the system.
   *
   * @return false if url hash is not present in the system, true otherwise.
   *
   */
  deleteBookmarkForHash : function (aHash) {
    traceIn("deleteBookmarkForHash");
    try {
      var hashResource = gRdfService.GetLiteral(aHash);
      var bookmarkResource = this._fileDatasource.GetSource(grscHash, hashResource,
        true);
      var url = this._getTargetValue(bookmarkResource, grscUrl);
      if (url) {
        yDebug.print("Delete url ===> " + url);
        return this.deleteBookmark(url);
      } else {
        return false;
      }
    } catch (e) {
      logError("deleteBookmarkForHash", e);
    } finally {
      traceOut("deleteBookmarkForHash");
    }
    return false;
  },

  getBundles : function(outCount) {
    traceIn("getBundles");
    var result = [];
    try {
      var bundles = this._bundleRoot.GetElements();
      while (bundles.hasMoreElements()) {
        var bnRsrc = bundles.getNext().QueryInterface(CI.nsIRDFResource);
        var bnJson = this._genBundleJSON(bnRsrc);
        if (bnJson) {
          result.push(bnJson);
        }
      }
    } catch (e) {
      logError("getBundles", e);
    } finally {
      traceOut("getBundles");
    }
    if (outCount) {
      outCount.value = result.length;
    }
    return result;
  },
  
  getBundle : function(aBundle) {
    traceIn("getBundle");
    try {
      var bnResource = this._getBundleResource(aBundle, false);
      if (bnResource) {
        return this._genBundleJSON(bnResource);
      } 
    } catch (e) {
      logError("getBundle", e);
    }
    return null;
  },
  
  setBundles : function(aBundles) {
    traceIn("setBundles");
    try {
      aBundles.QueryInterface(Components.interfaces.nsIArray);
      for (var e = aBundles.enumerate(); e.hasMoreElements(); ) {
        var bag = e.getNext().QueryInterface(CI.nsIPropertyBag);
        var name = bag.getProperty("name").
          QueryInterface(CI.nsISupportsString).data;
        var tags = bag.getProperty("tags").
          QueryInterface(CI.nsISupportsString).data;
        tags = ybookmarksUtils.jsArrayToNs(tags.split(" "));
        var bundle = {
          name : name,
          tags : tags
        };
        this.setBundle(bundle);
      }
    } catch (e) {
      logError("setBundles", e);
    } finally {
      traceOut("setBundles");
    }
  },
  
  setBundle : function(aBundle) {
    traceIn("setBundle");
    try {
      var bnResource = this._getBundleResource(aBundle.name, true);
      var bnContainer = gRdfContainerUtils.MakeSeq(this._fileDatasource,
        bnResource);    
      emptyContainer(bnContainer);

      for(var i = 0; i < aBundle.tags.length; i++) {
        var nsTag = aBundle.tags.queryElementAt(i,
          Components.interfaces.nsISupportsString);
        var tagResource = this._getTagResource(nsTag.data, true);
        bnContainer.AppendElement(tagResource);
      }

      if (aBundle.order) {
        this._setStringProperty(bnResource, grscBundleOrder, aBundle.order);
      } else if (! this._fileDatasource.GetTarget(bnResource,
        grscBundleOrder, true)) {
        this._setStringProperty(bnResource, grscBundleOrder,
          FAVTAG_ORDER_DEFAULT);
      }
      this._scheduleFlush();
    } catch (e) {
      logError("setBundle", e);
    } finally {
      traceOut("setBundle");
    }
  },
  
  clearBundles : function () {
    var bundles = this._bundleRoot.GetElements();
    while (bundles.hasMoreElements()) {
      var bnRsrc = bundles.getNext().QueryInterface(CI.nsIRDFResource);
      this._removeBundle(bnRsrc);
      this._bundleRoot.RemoveElement(bnRsrc, false);
      this._scheduleFlush();
    }
  },
  
  deleteBundle : function (aBundle) {
    var bnResource = this._getBundleResource(aBundle, false);
    this._deleteAllChildren(bnResource);
    this._removeFromBundlesRoot(bnResource);
    this._scheduleFlush();
  },

  moveBundle : function (aBundle, aIndex) {
    var bnResource = this._getBundleResource(aBundle, false);

    if (bnResource && this._bundleRoot.IndexOf(bnResource) != -1) {
      this._bundleRoot.RemoveElement(bnResource, true);
      this._bundleRoot.InsertElementAt(bnResource, aIndex, true);
      this._scheduleFlush();
    }
  },

  _removeBundle : function(bundleResource) {
    var tags = gRdfContainerUtils.MakeSeq(this._fileDatasource, bundleResource);
    var tagEnum = tags.GetElements();
    while (tagEnum.hasMoreElements()) {
      var tagResource = tagEnum.getNext();
      if (this._getTargetInt(tagResource, grscChildCount) == 0) {
        this._deleteAllChildren(tagResource);
        this._removeFromTagRoot(tagResource);
      }
    }
    this._deleteAllChildren(bundleResource);
  },

  _genBundleJSON : function(aBundleResource) {
    var name = this._fileDatasource.GetTarget(aBundleResource,
      grscBundleValue, true);
    if (name) {
      name = name.QueryInterface(Components.interfaces.nsIRDFLiteral).Value;
    } else {
      yDebug.print("Name resource not found for " + aBundleResource.Value);
      name = "";
    }
    var tagContainer = gRdfContainerUtils.MakeSeq(this._fileDatasource,
      aBundleResource);
    var tagEnum = tagContainer.GetElements();
    var nsTags = new NSArray();
    while (tagEnum.hasMoreElements()) {
      var tagRsrc = tagEnum.getNext().QueryInterface(CI.nsIRDFResource);
      var tagLiteral = this._fileDatasource.GetTarget(tagRsrc, grscTagValue, true);
      if (tagLiteral) {
        tagLiteral.QueryInterface(CI.nsIRDFLiteral);
        var nsTag = new NSString();
        nsTag.data = tagLiteral.Value;
        nsTags.appendElement(nsTag, false);
      } else {
        yDebug.print("tag " + tagRsrc.Value + " has no name");
      }
    }

    var orderLiteral = this._fileDatasource.GetTarget(aBundleResource,
      grscBundleOrder, true);
    var order = orderLiteral ?
      orderLiteral.QueryInterface(CI.nsIRDFLiteral).Value :
      FAVTAG_ORDER_DEFAULT;

    var retVal =  {
      name : name,
      tags : nsTags,
      order : order
    };
    retVal.wrappedJSObject = retVal;

    return retVal;
  },
  
  /**
   * Creates a new triplet <subject, predicate, newValue> if there
   * is no triplet having subject and predicate. If there does
   * exist a triplet for subject and predicate, replaces the object
   * with the new value.
   */
  _setProperty : function(subject, predicate, newValue) {
    var currentValue = this._fileDatasource.GetTarget(
      subject, predicate, true);
    if (currentValue) {
      this._fileDatasource.Change(subject, predicate, currentValue,
        newValue, true);
    } else {
      this._fileDatasource.Assert(subject, predicate, newValue, true);
    }
  },

  _setStringProperty : function(subject, predicate, value) {
    this._setProperty(subject, predicate, gRdfService.GetLiteral(value));
  },

  _setBooleanProperty : function(subject, predicate, value) {
    this._setProperty(subject, predicate, gRdfService.GetLiteral(value));
  },

  _setDateProperty : function(subject, predicate, value) {
    this._setProperty(subject, predicate, gRdfService.GetDateLiteral(value));
  },

  _setSharedFlag : function(subject, aShared) {
    this._setBooleanProperty(subject, grscShared, aShared);
  },

  _setLocalOnlyFlag : function(subject, localOnly) {
    this._setBooleanProperty(subject, grscLocalOnly, localOnly);
  },

  QueryInterface : function(aIID) {
    if (!aIID.equals(nsIYBookmarksStoreService) &&
       !aIID.equals(nsISupports)) {
         throw Components.results.NS_ERROR_NO_INTERFACE;
    }

    return this;
  }
};

/*
 * Class factory
 */
function factory(filename) {
  return {
    _filename : filename,
    _singletonObj : null,

    createInstance : function(aOuter, aIID) {
      yDebug.print("createInstance called in nsIFactory object");
      if (aOuter != null) {
        throw Components.results.NS_ERROR_NO_AGGREGATION;
      }
      if (!this._singletonObj) {
        this._singletonObj = new YBookmarksStoreService(this._filename);
      }
      return this._singletonObj.QueryInterface(aIID);
    }
  };
}

var YBookmarksStoreServiceFactory = factory("delicious.rdf");
var YBookmarksStoreServiceTestFactory = factory("delicious-test.rdf");

/*
 * Module definition
 */

var YBookmarksStoreServiceModule = {

  registerSelf : function(aCompMgr, aFileSpec, aLocation, aType) {
    yDebug.print("Registering YBookmarksStoreServiceModule", YB_LOG_MESSAGE);
    yDebug.print("registerSelf: aFileSpec => " + aFileSpec);
    yDebug.print("registerSelf: aLocation => " + aLocation);
    yDebug.print("registerSelf: aType => " + aType);
    aCompMgr = aCompMgr.QueryInterface(
      Components.interfaces.nsIComponentRegistrar);
    aCompMgr.registerFactoryLocation(CLASS_ID, CLASS_NAME, CONTRACT_ID,
      aFileSpec, aLocation, aType);
    aCompMgr.registerFactoryLocation(TEST_CLASS_ID, TEST_CLASS_NAME,
      TEST_CONTRACT_ID, aFileSpec, aLocation, aType);
  },

  unregisterSelf : function (aCompMgr, aLocation, aType) {
    yDebug.print("unregisterSelf: aLocation => " + aLocation, YB_LOG_MESSAGE);
    yDebug.print("unregisterSelf: aType => " + aType);
    aCompMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar);
    aCompMgr.unregisterFactoryLocation(CLASS_ID, aLocation);
    aCompMgr.unregisterFactoryLocation(TEST_CLASS_ID, aLocation);
  },

  getClassObject : function(aCompMgr, aCID, aIID) {
    yDebug.print("getClassObject: aCID => " + aCID);
    yDebug.print("getClassObject: aIID => " + aIID);
    if (!aIID.equals(Components.interfaces.nsIFactory)) {
      throw Components.results.NS_ERROR_NOT_IMPLEMENTED;
    }

    if (aCID.equals(CLASS_ID)) {
      return YBookmarksStoreServiceFactory;
    } else if (aCID.equals(TEST_CLASS_ID)) {
      return YBookmarksStoreServiceTestFactory;
    }
    throw Components.results.NS_ERROR_NO_INTERFACE;
  },

  canUnload : function(aCompMgr) {
    return true;
  }
};

function NSGetModule(aCompMgr, aFileSpec) {
  yDebug.print("YBookmarksStoreServiceModule2 GetModule");

  return YBookmarksStoreServiceModule;
}
