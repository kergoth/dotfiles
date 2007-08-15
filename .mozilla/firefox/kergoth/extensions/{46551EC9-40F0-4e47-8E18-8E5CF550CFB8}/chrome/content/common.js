var stylishCommon = {

	hasSSSFix: !Components.ID('{41d979dc-ea03-4235-86ff-1e3c090c5630}').equals(Components.interfaces.nsIStyleSheetService),
	XULNS: "http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul",
	HTMLNS: "http://www.w3.org/1999/xhtml",
	codePrefix: "data:text/css,",
	editDialogOptions: "chrome,resizable,dialog=no,centerscreen",

	ios: Components.classes["@mozilla.org/network/io-service;1"].getService(Components.interfaces.nsIIOService),
	sss: Components.classes["@mozilla.org/content/style-sheet-service;1"].getService(Components.interfaces.nsIStyleSheetService),

	getDOMId: function(uri) {
		return "stylish-" + uri.substring(6, uri.length)
	},

	//Returns an array of all open documents, whether chrome or content
	getDocuments: function() {
		var docs = [];

		var ww = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService(Components.interfaces.nsIWindowMediator);
		var windows = ww.getXULWindowEnumerator(null);

		//For every window
		while (windows.hasMoreElements()) {
			//Get the window's main docshell
			var windowDocShell = windows.getNext().QueryInterface(Components.interfaces.nsIXULWindow).docShell;
			var containedDocShells = windowDocShell.getDocShellEnumerator(Components.interfaces.nsIDocShellTreeItem.typeAll, Components.interfaces.nsIDocShell.ENUMERATE_FORWARDS);
			//For every docshell in the window
			while (containedDocShells.hasMoreElements()) {
				// Get the corresponding document for this docshell
				var viewer = containedDocShells.getNext().QueryInterface(Components.interfaces.nsIDocShell).contentViewer;
				// Adblock might block iframes/frames. Null check the content viewer.
				if (viewer) {
					docs[docs.length] = viewer.DOMDocument;
				}
			}
		}
		return docs;
	},

	//open the edit dialog
	openEdit: function(style) {
		//we only want one window per style
		//knock out the invalid characters for the window name
		var windowName = "stylishEdit" + style.uri.replace(/\W/g, "");
		//if a window is already open, openDialog will clobber the changes made. check for an open window for this style
		//and focus to it
		var windowsMediator = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService(Components.interfaces.nsIWindowMediator);
		var win = windowsMediator.getMostRecentWindow(windowName);
		if (win) {
			win.focus();
		} else {
			openDialog("chrome://stylish/content/edit.xul", windowName, stylishCommon.editDialogOptions, {uri: style.uri, windowtype: windowName});
		}
	},

	reloadManage: function() {
		var ww = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService(Components.interfaces.nsIWindowMediator);
		var windows = ww.getXULWindowEnumerator(null);
		while (windows.hasMoreElements()) {
			// Get the window's main docshell
			var windowDocShell = windows.getNext().QueryInterface(Components.interfaces.nsIXULWindow).docShell;
			var containedDocShells = windowDocShell.getDocShellEnumerator(Components.interfaces.nsIDocShellTreeItem.typeChrome, Components.interfaces.nsIDocShell.ENUMERATE_FORWARDS);
			while (containedDocShells.hasMoreElements()) {
				// Get the corresponding document for this docshell
				var childDoc = containedDocShells.getNext().QueryInterface(Components.interfaces.nsIDocShell).contentViewer.DOMDocument;
				if (childDoc.location.href.indexOf("chrome://stylish/content/manage.xul") == 0) {
					childDoc.defaultView.init();
				}
			}
		}
	},

	add: function(code) {
		//give the window a random name so we can open many
		openDialog("chrome://stylish/content/edit.xul", stylishCommon.getRandomDialogName("stylishEdit"), stylishCommon.editDialogOptions, {code: code});
	},

	addDomain: function(domain) {
		var code = "@namespace url(http://www.w3.org/1999/xhtml);\n\n@-moz-document domain(\"" + domain + "\") {\n\n}";
		stylishCommon.add(code);
	},

	registerStyle: function(uri, css) {
		var cssURL = stylishCommon.codePrefix + css;
		var u = this.ios.newURI(cssURL, null, null);
		this.sss.loadAndRegisterSheet(u, this.sss.USER_SHEET);

		if (!this.hasSSSFix) {
			//instant apply
			var docs = this.getDocuments();
			for (var i = 0; i < docs.length; i++) {
				var childDoc = docs[i];
				var stylesheetLink = childDoc.createElementNS(this.HTMLNS, "link");
				stylesheetLink.id = this.getDOMId(uri);
				stylesheetLink.type = "text/css";
				stylesheetLink.rel = "stylesheet";
				stylesheetLink.href = cssURL;
				stylesheetLink.charset = "UTF-8"; 

				//we can't use xml processing instructions because then they'd get put into the DOM and some code in the codebase assumes that no processing instructions are in the DOM <https://bugzilla.mozilla.org/show_bug.cgi?id=319654>. so let's use html:link and try to put it in an appropriate place
				var nodeToAppendTo = null;
				//XHTML head
				var heads = childDoc.getElementsByTagNameNS(this.HTMLNS, "head");
				if (heads.length >= 1) {
					nodeToAppendTo = heads[0];
				}
				if (!nodeToAppendTo) {
					//HTML head
					var heads = childDoc.getElementsByTagNameNS(null, "head");
					if (heads.length >= 1) {
						nodeToAppendTo = heads[0];
					}
				}
				if (!nodeToAppendTo) {
					//just jam it in the document element and hope for the best
					nodeToAppendTo = childDoc.documentElement;
				}
				//XXX figure out why this can be still null
				if (nodeToAppendTo) {
					nodeToAppendTo.appendChild(stylesheetLink);
				}
			}
		}
	},

	unregisterStyle: function(uri, css) {
		var cssURL = this.codePrefix + css;
		//dump("unregistering " + this.code + "\n");
		var u = stylishCommon.ios.newURI(cssURL, null, null);
		if (this.sss.sheetRegistered(u, this.sss.USER_SHEET)) {
			this.sss.unregisterSheet(u, this.sss.USER_SHEET);
		}
		if (!this.hasSSSFix) {
			//instant unapply
			//when we put the link code it, it strips whitespace, so to find a match we need to compare it to a the URL with no whitespace
			var cssURLAttribute = cssURL.replace(/\n/, "");
			var docs = this.getDocuments();
			for (var i = 0; i < docs.length; i++) {
				var childDoc = docs[i];
				var link = childDoc.getElementById(this.getDOMId(uri));
				if (link) {
					link.parentNode.removeChild(link);
				}
			}
		}
	},

	//compares CSS, taking into account platform differences
	cssAreEqual: function(css1, css2) {
		if (css1 == null && css2 == null) {
			return true;
		}
		if (css1 == null || css2 == null) {
			return false;
		}
		return css1.replace(/\s/g, "") == css2.replace(/\s/g, "");
	},

	getRandomDialogName: function(prefix) {
		return prefix + String(Math.random()).split(".")[1];
	},

	getAppName: function() {
		var appInfo = Components.classes["@mozilla.org/xre/app-info;1"].getService(Components.interfaces.nsIXULAppInfo);
		return appInfo.name;
	},

	addAsSet: function(array, entry) {
		for (var i = 0; i < array.length; i++) {
			if (array[i] == entry) {
				return;
			}
		}
		array.push(entry);
	},

	dispatchEvent: function(doc, type) {
		if (!doc) {
			return;
		}
		var stylishEvent = doc.createEvent("Events");
		stylishEvent.initEvent(type, false, false, doc.defaultView, null);
		doc.dispatchEvent(stylishEvent);
	}

}
