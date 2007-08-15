var stylishCommonOverlay = {
	openManageStyles: function() {
		var windowName = "stylish";
		var windowsMediator = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService(Components.interfaces.nsIWindowMediator);
		var win = windowsMediator.getMostRecentWindow(windowName);
		if (win) {
			win.focus();
		} else {
			openDialog("chrome://stylish/content/manage.xul", windowName, "chrome,resizable,dialog=no,centerscreen");
		}
	},

	handleStatusClick: function(event) {
		//show the menu on right-click
		if (event.target.id == "stylish-panel") {
			if (event.button == 2) {
				event.target.firstChild.showPopup();
			} else if (event.button == 1) {
				//open manage styles on middle click
				stylishCommonOverlay.openManageStyles();
			}
		}
	},

	addBlank: function() {
		stylishCommon.add("");
	},

	clearMenu: function(event) {
		var popup = event.target;
		while (popup.hasChildNodes()) {
			popup.removeChild(popup.firstChild);
		}
	}
}
