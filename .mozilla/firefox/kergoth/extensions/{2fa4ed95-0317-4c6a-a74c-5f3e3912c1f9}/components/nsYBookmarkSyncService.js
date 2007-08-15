/**
 * Documentation about bookmark sync
 *   
 * When the first instance of firefox browser is opened, the sync function is called. 
 * First of all, the transaction list stored in the extra datasource is checked and all the 
 * pending transactions are sent to the remote server. There are three types of transaction: 
 * addBookmark, editBookmark and deleteBookmark.  Generally, the transaction list should be empty 
 * when the sync function is called because all these transactions should be sent to the server 
 * immediately after the user carries out an operation. e.g. adding/editing/deleteing a bookmark. 
 * Then, a timeout is set to call sync functionnitself again after X mins (5 mins by default).  
 * After that, a "update" request would be sent to server to get the last update time of user's 
 * bookmarks and compare the remote time with the local time stored in the extra datasource. 
 * If the local update time is empty/null, a full sync will be carried out. 
 * If the remote update time is greater than the local time or local update time is equal 
 * to -1, an incremental sync will be carried out.
 * 
 * Full sync - bookmarks are downloaded in chunks and are added to the local store.
 * Incremental sync - the local bookmark hashes and the remote bookmark hashes are compared.  
 * The bookmarks which only exist in the remote would be downloaded from the server and add to the local list.  
 * The bookmarks which only exist in the local would be deleted from the local list. 
 *
 */

/*
 * Constants
 */
const nsIYBookmarkSyncService = Components.interfaces.nsIYBookmarkSyncService;
const nsISupports = Components.interfaces.nsISupports;
var DEL_ADD_BOOKMARK_WAIT = 8 * 1000;
var DEL_CHUNK_WAIT = 8 * 1000;
var DEL_CHUNK_SIZE = 50;
const DEL_SYNC_INTERVAL = 5;  //mins
const DEL_IS_SYNCING_WAIT = 60 * 1000;
const DEL_SENDING_TRANSACIIONS_WAIT = 5 * 1000;
const DEL_HASH_REQUESET_AFTER_TRANS_WAIT = 5 * 1000;

const CLASS_ID = Components.ID("{723A9B07-CA88-4386-B916-5E180837EDA8}");
const CLASS_NAME = "Sync Local Bookmarks with remote service";
const CONTRACT_ID = "@mozilla.org/ybookmarks-sync-service;1";

const kDelContractID = "@yahoo.com/socialstore/delicious;1";

/**********************************************************
 * Load yDebug.js
 **********************************************************/
( ( Components.classes["@mozilla.org/moz/jssubscript-loader;1"] ).getService( 
     Components.interfaces.mozIJSSubScriptLoader ) ).loadSubScript( 
        "chrome://ybookmarks/content/yDebug.js" ); 

/**********************************************************
 * Load ybookmarksUitl.js
 **********************************************************/
( ( Components.classes["@mozilla.org/moz/jssubscript-loader;1"] ).getService( 
     Components.interfaces.mozIJSSubScriptLoader ) ).loadSubScript( 
        "chrome://ybookmarks/content/ybookmarksUtils.js" ); 

/**
 *  Download the missing bookmarks from remote and add them to the local store
 *
 *  @param hashes the array of bookmark hashes for downloading the remote bookmarks
 *  @param lastUpdateTime the last update time of the remote bookmarks
 */
function YBookmarkSyncService_download_diff (hashes, lastUpdateTime) {
   
   var delreader = Components.classes[kDelContractID].
       getService(Components.interfaces.nsISocialStore);
   
   var cb = {
      onload: function(posts) {
      
        var bookmarksStore =
            (Components.classes["@mozilla.org/ybookmarks-store-service;1"].
             getService(Components.interfaces.nsIYBookmarksStoreService));
        
        var notifyData = null;
        if ( posts.length ) {
          notifyData = "add-to-ds-begin";
          Components.classes["@mozilla.org/observer-service;1"].
               getService(Components.interfaces.nsIObserverService).
              notifyObservers(null, "ybookmark.syncInfo", notifyData); 
        }
        
        var post;
        for (var i = 0; i < posts.length; i++) {
          post = 
              posts.queryElementAt(i,
                                   Components.interfaces
                                   .nsIWritablePropertyBag);

          _YBookmarksSyncHelper.updateStoreFromPost( bookmarksStore, post );

          if ( i == (posts.length - 1)) {
             notifyData = "add-to-ds-end";
             Components.classes["@mozilla.org/observer-service;1"].
                                getService(Components.interfaces.nsIObserverService).
                notifyObservers(null, "ybookmark.syncInfo", notifyData); 
          } 
        }
        
         yDebug.print ( "We are done with incremental sync..." );
         YBookmarksSyncService._isSyncing = false;
         bookmarksStore.setLastUpdateTime(lastUpdateTime);
         bookmarksStore.flush(false); 
         notifyData = "all-done";

         Components.classes["@mozilla.org/observer-service;1"]
           .getService(Components.interfaces.nsIObserverService)
                   .notifyObservers(null, "ybookmark.syncDone", notifyData);        
      
      },
      
      onerror : function (posts) {
         yDebug.print("UNABLE to download user's delicious bookmarks based on the hashes", YB_LOG_MESSAGE);
         YBookmarksSyncService._isSyncing = false;
         var notifyData = "add-to-ds-end";
         Components.classes["@mozilla.org/observer-service;1"].
              getService(Components.interfaces.nsIObserverService).
         notifyObservers(null, "ybookmark.syncInfo", notifyData);
      }
   };
   
   if (hashes.length > 0) {
     delreader.getBookmarksForHashes(hashes, cb);
   }
   else {
     yDebug.print ( "We are done with incremental sync..." );   
     var bookmarksStore =
          (Components.classes["@mozilla.org/ybookmarks-store-service;1"].
            getService(Components.interfaces.nsIYBookmarksStoreService));
     YBookmarksSyncService._isSyncing = false;
     bookmarksStore.setLastUpdateTime(lastUpdateTime);
     bookmarksStore.flush(false); 
     var notifyData = "all-done";
     Components.classes["@mozilla.org/observer-service;1"]
     .getService(Components.interfaces.nsIObserverService)
                   .notifyObservers(null, "ybookmark.syncDone", notifyData);        
   }
}

/**
 * Delete some local bookmarks
 * 
 * @param hashes the array of bookmark hashes for deleting some local bookmarks
 */
function YBookmarkSyncService_delete_diff (hashes) {
  
  var bookmarksStore = Components.classes["@mozilla.org/ybookmarks-store-service;1"].
           getService(Components.interfaces.nsIYBookmarksStoreService);         
  var urlhash, url;
  for (var i = 0; i < hashes.length; i++) {
     urlhash = hashes.queryElementAt(i, Components.interfaces.nsISupportsString);
     bookmarksStore.deleteBookmarkForHash(urlhash);
  }
}  

function _convertHashesFromNSArrayToJSObject(nsArray) {

  var jsArray = new Object();
  var post, urlhash;
  for (var i=0; i < nsArray.length; i++) {
     post = nsArray.queryElementAt(i,
                                   Components.interfaces
                                   .nsIWritablePropertyBag);             
     urlhash = post.getProperty("hash");
     jsArray[urlhash] = post.getProperty("metahash");
     //yDebug.print("Hash===>" + urlhash + ":" + jsArray[urlhash]);
  }
  
  return jsArray;
}

/**
 * Compare the local bookmark hashes and remote bookmark hashes
 *
 * @param localHashList the array of local bookmark hashes
 * @param remoteHashList the array of remote bookmark hashes
 * @return reult the array of two sets of bookmarks hashes: one for downloading
 * bookmarks from remote and one for deleting local bookmarks
 *
 */
function _compareBookmarkHashes(localHashList, remoteHashList) {

  const NSArray = new Components.Constructor("@mozilla.org/array;1", 
                                             Components.interfaces.nsIMutableArray);
  const NSString = new Components.Constructor("@mozilla.org/supports-string;1",
                                              Components.interfaces.nsISupportsString);

   var result = new Array();
   var deleteList = new NSArray();
   var downloadList = new NSArray();
   var remoteMatch;

   var localMatch, str;
   for (var remoteUrlHash in remoteHashList) {
     
     localMatch = localHashList[remoteUrlHash];
     if (localMatch) {
       if (remoteHashList[remoteUrlHash] != localMatch) {
         yDebug.print("Bookmark was edited => download " + remoteUrlHash, YB_LOG_MESSAGE);
         str = new NSString();
         str.data = remoteUrlHash;
         downloadList.appendElement(str, false);
       }
       localHashList[remoteUrlHash] = null;
     }
     else {
       yDebug.print("New bookmark was added to the remote => download " + remoteUrlHash, YB_LOG_MESSAGE);
       str = new NSString();
       str.data = remoteUrlHash;       
       downloadList.appendElement(str, false);
     }
   }  

   for (var localUrlHash in localHashList) {
     if (localHashList[localUrlHash] != null) {
       //remove from the list
       yDebug.print("Delete local bookmark ---> " + localUrlHash);
       str = new NSString();
       str.data = localUrlHash;      
       deleteList.appendElement(str, false);
     }
   }

   result["deleteList"] = deleteList;
   result["downloadList"] = downloadList;
   
   return result;
}     

/**
 * Class definition
 */
var YBookmarksSyncService = {
   _syncAllowed: true,
   _isSyncing : false,
   
   init: function() {
      yDebug.print( "Creating instance of YBookmarksSyncService" );

      var assClass =
         Components.classes["@mozilla.org/appshell/appShellService;1"];
      var ass = assClass.getService(Components.interfaces.nsIAppShellService);
      gHiddenWin = ass.hiddenDOMWindow;
   },
   
   cancelSync: function() {
      this._syncAllowed = false;
      gHiddenWin.clearTimeout(gHiddenWin.ybSyncTimeoutId);
      this._isSyncing = false;
   },

   allowSync: function() {
   
      this._syncAllowed = true;
      this._isSyncing = false;
   },

   /**
    * Send all the local transactions (e.g add, edit and delete bookmarks) to the remote.
    * This is called periodically by the sync service but this should also be called 
    * when a new transaction is added to the transaction store.
    */  
   processTransactions : function() {
     try {
      if (!this._syncAllowed) {
         return;
      }
     
     /* e.g. 0 - uninitialized, 1 - sent, 2 - completed, 3 - failed */
     var socialStore = Components.classes["@yahoo.com/socialstore/delicious;1"].
                         getService( Components.interfaces.nsISocialStore );

     var delreader = Components.classes[kDelContractID].
          getService(Components.interfaces.nsISocialStore);

     var bookmarksStore = Components.classes["@mozilla.org/ybookmarks-store-service;1"].
             getService(Components.interfaces.nsIYBookmarksStoreService);

     var transactionQueue = bookmarksStore.getTransactions();
     
     var transactions = transactionQueue.enumerate();
     var transaction, transactionState, cb;
           
     while (transactions.hasMoreElements() && this._syncAllowed) {
        
        transaction = transactions.getNext();
        transaction = transaction.QueryInterface(Components.interfaces.nsIWritablePropertyBag);        
        
        transactionState = transaction.getProperty("transactionState");
        if (transactionState == 2 || transactionState == 1) {
          continue;
        }
 
        bookmarksStore.setTransactionState (transaction.getProperty("transactionType"), transaction.getProperty("url"), 1);
        
        switch (transaction.getProperty("transactionType")) {
          case "addBookmark":
            
            cb = {
              onload: function (returnValue) {

                if(returnValue.length == 0){
                  return;
                }  
                
                var rv = returnValue.queryElementAt(0, 
                         Components.interfaces.nsIWritablePropertyBag);
                var url = rv.getProperty("url");

                var bookmarksStore =Components.classes["@mozilla.org/ybookmarks-store-service;1"].
                         getService(Components.interfaces.nsIYBookmarksStoreService);
                bookmarksStore.setTransactionState ("addBookmark", url, 2);

                yDebug.print("Added bookmark to the remote:" + url, YB_LOG_MESSAGE);
                gHiddenWin.setTimeout(function() { _YBookmarksSyncHelper.updateBookmarkHash(url); }, 
                                         DEL_HASH_REQUESET_AFTER_TRANS_WAIT,
                                         url);
              },

              onerror: function (returnValue) {
                returnValue = returnValue.QueryInterface(Components.interfaces.nsIArray);
                if(returnValue.length == 0) {
                  yDebug.print("Failed to add bookmark to the remote", YB_LOG_MESSAGE);
                  return;
                }  
                
                var rv = returnValue.queryElementAt(0, 
                        Components.interfaces.nsIWritablePropertyBag);
                var url = rv.getProperty("url");
                var status = rv.getProperty("status");
                var statusText = rv.getProperty("statusText");
                
                var bookmarksStore = Components.classes["@mozilla.org/ybookmarks-store-service;1"].
                      getService(Components.interfaces.nsIYBookmarksStoreService);
                if (status == "414") {
                  yDebug.print("Remove addBookmark transaction: ", YB_LOG_MESSAGE);
                  bookmarksStore.setTransactionState ("addBookmark", url, 2);

                  //remove bookmark from local store
                  bookmarksStore.deleteBookmark(url);
                  
                  Components.classes["@mozilla.org/observer-service;1"]
             .getService(Components.interfaces.nsIObserverService)
                    .notifyObservers(null, "ybookmark.serverError", 
                        '{ status:"' + status + '", action:"addBookmark" }');
                }
                else {
                  bookmarksStore.setTransactionState ("addBookmark", url, 3);
                }

                yDebug.print("Failed to add bookmark to the remote :" + url, YB_LOG_MESSAGE);
              }
            };       
     
            yDebug.print("Adding...");
            delreader.addBookmark (transaction, cb);
           
          break;       
          case "editBookmark":

            cb = {
              onload: function (returnValue) {
                if(returnValue.length == 0)
                  return;
              
                var rv = returnValue.queryElementAt(0, 
                        Components.interfaces.nsIWritablePropertyBag);
                var url = rv.getProperty("url");
                var bookmarksStore = Components.classes["@mozilla.org/ybookmarks-store-service;1"].
                        getService(Components.interfaces.nsIYBookmarksStoreService);
                bookmarksStore.setTransactionState ("editBookmark", url, 2);

                yDebug.print("Edited Bookmark to remote :" + url, YB_LOG_MESSAGE);
                gHiddenWin.setTimeout(function(url) { _YBookmarksSyncHelper.updateBookmarkHash(url); }, 
                                        DEL_HASH_REQUESET_AFTER_TRANS_WAIT,
                                        url);
              },

              onerror: function (returnValue) {
                returnValue = returnValue.QueryInterface(Components.interfaces.nsIArray);
                if (returnValue.length == 0) {
                  yDebug.print("Failed to edit Bookmark to remote ", YB_LOG_MESSAGE);                                                           
                  return;
                }
                
                var rv = returnValue.queryElementAt(0, 
                        Components.interfaces.nsIWritablePropertyBag);
                var url = rv.getProperty("url");
                var status = rv.getProperty("status");
                var statusText = rv.getProperty("statusText");

                var bookmarksStore = Components.classes["@mozilla.org/ybookmarks-store-service;1"].
                       getService(Components.interfaces.nsIYBookmarksStoreService);
                if (status == "414") {
                  yDebug.print("Remove editBookmark transaction ", YB_LOG_MESSAGE);
                  bookmarksStore.setTransactionState ("editBookmark", url, 2);               
 
                  //remove bookmark from local store
                  bookmarksStore.deleteBookmark(url);
 
                  Components.classes["@mozilla.org/observer-service;1"]
             .getService(Components.interfaces.nsIObserverService)
                    .notifyObservers(null, "ybookmark.serverError", 
                          '{ status:"' + status + '", action:"editBookmark" }');
                }
                else {
                  bookmarksStore.setTransactionState ("editBookmark", url, 3);
                }

                yDebug.print("Failed to edit Bookmark to remote :" + url, YB_LOG_MESSAGE);                                           
              }
            };       
     
            yDebug.print("Editing...");
            delreader.editBookmark (transaction, cb);       
        
          break;
          case "deleteBookmark":

            cb = {
              onload: function (returnValue) {
                
                if (returnValue.length == 0)
                  return;
                var rv = returnValue.queryElementAt(0, 
                        Components.interfaces.nsIWritablePropertyBag);
                var url = rv.getProperty("url");
                var bookmarksStore = Components.classes["@mozilla.org/ybookmarks-store-service;1"].
                      getService(Components.interfaces.nsIYBookmarksStoreService);
                 bookmarksStore.setTransactionState ("deleteBookmark", url, 2);

                yDebug.print("Deleted Bookmark to remote :" + url, YB_LOG_MESSAGE);                                           
              },

              onerror: function (returnValue) {
                returnValue = returnValue.QueryInterface(Components.interfaces.nsIArray);
                if (returnValue.length == 0) {
                  yDebug.print("Failed to delete Bookmark to remote ", YB_LOG_MESSAGE);                                           
                  return;
                }
                
                var rv = returnValue.queryElementAt(0, 
                        Components.interfaces.nsIWritablePropertyBag);
                var status = rv.getProperty("status");
                var statusText = rv.getProperty("statusText");

                var bookmarksStore = Components.classes["@mozilla.org/ybookmarks-store-service;1"].
                     getService(Components.interfaces.nsIYBookmarksStoreService);
                if (status == "414") {
                  yDebug.print("Remove deleteBookmark transaction ", YB_LOG_MESSAGE);                  
                  bookmarksStore.setTransactionState ("deleteBookmark", url, 2);
                   Components.classes["@mozilla.org/observer-service;1"]
             .getService(Components.interfaces.nsIObserverService)
                    .notifyObservers(null, "ybookmark.serverError", 
                       '{ status:"' + status + '", action:"deleteBookmark" }');
                }
                else {
                  bookmarksStore.setTransactionState ("deleteBookmark", url, 3);
                }

                yDebug.print("Failed to delete Bookmark to remote :" + url, YB_LOG_MESSAGE);                                           
              }
            };       
     
            yDebug.print("Deleting...");
            delreader.deleteBookmark (transaction.getProperty("url"), cb);
  
          break;
          case "setBundle":
            
            cb = {
              onload: function (returnValue) {
                if(returnValue.length == 0){
                  return;
                }  
                                
                var rv = returnValue.queryElementAt(0, 
                         Components.interfaces.nsIWritablePropertyBag);
                
  /*              var rvEnum = rv.enumerator;
                while (rvEnum.hasMoreElements()) {
                  var e = rvEnum.getNext();
                  e.QueryInterface(Components.interfaces.nsIProperty);
                  yDebug.print("bundle name: " + e.name + "  value: " + e.value);
                }*/
                var bundle = rv.getProperty("url");
                var bookmarksStore = Components.classes["@mozilla.org/ybookmarks-store-service;1"].
                         getService(Components.interfaces.nsIYBookmarksStoreService);
                bookmarksStore.setTransactionState ("setBundle", bundle, 2);

                yDebug.print("Added Bundle to the remote:" + bundle, YB_LOG_MESSAGE);
                /*gHiddenWin.setTimeout(function() { _YBookmarksSyncHelper.updateBookmarkHash(url); }, 
                                         DEL_HASH_REQUESET_AFTER_TRANS_WAIT,
                                         url);*/
              },

              onerror: function (returnValue) {
                returnValue = returnValue.QueryInterface(Components.interfaces.nsIArray);
                if(returnValue.length == 0) {
                  yDebug.print("Failed to add bundle to the remote", YB_LOG_MESSAGE);
                  return;
                }  
                
                var rv = returnValue.queryElementAt(0, 
                        Components.interfaces.nsIWritablePropertyBag);
                var url = rv.getProperty("url");
                var status = rv.getProperty("status");
                var statusText = rv.getProperty("statusText");
                
                var bookmarksStore = Components.classes["@mozilla.org/ybookmarks-store-service;1"].
                      getService(Components.interfaces.nsIYBookmarksStoreService);
                if (status == "414") {
                  yDebug.print("Remove setBundle transaction: ", YB_LOG_MESSAGE);
                  bookmarksStore.setTransactionState ("setBundle", url, 2);

                  //remove bookmark from local store
                  bookmarksStore.deleteBundle(url.substr(url.length));
                  
                  Components.classes["@mozilla.org/observer-service;1"]
             .getService(Components.interfaces.nsIObserverService)
                    .notifyObservers(null, "ybookmark.serverError", 
                        '{ status:"' + status + '", action:"setBundle" }');
                }
                else {
                  bookmarksStore.setTransactionState ("setBundle", url, 3);
                }

                yDebug.print("Failed to set bundle to the remote :" + url, YB_LOG_MESSAGE);
              }
            };       
     
            yDebug.print("Setting Bundle...");
        /*    var transEnum = transaction.enumerator;
            while (transEnum.hasMoreElements()) {
              var p = transEnum.getNext().QueryInterface(Components.interfaces.nsIProperty);
              yDebug.print("bundle prop: " + p.name + " : " + p.value);
            }*/
            delreader.setBundle (transaction.getProperty("name"), transaction.getProperty("tags"), cb);
           
          break;       
          case "deleteBundle":
          
            cb = {
              onload: function (returnValue) {
              if(returnValue.length == 0){
                return;
              }  
                              
              var rv = returnValue.queryElementAt(0, 
                       Components.interfaces.nsIWritablePropertyBag);
              
/*              var rvEnum = rv.enumerator;
              while (rvEnum.hasMoreElements()) {
                var e = rvEnum.getNext();
                e.QueryInterface(Components.interfaces.nsIProperty);
                yDebug.print("bundle name: " + e.name + "  value: " + e.value);
              }*/
              var bundle = rv.getProperty("url");
              var bookmarksStore = Components.classes["@mozilla.org/ybookmarks-store-service;1"].
                       getService(Components.interfaces.nsIYBookmarksStoreService);
              bookmarksStore.setTransactionState ("deleteBundle", bundle, 2);

              yDebug.print("Deleted Bundle from the remote:" + bundle, YB_LOG_MESSAGE);
              /*gHiddenWin.setTimeout(function() { _YBookmarksSyncHelper.updateBookmarkHash(url); }, 
                                       DEL_HASH_REQUESET_AFTER_TRANS_WAIT,
                                       url);*/
            },

            onerror: function (returnValue) {
              returnValue = returnValue.QueryInterface(Components.interfaces.nsIArray);
              if(returnValue.length == 0) {
                yDebug.print("Failed to delete bundle from the remote", YB_LOG_MESSAGE);
                return;
              }  
              
              var rv = returnValue.queryElementAt(0, 
                      Components.interfaces.nsIWritablePropertyBag);
              var url = rv.getProperty("url");
              var status = rv.getProperty("status");
              var statusText = rv.getProperty("statusText");
              
              var bookmarksStore = Components.classes["@mozilla.org/ybookmarks-store-service;1"].
                    getService(Components.interfaces.nsIYBookmarksStoreService);
              
              bookmarksStore.setTransactionState ("deleteBundle", url, 3);
              
              yDebug.print("Failed to set bundle to the remote :" + url, YB_LOG_MESSAGE);
            }
          };       
   
          yDebug.print("Deleting Bundle...");
      /*    var transEnum = transaction.enumerator;
          while (transEnum.hasMoreElements()) {
            var p = transEnum.getNext().QueryInterface(Components.interfaces.nsIProperty);
            yDebug.print("bundle prop: " + p.name + " : " + p.value);
          }*/
          delreader.deleteBundle (transaction.getProperty("name"), cb);
          break;
          default:
        }
     }
   } catch (e) {
     yDebug.print("ERROR PROCESSING TRANSACTIONS: " + e);
   }
   },
      
   /** 
    * Sync the local store with the remote repository.
    * This is done periodically by the service but this requests
    * an immediate update.
    *
    * @param periodicSync a boolean to indicate whether we should run a 
    * periodic sync or not.
    */
   sync: function(periodicSync) {
      if (this != YBookmarksSyncService) { 
        YBookmarksSyncService.sync(periodicSync);
        return;
      }

      if (!this._syncAllowed) {
        return;
      }
            
      var syncTimeoutId;
      var bookmarksStore =
         Components.classes["@mozilla.org/ybookmarks-store-service;1"].
            getService(Components.interfaces.nsIYBookmarksStoreService);             
      
      bookmarksStore.restateTransactions();
      
      //get all transactions with uninitialized state
      if (bookmarksStore.getNumberOfTransactions("all", 0) > 0) {
         
         this.processTransactions();     
     
         //wait X seconds for the responses from the server
         if (periodicSync) {
            syncTimeoutId = gHiddenWin.setTimeout(function(syncService) { syncService.sync(true); }, DEL_SENDING_TRANSACIIONS_WAIT, this);
            gHiddenWin.ybSyncTimeoutId = syncTimeoutId;
         } else {
            gHiddenWin.setTimeout(function(syncService) { syncService.sync(false); }, DEL_SENDING_TRANSACIIONS_WAIT, this);
         }
   
         return;
      }
   
      if (periodicSync) {
      
         //add something to here to get the preference
        var interval = DEL_SYNC_INTERVAL;
        var prefs = Components.classes["@mozilla.org/preferences-service;1"]
                      .getService(Components.interfaces.nsIPrefBranch);
        try {
          interval = prefs.getIntPref("extensions.ybookmarks@yahoo.bookmark.sync.interval");
          if (interval <= 0) {
            interval = DEL_SYNC_INTERVAL;
            prefs.setIntPref("extensions.ybookmarks@yahoo.bookmark.sync.interval", interval);
          }
        }
        catch(e) { }
        interval *= (60 * 1000);
                
        if (!this._isSyncing) {
          syncTimeoutId =  gHiddenWin.setTimeout(function(syncService) { syncService.sync(true); }, interval, this);
          gHiddenWin.ybSyncTimeoutId = syncTimeoutId;
        } else {
          yDebug.print("=====> Syncing at the moment, come back 1 min later");
          syncTimeoutId =  gHiddenWin.setTimeout(function(syncService) { syncService.sync(true); }, DEL_IS_SYNCING_WAIT, this);
          gHiddenWin.ybSyncTimeoutId = syncTimeoutId;
          return;
        }
      } else {
        if (this._isSyncing) {
          yDebug.print("=====> Syncing at the moment, ignoring non-periodic sync");
          return;  
        }
      }

      this._isSyncing = true; 

      //get from the server
      var delreader =
         Components.classes[kDelContractID].
            getService(Components.interfaces.nsISocialStore);
    
      var cb = {
         onload: function(posts) {
            var post = 
               posts.queryElementAt(0,
                                    Components.interfaces
                                    .nsIWritablePropertyBag);

            var dellastupdated = post.getProperty("time");

            var bookmarksStore =
               Components.classes["@mozilla.org/ybookmarks-store-service;1"].
                  getService(Components.interfaces.nsIYBookmarksStoreService);
            var locallastupdate = bookmarksStore.getLastUpdateTime();

            yDebug.print("======> llu:" + locallastupdate + " dlu:" + dellastupdated);
         
            //locallastupdate == null, means we do not have a any data, force a full sync                 
            //locallastupdate == "-1", means we do have data but we want to force a partial sync
            if (locallastupdate) {
               locallastupdate = parseInt(locallastupdate);
               
               if (isNaN(locallastupdate) || parseInt(dellastupdated) > locallastupdate) {
                  //YBookmarksSyncService._syncFully(dellastupdated);
                 YBookmarksSyncService._syncPartially(dellastupdated);
                 yDebug.print("Do a partial sync here");
               } else {
                  Components.classes["@mozilla.org/observer-service;1"].
                     getService(Components.interfaces.nsIObserverService).
                        notifyObservers(null, "ybookmark.syncDone", "no-update");
                  yDebug.print("No updates on delicious");

                  YBookmarksSyncService._isSyncing = false;
                  
                  return;
               }
            } else {
              //full sync should only happen during the initial download .i.e. no data in the extra.rdf.
              //full sync doesn't remove any bookmarks that aren't in the remote.
              YBookmarksSyncService._syncFully(dellastupdated);          
              yDebug.print("Do a full sync here");
            }
            
            /* bundles */
            // this is placed here because syncFully calls storeService.clearExtra() which calls clearBundles()
            var bundleCb = {
              onerror: function(event) {
                yDebug.print("nsYBookmarkSyncService.getBundles callback error!" + event);
              },

              onload: function(bundles) {
                try {
                  var bookmarksStore = Components.classes["@mozilla.org/ybookmarks-store-service;1"].
                          getService(Components.interfaces.nsIYBookmarksStoreService);

                  bookmarksStore.setBundles(bundles);

                } catch (e) {
                  yDebug.print("nsYBookmarkSyncService.getBundles callback.onload(): " + e);
                }
              }
            };
            delreader.allBundles(bundleCb);
                    
         },

         onerror: function(event) {
            yDebug.print("UNABLE to access user's update status", YB_LOG_MESSAGE);
            yDebug.print("Notify the observer to update all windows\n");
                  
            YBookmarksSyncService._isSyncing = false;
            Components.classes["@mozilla.org/observer-service;1"].
              getService(Components.interfaces.nsIObserverService).
                 notifyObservers(null, "ybookmark.syncDone", "sync-error");
         }
      };
      
      delreader.lastUpdate(cb);
      
   },
   
   _syncFully: function(lastUpdateTime) {
      var bookmarksStore =
         Components.classes["@mozilla.org/ybookmarks-store-service;1"].
            getService(Components.interfaces.nsIYBookmarksStoreService);
            
      //bugfix :there is a internal flag in this service to detemine whether we should delete all bookmarks
      //the bookmarks can't be deleted when the bookmarks store service starts
      
      bookmarksStore.deleteAllBookmarks(true);
      
      Components.classes["@mozilla.org/observer-service;1"].
         getService(Components.interfaces.nsIObserverService).
            notifyObservers(null, "ybookmark.syncBegin", "no-update");
      gHiddenWin.setTimeout(this._getChunk, 0, 0, lastUpdateTime);
   },

   _syncPartially: function (dellastupdated) {

      if (this != YBookmarksSyncService) {
        YBookmarksSyncService._syncPartially(dellastupdated);
        return;
      }

      var delreader =
         Components.classes[kDelContractID].
            getService(Components.interfaces.nsISocialStore);

      var cb = {
         onload: function(remoteHashList) {
            var bookmarksStore =
               Components.classes["@mozilla.org/ybookmarks-store-service;1"].
                  getService(Components.interfaces.nsIYBookmarksStoreService);         
            var localHashList = bookmarksStore.getBookmarkHashes();
            var mLocalHashList = _convertHashesFromNSArrayToJSObject(localHashList);
            var mRemoteHashList = _convertHashesFromNSArrayToJSObject(remoteHashList);        
            var lists = _compareBookmarkHashes(mLocalHashList, mRemoteHashList);
            
            //delete local bookmarks
            var deleteList = lists["deleteList"];
            if (deleteList.length > 0 ) {
               YBookmarkSyncService_delete_diff (deleteList);
            }        

            //download remote bookmarks
            var downloadList = lists["downloadList"];        
            //more than 100 bookmarks, we do a full sync instead
            if (downloadList.length > 100) {
               YBookmarksSyncService._syncFully(dellastupdated);
            } else {
               YBookmarkSyncService_download_diff (downloadList, dellastupdated);
            }
         },
      
         onerror : function(posts) {
           yDebug.print("UNABLE to access user's delicious hashes", YB_LOG_MESSAGE);
           YBookmarksSyncService._isSyncing = false;
         }
      };

      delreader.getBookmarkHashes(cb);
   },
   
   _getChunk: function(start, lastUpdateTime) {
      if (this != YBookmarksSyncService) {
        YBookmarksSyncService._getChunk(start, lastUpdateTime);
        return;
      }
      
      if (!this._syncAllowed) {
         yDebug.print("Sync cancelled.");
         yDebug.print("Notify the observer to update all windows\n");
  
         this._isSyncing = false;
         Components.classes["@mozilla.org/observer-service;1"].
           getService(Components.interfaces.nsIObserverService).
              notifyObservers(null, "ybookmark.syncDone", "all-done");
         return;
      }
 
      var delreader =
         Components.classes[kDelContractID].
            getService(Components.interfaces.nsISocialStore);
      var count = 0;
      var downloadMore = false;
   
      var cb = {
         startTime : (new Date()).getTime(),
         onload: function(posts) {
         
            var notifyData = null;
            if (!YBookmarksSyncService._syncAllowed) {
               yDebug.print("Sync cancelled.");
               yDebug.print("Notify the observer to update all windows\n");
               
               YBookmarksSyncService._isSyncing = false;
               Components.classes["@mozilla.org/observer-service;1"].
                 getService(Components.interfaces.nsIObserverService).
              notifyObservers(null, "ybookmark.syncDone", "all-done");
               return;
            }

            var prefs = Components.classes["@mozilla.org/preferences-service;1"]
                      .getService(Components.interfaces.nsIPrefBranch);
            var size = prefs.getIntPref("extensions.ybookmarks@yahoo.sync.chunk.size");
            if (size >= 0 && DEL_CHUNK_SIZE != size) {
              DEL_CHUNK_SIZE = size;
            }
            var wait = prefs.getIntPref("extensions.ybookmarks@yahoo.sync.chunk.wait");
            if (wait >= 0 && DEL_CHUNK_WAIT != wait) {
              DEL_CHUNK_WAIT = wait;
              DEL_ADD_BOOKMARK_WAIT = wait;
            }
                        
            var bookmarksStore =
               Components.classes["@mozilla.org/ybookmarks-store-service;1"].
                  getService(Components.interfaces.nsIYBookmarksStoreService);
            
            if ( posts.length ) {
              notifyData = "add-to-ds-begin";
              Components.classes["@mozilla.org/observer-service;1"].
               getService(Components.interfaces.nsIObserverService).
              notifyObservers(null, "ybookmark.syncInfo", notifyData); 
            }
            
            var post;
            for (var i = 1; i < posts.length; i++) {
              post = 
                 posts.queryElementAt(i,
                                      Components.interfaces
                                      .nsIWritablePropertyBag);

              gHiddenWin.setTimeout(function(post, i) {
                 if (!YBookmarksSyncService._syncAllowed) {
                    yDebug.print("Sync cancelled.");
                    yDebug.print("Notify the observer to update all windows\n");
 
                    YBookmarksSyncService._isSyncing = false;
                    Components.classes["@mozilla.org/observer-service;1"].
                      getService(Components.interfaces.nsIObserverService).
                    notifyObservers(null, "ybookmark.syncDone", "all-done");
                    return;
                 }

                 _YBookmarksSyncHelper.updateStoreFromPost( bookmarksStore, post );
                                     
                 if ( i == (posts.length - 1)) {
                   notifyData = "add-to-ds-end";
                   Components.classes["@mozilla.org/observer-service;1"].
                    getService(Components.interfaces.nsIObserverService).
                     notifyObservers(null, "ybookmark.syncInfo", notifyData); 
                 } 
             }, 
             ((DEL_ADD_BOOKMARK_WAIT/DEL_CHUNK_SIZE) * i), 
             post, i);
           }

           var metaData = posts.queryElementAt(0,
                                      Components.interfaces
                                      .nsIWritablePropertyBag);
           var total = null;
           try {
             total = metaData.getProperty( "total" );
             yDebug.print ( "TOTAL => " + total, YB_LOG_MESSAGE);
           } catch ( e ) {
           }
           var syncDoneSubject = null;
           
           if ((posts.length - 1) == DEL_CHUNK_SIZE) {
             /* more chunks to go... */
             yDebug.print ( "More chunks to go.." );
             start += DEL_CHUNK_SIZE;
             var elapsedTime = (new Date()).getTime() - this.startTime;
             gHiddenWin.setTimeout(
               YBookmarksSyncService._getChunk, DEL_CHUNK_WAIT - elapsedTime,
                start, lastUpdateTime);
             syncDoneSubject = { start: start, chunk: DEL_CHUNK_SIZE, total: total };
             syncDoneSubject.wrappedJSObject = syncDoneSubject;
             notifyData = "more-chunk";
           } else {
             /* we're done. */
             yDebug.print ( "We are done with sync..." );
             gHiddenWin.setTimeout(function() { 
                if (lastUpdateTime) {
                    bookmarksStore.setLastUpdateTime(lastUpdateTime); 
                } 
                bookmarksStore.flush(false); 
                yDebug.print("Synching done"); 
                YBookmarksSyncService._isSyncing = false;
               }, 
               DEL_ADD_BOOKMARK_WAIT + 100);
             notifyData = "all-done";
          }

          gHiddenWin.setTimeout(function(notifyData){ 
            yDebug.print("Notify the observer to update all windows: " + notifyData);
            var os = Components.classes["@mozilla.org/observer-service;1"].
               getService(Components.interfaces.nsIObserverService);
            var topic = (notifyData == "more-chunk") ? "ybookmark.syncInfo" : "ybookmark.syncDone"; 
            os.notifyObservers(syncDoneSubject, topic, notifyData);
            }, 
            DEL_ADD_BOOKMARK_WAIT + 100, notifyData);
         },

         onerror: function(event) {
            yDebug.print("UNABLE to access user's delicious posts: " + event.target.status, YB_LOG_MESSAGE);
            yDebug.print("Notify the observer to update all windows\n");
                  
            YBookmarksSyncService._isSyncing = false;
            Components.classes["@mozilla.org/observer-service;1"].
              getService(Components.interfaces.nsIObserverService).
                 notifyObservers(null, "ybookmark.syncDone", "sync-error");
         }
      };

      var prefs = Components.classes["@mozilla.org/preferences-service;1"]
                      .getService(Components.interfaces.nsIPrefBranch);
      var size = prefs.getIntPref("extensions.ybookmarks@yahoo.sync.chunk.size");
      if (size >= 0 && DEL_CHUNK_SIZE != size) {
         DEL_CHUNK_SIZE = size;
      }      
      delreader.allBookmarks(start, DEL_CHUNK_SIZE, cb);
   },
   
   QueryInterface: function(aIID) {

      if ( !aIID.equals(nsIYBookmarkSyncService) &&
           !aIID.equals(nsISupports)) {
         throw Components.results.NS_ERROR_NO_INTERFACE;
      }

      return this;
   }
};

/**
 * Microsummaries observer. This object is a listener for the microsummary object.
 * When microsummary content is available, it set the microsummary object to the
 * bookmark resource
 * 
 * @param bookmarksResource Bookmark in question
 */
function _YBookmarksSyncMicrosummaryUpdater(bookmarksResource, generatorUri) {
  this._bookmarksResource = bookmarksResource;
  this._generatorUri = generatorUri;
  this._msService = Components.classes["@mozilla.org/microsummary/service;1"].
                                getService( Components.interfaces.nsIMicrosummaryService );
}

_YBookmarksSyncMicrosummaryUpdater.prototype = {
  interfaces: [ Components.interfaces.nsIMicorsummaryObserver, Components.interfaces.nsISupports ],

  onContentLoaded: function( microsummary ) {
    if ( microsummary.generator.uri.spec == this._generatorUri &&  microsummary.content ) {
      this._msService.setMicrosummary( this._bookmarksResource, microsummary );
    }
  },

  onElementAppended: function ( microsummary ) {
    if ( microsummary.generator.uri.spec == this._generatorUri ) {
      microsummary.update();
    }
  },

  updateMicrosummary: function(microsummaries) {
    var enumeration = microsummaries.Enumerate();
    while ( enumeration.hasMoreElements() ) {
      var microsummary = enumeration.getNext();
      microsummary.QueryInterface( Components.interfaces.nsIMicrosummary );
      if ( microsummary.generator.uri.spec == this._generatorUri ) {
        if ( microsummary.content ) {
          this._msService.setMicrosummary( this._bookmarksResource, microsummary );
        } else {
          microsummary.update();
        }
      }
    }
  } // end of updateMicrosummary
};

/**
 * Bookmarks Sync helper functions
 */
var _YBookmarksSyncHelper = {
  /**
   * This function does the following steps:
   *   1. Check if microsummary was saved at the service provider.
   *   2. If so, get the available microsummary uris for the url in question.
   *   3. Find the microsummary which was used by the user, add the observer
   *      to that microsummary in order to listen to it.
   */
  fetchMicrosummary: function( post ) {
    try {

      var generatorUri = post.getProperty("microsummary");
      if ( generatorUri == "" ) {
        yDebug.print ( "Generator uri is null", YB_LOG_MESSAGE );
        return;
      }

      // check if microsummary available
      var microsummaryService = Components.classes["@mozilla.org/microsummary/service;1"];
      if ( !microsummaryService ) {
        yDebug.print ( "Microsummary service not available", YB_LOG_MESSAGE );
        return;
      }
      microsummaryService = microsummaryService.getService( Components.interfaces.nsIMicrosummaryService );

      var url = post.getProperty("url");
        
      var bookmarksStore = (Components.classes["@mozilla.org/ybookmarks-store-service;1"].
             getService(Components.interfaces.nsIYBookmarksStoreService));

      var bookmarksResource = bookmarksStore.isBookmarked ( url );
      if ( !bookmarksResource ) {
        yDebug.print ( "fetchMicrosummary: " + url + " is not in bookmark database\n", YB_LOG_MESSAGE );
        return;
      }

      // if bookmark already has microsummary, no need to continue
      var currentMicrosummary = microsummaryService.getMicrosummary( bookmarksResource );
      if ( currentMicrosummary ) {
        yDebug.print ( "fetchMicrosummary: " + url + " is already having the microsummary attached",
                     YB_LOG_MESSAGE);
        return;
      }

      var ioService= Components.classes["@mozilla.org/network/io-service;1"].
                   getService(Components.interfaces.nsIIOService);

      // fetch the microsummary uris for the "url". If not already in memory, microsummary service
      // load the page and collect the microsummaries from it.
      var microsummaries = microsummaryService.getMicrosummaries( ioService.newURI( url, null, null ),
                                                                  null
                                                                );
      // microsummaries for this url does not exists, ignore the microsummary from the service provider
      if ( !microsummaries ) {
        yDebug.print ( "fetchMicrosummary: Either microsummaries is null or no elements within it for " + generatorUri + "(" + url + ")", YB_LOG_MESSAGE );
        return;
      }

      var observer = new _YBookmarksSyncMicrosummaryUpdater(bookmarksResource, generatorUri);
      microsummaries.addObserver( observer );
      observer.updateMicrosummary(microsummaries);

    } catch ( e ) {
      // microsummary property is not present. Bookmark do not have microsummary
      // attached to it.
      if ( e.stack )
        yDebug.print ( e.stack, YB_LOG_MESSAGE );
    }
  },
  
  /**
   * Update the bookmark store
   *
   * @param bookmarkStore a bookmark store service
   * @post post from the service provider
   */
  updateStoreFromPost: function(bookmarksStore, post) {

    var url = post.getProperty("url");
    var title = post.getProperty("title");
    var notes = post.getProperty("notes");
    var tags = post.getProperty("tags");
    var icon = post.getProperty("icon");
    var hash = post.getProperty("hash");
    var metahash = post.getProperty("metahash");
    var shortcut = post.getProperty("shortcut");

    var taglist = tags.split(/\s */);

    // public by default
    var shared = "true";
    try {
      shared = post.getProperty("shared");
      if ( !shared )
        shared = "true";
    } catch ( e ) {
    }

    /* this is from server so localOnly should be false */    
    var localOnly = "false";
    
    var postData = "";    
    if ( notes.length ) {
      postData = _YBookmarksSyncHelper.extractPostDataFromNotes( notes );
      if (postData.length)
        notes = _YBookmarksSyncHelper.removePostDataFromNotes( notes );
    }

    // This is a livemark. For all services, set the tags as firefox:rss to 
    // indicate the rss feed
    if ( ybookmarksUtils.containsTag( tags, "firefox:rss" ) != -1 ) {
      bookmarksStore.addLivemark( url, title, url, notes,
                                  taglist.length, taglist, shared, localOnly, false );
      bookmarksStore.setBookmarkKeyAsString(url, "hash", hash); 
      bookmarksStore.setBookmarkKeyAsString(url, "metahash", metahash); 
    } else {

      var bookmarkObject = {
        name: title,
        url: url,
        description: notes,
        tags: ybookmarksUtils.jsArrayToNs(taglist),
        shortcut: shortcut,
        postData: postData
      };

      try {
        var updateTime = post.getProperty("update_time");
        if ( updateTime ) {
          bookmarkObject.last_modified = updateTime;
        }
      } catch ( e ) {
      }

      try {
        var addTime = post.getProperty("add_time");
        if ( addTime ) {
          bookmarkObject.added_date = addTime;
        }
      } catch ( e ) {
      }

      bookmarkObject.shared = shared;
      bookmarkObject.localOnly = localOnly;

      bookmarksStore.addBookmarkObject( bookmarkObject, false );
      bookmarksStore.setBookmarkKeyAsString(url, "hash", hash); 
      bookmarksStore.setBookmarkKeyAsString(url, "metahash", metahash); 
      _YBookmarksSyncHelper.fetchMicrosummary( post );
    }
  },
  
  /**
   * Update the hashes for a bookmark. This is called after adding/editing a bookmark
   * to the service provider
   *
   * @param url a bookmark's url
   */
  updateBookmarkHash : function(url) {
    
    yDebug.print("UpdateBookmarkHash: " + url);

    var cb = { 
      onload: function(posts) {
      
        var bookmarksStore =
            (Components.classes["@mozilla.org/ybookmarks-store-service;1"].
             getService(Components.interfaces.nsIYBookmarksStoreService));

        var post;
        for (var i = 0; i < posts.length; i++) {
           post = posts.queryElementAt(i,
                                   Components.interfaces
                                   .nsIWritablePropertyBag);           
           _YBookmarksSyncHelper.updateStoreFromPost( bookmarksStore, post );
         }
        
         bookmarksStore.flush(false); 
      },
      
      onerror : function (posts) {
         yDebug.print("UNABLE to update bookmark based on the url", YB_LOG_MESSAGE);
      }
    };
  
    var delreader = Components.classes[kDelContractID].
                      getService(Components.interfaces.nsISocialStore);             
    delreader.getBookmarkForURL(url, cb);
  },
  
  /**
   * Extract the post data (POST form shortcut) from the notes string
   *  
   * @param notes the notes string 
   * @return postData the post data from the notes
   */
  extractPostDataFromNotes : function(notes) {
      
    var postData = "";
    if ( notes ) {
       var result = notes.match( /\[postdata:([^\]]+)\]\s*/ );
       try {
         if( result != null) {
           postData = decodeURIComponent(result[1]);
           yDebug.print( "Found postData: " + postData);
         }
       }
       catch(e) { }
    }

    
  return postData;
  },
  
  removePostDataFromNotes : function(notes) {
  
   if ( notes && notes.match( /\[postdata:/ ) ) {
     notes = notes.replace( /\[postdata:[^\]]+\]\s*/, "" );
   }

  return notes;
  }
  
};

/* 
 * Class factory
*/
var YBookmarksSyncServiceFactory = {

   _singletonObj: null,

   createInstance: function(aOuter, aIID) {

      yDebug.print ( "createInstance called in nsIFactory object" );

      if ( aOuter != null ) {
         throw Components.results.NS_ERROR_NO_AGGREGATION;
      }

      if ( !this._singletonObj ) {
         YBookmarksSyncService.init();
         this._singletonObj = YBookmarksSyncService;
      }
      
      return this._singletonObj.QueryInterface(aIID);
   }
};

/*
 * Module definition
*/

var YBookmarksSyncServiceModule = {
   registerSelf: function(aCompMgr, aFileSpec, aLocation, aType) {
      yDebug.print( "Registering YBookmarksSyncServiceModule", YB_LOG_MESSAGE);
      yDebug.print( "registerSelf: aFileSpec => " + aFileSpec );
      yDebug.print( "registerSelf: aLocation => " + aLocation );
      yDebug.print( "registerSelf: aType => " + aType );
      aCompMgr = aCompMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar);
      aCompMgr.registerFactoryLocation( CLASS_ID, CLASS_NAME, CONTRACT_ID, aFileSpec, aLocation, aType);
   },

   unregisterSelf: function (aCompMgr, aLocation, aType) {
      yDebug.print ( "unregisterSelf: aLocation => " + aLocation, YB_LOG_MESSAGE );
      yDebug.print ( "unregisterSelf: aType => " + aType );
      aCompMgr.QueryInterface( Components.interfaces.nsIComponentRegistrar);
      aCompMgr.unregisterFactoryLocation( CLASS_ID, aLocation );
   },

   getClassObject: function(aCompMgr, aCID, aIID) {
      yDebug.print ( "getClassObject: aCID => " + aCID );
      yDebug.print ( "getClassObject: aIID => " + aIID );
      if ( !aIID.equals(Components.interfaces.nsIFactory) ) 
         throw Components.results.NS_ERROR_NOT_IMPLEMENTED;

      if ( aCID.equals( CLASS_ID ) ) {
         return YBookmarksSyncServiceFactory;
      }

      throw Components.results.NS_ERROR_NO_INTERFACE;
   },

   canUnload: function(aCompMgr) {
      return true;
   }
};

function NSGetModule(aCompMgr, aFileSpec) {
   yDebug.print( "YBookmarksSyncServiceModule GetModule" );
   return YBookmarksSyncServiceModule;
}

