var stylishBrowserOverlay = {
	MAIN_POPUPS: ["stylish-status-popup", "stylish-toolbar-popup", "stylish-tools-menu-popup", "stylish-seamonkey-tools-menu-popup"],
	pageStyleMenu: null,

	init: function() {		stylishBrowserOverlay.STRINGS = document.getElementById("stylish-strings");
		stylishBrowserOverlay.URL_STRINGS = document.getElementById("stylish-url-strings");
		//page load listener
		var appcontent = document.getElementById("appcontent"); // browser
		if (!appcontent) {
			appcontent = document.getElementById("frame_main_pane"); // songbird
		}
		if (appcontent) {
			appcontent.addEventListener("DOMContentLoaded", stylishBrowserOverlay.onPageLoad, true);
		}
		//page style menu item adder
		pageStyleMenu = document.getElementById("pageStyleMenu") || document.getElementById("menu_UseStyleSheet");
		if (pageStyleMenu) {
			pageStyleMenu.firstChild.addEventListener("popupshowing", stylishBrowserOverlay.pageStylePopupShowing, false);
			pageStyleMenu.firstChild.addEventListener("popuphiding", stylishBrowserOverlay.pageStylePopupHiding, false);
		}
	},

	isAllowedToInstall: function(doc) {
		//this can throw for some reason
		try {
			var domain = doc.domain;
		} catch (ex) {
			return false;
		}
		if (!domain) {
			return false;
		}
		var prefs = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefService);
		prefs = prefs.getBranch("extensions.stylish.install.");
		var allowedDomains = prefs.getCharPref("allowedDomains").split(" ");
		if (allowedDomains.indexOf(doc.domain) > -1) {
			return true;
		}
		//maybe this is a subdomain 
		for (var i = 0; i < allowedDomains.length; i++) {
			var subdomain = "." + allowedDomains[i];
			var subdomainIndex = doc.domain.lastIndexOf(subdomain);
			if (subdomainIndex > -1 && subdomainIndex == doc.domain.length - subdomain.length) {
				return true;
			}
		}
		return false;
	},

	cleanURI: function(uri) {
		var hash = uri.indexOf("#");
		if (hash > -1) {
			uri = uri.substring(0, hash);
		}
		return uri;
	},

	onPageLoad: function(event) {
		if (event.originalTarget.nodeName == "#document" && stylishBrowserOverlay.isAllowedToInstall(event.originalTarget)) {
			var doc = event.originalTarget;

			//style installed status
			var uri = stylishBrowserOverlay.cleanURI(doc.location.href);
			var enumerator = StylishStyle.prototype.ds.getAllResources();
			var style = null;
			var found = false;
			while (enumerator.hasMoreElements()) {
				var node = enumerator.getNext();
				style = new StylishStyle(node);
				if (style.uri == uri) {
					found = true;
					break;
				}
			}
			if (!found) {
				stylishCommon.dispatchEvent(doc, "styleCanBeInstalled");
				doc.addEventListener("stylishInstall", stylishBrowserOverlay.installFromSite, false);
			} else {
				//workaround for bug 194231 
				var codeTextNodes = doc.getElementById("stylish-code").childNodes;
				var code = ""
				for (var i = 0; i < codeTextNodes.length; i++) {
					code += codeTextNodes[i].nodeValue;
				}
				if (!stylishCommon.cssAreEqual(style.originalCode, code)) {
					stylishCommon.dispatchEvent(doc, "styleCanBeUpdated");
					doc.addEventListener("stylishUpdate", stylishBrowserOverlay.updateFromSite, false);
				} else {
					stylishCommon.dispatchEvent(doc, "styleAlreadyInstalled");
				}
			}

			//post style listeners
			doc.addEventListener("postFromStylish", stylishBrowserOverlay.provideStyleInfo, false);
			doc.addEventListener("postedFromStylish", stylishBrowserOverlay.updateStyleURI, false);
			
		}
	},

	installFromSite: function(event) {
		var doc;
		if (event.target.nodeName == "#document") {
			doc = event.target;
		}
		var uri = stylishBrowserOverlay.cleanURI(doc.location.href);
		var links = doc.getElementsByTagName("link");
		var code = null;
		var description = null;
		var updateURL = null;
		var installPingURL = null;
		var triggeringDocument = null;
		for (i in links) {
			switch (links[i].rel) {
				case "stylish-code":
					var id = links[i].getAttribute("href").replace("#", "");
					var element = doc.getElementById(id);
					if (element) {
						code = element.textContent;
					}
					break;
				case "stylish-description":
					var id = links[i].getAttribute("href").replace("#", "");
					var element = doc.getElementById(id);
					if (element) {
						description = element.textContent;
					}
					break;
				case "stylish-install-ping-url":
					installPingURL = links[i].href;
					break;
				case "stylish-update-url":
					updateURL = links[i].href;
					break;				
			}
		}
		openDialog("chrome://stylish/content/edit.xul", "stylishEdit" + Math.random(), stylishCommon.editDialogOptions, {uri: uri, description: description, code: code, updateURL: updateURL, installPingURL: installPingURL, triggeringDocument: doc});
	},

	updateFromSite: function(event) {
		var doc = event.target;
		var uri = stylishBrowserOverlay.cleanURI(doc.location.href);
		var enumerator = StylishStyle.prototype.ds.getAllResources();
		var style = null;
		var found = false;
		while (enumerator.hasMoreElements()) {
			style = new StylishStyle(enumerator.getNext());
			if (style.uri == uri) {
				found = true;
				break;
			}
		}
		if (!found) {
			return;
		}
		//knock out the invalid characters for the window name
		var windowName = "stylishEdit" + style.uri.replace(/\W/g, "");
		var links = doc.getElementsByTagName("link");
		var code = null;
		for (i in links) {
			switch (links[i].rel) {
				case "stylish-code":
					var id = links[i].getAttribute("href").replace("#", "");
					var element = doc.getElementById(id);
					if (element) {
						code = element.textContent;
					}
					break;
			}
		}
		openDialog("chrome://stylish/content/edit.xul", windowName, stylishCommon.editDialogOptions, {uri: style.uri, code: code, windowtype: windowName, triggeringDocument: doc});
	},

	provideStyleInfo: function(event) {
		var doc = event.target;
		var style = new StylishStyle(doc.getElementById("stylish-uri").value);
		if (style.code) {
			var data = {code: style.code, shortDescription: style.description};
			doc.getElementById("stylish-info").value = data.toSource();
			var stylishEvent = doc.createEvent("Events");
			stylishEvent.initEvent("postFromStylishReturn", false, false, doc.defaultView, null); 
			doc.dispatchEvent(stylishEvent);
		} else {
			StylishStyle.prototype.ds.deleteRecursive(style.node);
		}
	},

	updateStyleURI: function(event) {
		var doc = event.target;
		var oldStyle = new StylishStyle(doc.getElementById("old-uri").value);
		var newStyle = new StylishStyle(doc.getElementById("new-uri").value);
		oldStyle.copy(newStyle);
		StylishStyle.prototype.ds.deleteRecursive(oldStyle.node);
		newStyle.updateURL = doc.getElementById("new-update-uri").value
		newStyle.save();
		stylishCommon.reloadManage();
	},

	mainPopupShowing: function(event) {
		var popup = event.target;
		switch (this.MAIN_POPUPS.indexOf(popup.id)) {
			case -1:
				//this was called on the children of the popups we care about, so bail in that case
				return;
			case 0:
				//the primary popup, do nothing special
				break;
			default:
				//a secondary popup, copy the stuff from the primary popup
				var primary = document.getElementById(this.MAIN_POPUPS[0]);
				for (var i = 0; i < primary.childNodes.length; i++) {
					popup.appendChild(primary.childNodes[i].cloneNode(true));
				}
		}

		document.getElementById("stylish-add-file").style.display = (content.document.contentType == "text/css") ? "-moz-box" : "none";

		var applicableStyles = stylishBrowserOverlay.getApplicableStyles();
		if (applicableStyles.length > 0) {
			stylishBrowserOverlay.appendStyleMenuItems(popup, applicableStyles);
		}
	},

	writeStylePopupShowing: function(event) {
		var popup = event.target;
		var addSite = document.createElementNS(stylishCommon.XULNS, "menuitem");
		addSite.setAttribute("label", stylishBrowserOverlay.STRINGS.getString("writeForSite"));
		addSite.setAttribute("accesskey", stylishBrowserOverlay.STRINGS.getString("writeForSiteAccesskey"));
		addSite.setAttribute("oncommand", "stylishBrowserOverlay.addSite()");
		popup.appendChild(addSite);

		if (content.document.domain) {
			var domains = [];
			stylishBrowserOverlay.getDomainList(content.document.domain, domains);
			for (var i = 0; i < domains.length; i++) {
				popup.appendChild(stylishBrowserOverlay.getDomainMenuItem(domains[i]));
			}
		}

		addSite = document.createElementNS(stylishCommon.XULNS, "menuitem");
		addSite.setAttribute("label", stylishBrowserOverlay.STRINGS.getString("writeBlank"));
		addSite.setAttribute("accesskey", stylishBrowserOverlay.STRINGS.getString("writeBlankAccesskey"));
		addSite.setAttribute("oncommand", "stylishCommonOverlay.addBlank()");
		popup.appendChild(addSite);
	},

	pageStylePopupShowing: function(event) {
		var popup = event.target;
		//this fires for its children too, but we don't want to do anything
		if (popup != pageStyleMenu.firstChild) {
			return;
		}
		var separator = document.createElementNS(stylishCommon.XULNS, "menuseparator");
		separator.id = "stylishPageStyleSeparator";
		popup.appendChild(separator);
		popup.appendChild(document.getElementById("stylish-global-styles").cloneNode(true));
		var applicableStyles = stylishBrowserOverlay.getApplicableStyles();
		if (applicableStyles.length > 0) {
			stylishBrowserOverlay.appendStyleMenuItems(popup, applicableStyles);
		}
	},

	pageStylePopupHiding: function(event) {
		var popup = event.target;
		//this fires for its children too, but we don't want to do anything
		if (popup != pageStyleMenu) {
			return;
		}
		//wipe out the stuff we added
		var separator = document.getElementById("stylishPageStyleSeparator");
		while (separator.nextSibling) {
			separator.parentNode.removeChild(separator.nextSibling);
		}
		separator.parentNode.removeChild(separator);
	},

	appendStyleMenuItems: function(popup, styles) {
		for (var i = 0; i < styles.length; i++) {
			//we don't want a messed up entry to screw up the rest of the list
			try {
				popup.appendChild(stylishBrowserOverlay.getApplicableStyleMenuItem(styles[i], i));
			} catch (ex) {
				Components.utils.reportError(ex);
			}
		}
	},

	getContainedDocuments: function(docShell) {
		var docs = [];
		// Load all the window's content docShells
		var containedDocShells = docShell.getDocShellEnumerator(Components.interfaces.nsIDocShellTreeItem.typeAll, Components.interfaces.nsIDocShell.ENUMERATE_FORWARDS);
		while (containedDocShells.hasMoreElements()) {
			// Get the corresponding document for this docshell
			try {
				//this can fail for loading documents
				var doc = containedDocShells.getNext().QueryInterface(Components.interfaces.nsIDocShell).contentViewer.DOMDocument;
				docs.push(doc);
			} catch (ex) {
				dump(ex);
			}
		}
		return docs;
	},

	getGlobalStyles: function() {
		var globalStyles = [];
		var resourceEnumerator = StylishStyle.prototype.ds.getNode(StylishStyle.prototype.containerURI).getChildren();
		var applicableStyles = [];

		while (resourceEnumerator.hasMoreElements()) {
			var style = new StylishStyle(resourceEnumerator.getNext());
			if (style.global && style.appliesToNamespace(stylishCommon.HTMLNS)) {
				globalStyles.push(style);
			}
		}
		return globalStyles;
	},

	getDomainList: function(domain, array) {
		//don't want to list tlds
		if (Components.interfaces.nsIEffectiveTLDService) {
			var tld = Components.classes["@mozilla.org/network/effective-tld-service;1"].getService(Components.interfaces.nsIEffectiveTLDService);
			if (domain.length <= tld.getEffectiveTLDLength(domain)) {
				return;
			}
		}
		array[array.length] = domain;
		var firstDot = domain.indexOf(".");
		var lastDot = domain.lastIndexOf(".");
		if (firstDot != lastDot) {
			//if after the last dot it's a number, this is an ip address, so it's not part of a domain
			if (!isNaN(parseInt(domain.substring(lastDot + 1, domain.length)))) {
				return;
			}
			stylishBrowserOverlay.getDomainList(domain.substring(firstDot + 1, domain.length), array);
		}
	},

	getDomainMenuItem: function(domain) {
		var addSite = document.createElementNS(stylishCommon.XULNS, "menuitem");
		addSite.setAttribute("label", stylishBrowserOverlay.STRINGS.getFormattedString("writeForDomain", [domain]));
		addSite.setAttribute("oncommand", "stylishCommon.addDomain(\"" + domain + "\")");
		return addSite;
	},

	getApplicableStyleMenuItem: function(style, position) {
		var item = document.createElementNS(stylishCommon.XULNS, "menuitem");
		item.setAttribute("label", style.description);
		item.setAttribute("type", "checkbox");
		item.setAttribute("checked", style.enabled);
		item.stylishStyle = style;
		item.setAttribute("oncommand", "stylishBrowserOverlay.styleMenuItemCommand(event, this.stylishStyle)");
		item.setAttribute("onclick", "stylishBrowserOverlay.handleStyleMenuItemClick(event, this.stylishStyle)");
		item.setAttribute("class", "style-menu-item");
		if (position < 9) {
			item.setAttribute("accesskey", position + 1);
		}
		return item;		
	},

	styleMenuItemCommand: function(event, style) {
		style.enabled = !style.enabled;
		StylishStyle.prototype.ds.save();
		stylishCommon.reloadManage();
		event.stopPropagation();
	},

	handleStyleMenuItemClick: function(event, style) {
		//right-click opens edit window
		if (event.button == 2) {
			stylishCommon.openEdit(style);
			//close the menu
			var element = event.target;
			while (element) {
				if (element.nodeName == "menupopup") {
					element.hidePopup();
				}
				element = element.parentNode;
			}
			event.stopPropagation();
		}
	},

	getApplicableStyles: function() {
		var resourceEnumerator = StylishStyle.prototype.ds.getNode(StylishStyle.prototype.containerURI).getChildren();
		var applicableStyles = [];
		while (resourceEnumerator.hasMoreElements()) {
			var matches = false;
			var style = new StylishStyle(resourceEnumerator.getNext());
			var targetEnumerator = style.siteURLs;
			while (!matches && targetEnumerator.hasMoreElements()) {
				var siteURL = targetEnumerator.getNext().getValue();
				if (this.cleanURI(content.document.location.href) == this.cleanURI(siteURL)) {
					applicableStyles.push(style);
					matches = true;
				}
			}
			targetEnumerator = style.siteURLPrefixes;
			while (!matches && targetEnumerator.hasMoreElements()) {
				var siteURLPrefix = targetEnumerator.getNext().getValue();
				if (content.document.location.href.indexOf(siteURLPrefix) == 0) {
					applicableStyles.push(style);
					matches = true;
				}
			}
			var domain = content.document.domain;
			if (domain) {
				targetEnumerator = style.domains;
				while (!matches && targetEnumerator.hasMoreElements()) {
					var siteDomain = targetEnumerator.getNext().getValue();
					if (siteDomain == domain) {
						applicableStyles.push(style);
						matches = true;
					} else {
						//maybe this is a subdomain
						var subdomain = "." + siteDomain;
						var domainPosition = domain.indexOf(subdomain);
						if (domainPosition > -1 && domainPosition == domain.length - subdomain.length) {
							applicableStyles.push(style);
							matches = true;
						}
					}
				}
			}
		}
		return applicableStyles;
	},

	findStyle: function(e) {
		openUILinkIn(stylishBrowserOverlay.URL_STRINGS.getFormattedString("stylishSearchUrl", [encodeURIComponent(content.location.href)]), "tab");
	},

	openSidebar: function() {
		toggleSidebar("viewStylishSidebar");
	},

	showGlobalStyles: function(event) {
		var popup = event.target;
		var globalStyles = stylishBrowserOverlay.getGlobalStyles();
		if (globalStyles.length == 0) {
			var noneMenuItem = document.createElementNS(stylishCommon.XULNS, "menuitem");
			noneMenuItem.setAttribute("label", stylishBrowserOverlay.STRINGS.getString("noGlobalStyles"));
			noneMenuItem.setAttribute("disabled", "true");
			noneMenuItem.className = "no-style-menu-item";
			popup.appendChild(noneMenuItem);
		} else {
			stylishBrowserOverlay.appendStyleMenuItems(popup, globalStyles);
		}
		event.stopPropagation();
	},

	clearStyleMenuItems: function(event) {
		var popup = event.target;
		for (var i = popup.childNodes.length - 1; i >= 0; i--) {
			if (popup.childNodes[i].className == "style-menu-item" || popup.childNodes[i].className == "no-style-menu-item") {
				popup.removeChild(popup.childNodes[i]);
			}
		}
	},

	addFile: function() {
		openDialog("chrome://stylish/content/edit.xul", stylishCommon.getRandomDialogName("stylishEdit"), stylishCommon.editDialogOptions, {uri: content.document.location.href, code: content.document.childNodes[0].textContent, updateURL: content.document.location.href});
	},

	addSite: function() {
		var url = content.location.href;
		var code = "@namespace url(http://www.w3.org/1999/xhtml);\n\n@-moz-document url(\"" + url + "\") {\n\n}";
		stylishCommon.add(code);
	}
}

addEventListener("load", stylishBrowserOverlay.init, false);
