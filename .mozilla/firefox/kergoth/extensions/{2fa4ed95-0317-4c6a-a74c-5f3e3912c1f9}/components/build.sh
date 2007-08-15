#!/bin/bash

/c/gecko-sdk/bin/xpidl.exe -m typelib -I "c:\gecko-sdk\idl" -e nsISocialStoreCallback.xpt nsISocialStoreCallback.idl

/c/gecko-sdk/bin/xpidl.exe -m typelib -I "c:\gecko-sdk\idl" -e nsISocialStore.xpt nsISocialStore.idl

/c/gecko-sdk/bin/xpidl.exe -m typelib -I "c:\gecko-sdk\idl" -e nsIYBookmark.xpt nsIYBookmark.idl
/c/gecko-sdk/bin/xpidl.exe -m typelib -I "c:\gecko-sdk\idl" -e nsIYBundle.xpt nsIYBundle.idl
/c/gecko-sdk/bin/xpidl.exe -m typelib -I "c:\gecko-sdk\idl" -e nsIYBookmarkService.xpt nsIYBookmarkService.idl
/c/gecko-sdk/bin/xpidl.exe -m typelib -I "c:\gecko-sdk\idl" -e nsIYBookmarkSyncService.xpt nsIYBookmarkSyncService.idl
/c/gecko-sdk/bin/xpidl.exe -m typelib -I "c:\gecko-sdk\idl" -e nsIYBookmarksStoreService.xpt nsIYBookmarksStoreService.idl
/c/gecko-sdk/bin/xpidl.exe -m typelib -I "c:\gecko-sdk\idl" -e nsIYDebugService.xpt nsIYDebugService.idl
