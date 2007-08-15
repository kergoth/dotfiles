var stylishMailOverlay = {

	popupShowing: function(event) {
		//put the app name in the label
		var findStyle = document.getElementById("stylish-find-app");
		if (!findStyle.hasAttribute("label")) {
			findStyle.setAttribute("label", document.getElementById("stylish-strings").getFormattedString("findStyleApp", [stylishCommon.getAppName()]));
		}
	},

	find: function(e) {
		var appName = stylishCommon.getAppName();
		var uri = "http://userstyles.org/style/search_text/" + encodeURIComponent(appName);
		if (appName == "Thunderbird") {
			uri = Components.classes["@mozilla.org/network/io-service;1"].getService(Components.interfaces.nsIIOService).newURI(uri, null, null);
			var protocolSvc = Components.classes["@mozilla.org/uriloader/external-protocol-service;1"].getService(Components.interfaces.nsIExternalProtocolService);
			protocolSvc.loadUrl(uri);
		} else if (appName == "SeaMonkey") {
			openUILinkIn(uri, "window");
		}
 	}
}
