if (typeof openUILinkIn == "undefined") {
	function openUILinkIn(url, where, allowThirdPartyFixup, postData) {
		if (!where || !url) {
			return;
		}
		if (where == "save") {
			saveURL(url, null, null, true);
			return;
		}

		var w = getTopWin();

		if (!w || where == "window") {
			openDialog(getBrowserURL(), "_blank", "chrome,all,dialog=no,centerscreen", url, null, null, postData, allowThirdPartyFixup);
			return;
		}
		var browser = w.document.getElementById("content");
		var loadInBackground = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch).getBoolPref("browser.tabs.loadInBackground", "false");

		switch (where) {
			case "current":
				browser.loadURI(url);
				w.content.focus();
				break;
			case "tabshifted":
				loadInBackground = !loadInBackground;
				// fall through
			case "tab":
				browser.addTab(url, null, null, !loadInBackground);
				break;
		}
	}
}

if (typeof checkForMiddleClick == "undefined") {
	function checkForMiddleClick() {
		//meh
	}
}
