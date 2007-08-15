window.addEventListener("load", db_aboutInit, true);

function db_aboutInit() {
	
	var gExtensionManager = Components.classes["@mozilla.org/extensions/manager;1"].getService(Components.interfaces.nsIExtensionManager);
	document.getElementById("extVersion").value = gExtensionManager.getItemForID("{D4DD63FA-01E4-46a7-B6B1-EDAB7D6AD389}").version;
	window.removeEventListener("load", db_aboutInit, true);
}

function db_openLink(aPage) {
	
	// Open page in new tab
	var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService();
    var wmed = wm.QueryInterface(Components.interfaces.nsIWindowMediator);
    
    var win = wmed.getMostRecentWindow("navigator:browser");
    if (!win)
    	win = window.openDialog("chrome://browser/content/browser.xul", "_blank", "chrome,all,dialog=no", aPage, null, null);
    else {
    	var content = win.document.getElementById("content");
    	content.selectedTab = content.addTab(aPage);	
    }
	
}