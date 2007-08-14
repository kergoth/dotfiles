function StylishStyle(o) {
	//getNode will create a node if necessary
	if (typeof o == "string") {
		this.node = this.ds.getNode(o);
	} else if (o) {
		this.node = o;
	} else {
		this.node = this.ds.getAnonymousNode();
	}
	this._description = null;
	this._enabled = null;
	this._customized = null;
	this._code = null;
	this._originalCode = null;
	this._global = null;
	this._domains = null;
	this._siteURLPrefixes = null;
	this._siteURLs = null;
	this._namespaces = null;
	this._treeDisplayCode = null;
	this._appliesToDisplay = null;
	this._namespaceNames = null;
	this._updateURL = null;
	this._neverUpdate = null;
}

StylishStyle.prototype = {
	containerURI: "urn:stylish:userstyles",
	descriptionURI: "urn:stylish#description",
	enabledURI: "urn:stylish#enabled",
	customizedURI: "urn:stylish#customized",
	originalCodeURI: "urn:stylish#originalCode",
	codeURI: "urn:stylish#code",
	siteURLURI: "urn:stylish#url",
	updateURLURI: "urn:stylish#updateURL",
	siteURLPrefixURI: "urn:stylish#urlPrefix",
	siteDomainURI: "urn:stylish#domain",
	globalStyleURI: "urn:stylish#global",
	namespaceURI: "urn:stylish#namespace",
	neverUpdateURI: "urn:stylish#neverUpdate",
	documentRulePrefix: "@-moz-document ",

	//copies this style's attributes to the passed style
	copy: function(newStyle) {
		newStyle.description = this.description;
		newStyle.customized = this.customized;
		newStyle.originalCode = this.originalCode;
		newStyle.code = this.code;
		newStyle.siteURLs = this.siteURLs;
		if (this.updateURL) {
			newStyle.updateURL = this.updateURL;
		}
		newStyle.siteURLPrefixes = this.siteURLPrefixes;
		newStyle.domains = this.domains;
		newStyle.global = this.global;
		newStyle.namespaces = this.namespaces;
		newStyle.neverUpdate = this.neverUpdate;
		newStyle.enabled = this.enabled;
	},

	applyArray: function(uri, values) {
		var valueArray;
		if (values instanceof Array) {
			valueArray = values;
		} else {
			//maybe it's an rdf enumerator
			valueArray = [];
			while (values.hasMoreElements()) {
				valueArray.push(values.getNext());
			}
		}
		//unapply the previous values
		var targets = this.node.getTargets(uri);
		while (targets.hasMoreElements()) {
			var target = targets.getNext();
			this.node.removeTarget(uri, target);
		}
		//apply the new values
		for (var i = 0; i < valueArray.length; i++) {
			this.node.addTarget(uri, valueArray[i]);
		}
	},

	applyValue: function(uri, value) {
		var oldValue = this.node.getTarget(uri);
		if (oldValue) {
			this.node.modifyTarget(uri, oldValue, value);
		} else {
			this.node.addTarget(uri, value);
		}
	},

	register: function() {
		stylishCommon.registerStyle(this.uri, this.code);
	},

	unregister: function() {
		stylishCommon.unregisterStyle(this.uri, this.code);
	},

	get uri() {
		return this.node.source.Value;
	},

	get description() {
		if (this._description) {
			return this._description;
		}
		var descriptionLiteral = this.node.getTarget(this.descriptionURI);
		this._description = descriptionLiteral != null ? descriptionLiteral.getValue() : "";
		return this._description;
	},

	set description(description) {
		this.applyValue(this.descriptionURI, description);
		this._description = null;
	},

	get enabled() {
		if (this._enabled != null) {
			return this._enabled;
		}
		var enabledLiteral = this.node.getTarget(this.enabledURI);
		this._enabled = enabledLiteral != null ? enabledLiteral.getValue() == "true" : false;
		return this._enabled;
	},

	set enabled(enabled) {
		var newTarget;
		if (enabled) {
			this.register();
		} else {
			this.unregister();
		}
		this.applyValue(this.enabledURI, enabled ? "true" : "false");
		this._enabled = null;
	},

	enableWithoutRegister: function() {
		this.applyValue(this.enabledURI, "true");
		this._enabled = null;
	},

	get enabledString() {
		return "" + this.enabled;
	},

	set enabledString(enabledString) {
		this.enabled = enabledString == "true";
	},

	get customized() {
		if (this._customized) {
			return this._customized;
		}
		var customizedLiteral = this.node.getTarget(this.customizedURI);
		this._customized = customizedLiteral != null ? customizedLiteral.getValue() == "true": false;
		return this._customized;
	},

	set customized(customized) {
		this.applyValue(this.customizedURI, customized ? "true" : "false");
		this._customized = null;
	},

	get code() {
		if (this._code) {
			return this._code;
		}
		var codeLiteral = this.node.getTarget(this.codeURI);
		this._code = codeLiteral != null ? codeLiteral.getValue() : "";
		return this._code;
	},

	set code(code) {
		this.applyValue(this.codeURI, code);
		this._code = null;
	},

	get originalCode() {
		if (this._originalCode) {
			return this._originalCode;
		}
		var originalCodeLiteral = this.node.getTarget(this.originalCodeURI);
		this._originalCode = originalCodeLiteral != null ? originalCodeLiteral.getValue() : this.code;
		return this._originalCode;
	},

	set originalCode(originalCode) {
		this.applyValue(this.originalCodeURI, originalCode);
		this._originalCode = null;
	},

	get global() {
		if (this._global != null) {
			return this._global;
		}
		var globalLiteral = this.node.getTarget(this.globalStyleURI);
		this._global = globalLiteral != null ? globalLiteral.getValue() == "true" : false;			
		return this._global;
	},

	set global(globalStyle) {
		this.applyValue(this.globalStyleURI, globalStyle ? "true" : "false");
		this._global = null;
	},

	get domains() {
		if (this._domains) {
			return this._domains;
		}
		this._domains = this.node.getTargets(this.siteDomainURI);
		return this._domains;
	},

	set domains(domains) {
		this.applyArray(this.siteDomainURI, domains);
		this._domains = null;
	},

	get siteURLPrefixes() {
		if (this._siteURLPrefixes) {
			return this._siteURLPrefixes;
		}
		this._siteURLPrefixes = this.node.getTargets(this.siteURLPrefixURI);
		return this._siteURLPrefixes;
	},

	set siteURLPrefixes(prefixes) {
		this.applyArray(this.siteURLPrefixURI, prefixes);
		this._siteURLPrefixes = null;
	},

	get siteURLs() {
		if (this._siteURLs) {
			return this._siteURLs;
		}
		this._siteURLs = this.node.getTargets(this.siteURLURI);
		return this._siteURLs;
	},

	set siteURLs(urls) {
		this.applyArray(this.siteURLURI, urls);
		this._siteURLs = null;
	},

	get namespaces() {
		if (this._namespaces) {
			return this._namespaces
		}
		this._namespaces = this.node.getTargets(this.namespaceURI);
		return this._namespaces;
	},

	set namespaces(namespaces) {
		this.applyArray(this.namespaceURI, namespaces);
		this._namespaces = null;
	},

	get treeDisplayCode() {
		if (this._treeDisplayCode) {
			return this._treeDisplayCode;
		}
		//take out line breaks and limit to 100 chars
		this._treeDisplayCode = this.code.substring(0, 100).replace(/\n/g, " ");
		return this._treeDisplayCode;
	},

	get appliesToDisplayArray() {
		if (this.global) {
			var namespaceNames = this.namespaceNames;
			if (namespaceNames.length > 0) {
				return namespaceNames;
			}
			return [STRINGS.getString("globalDisplay")];
		}
		var components = [];
		var domains = this.domains;
		while (domains.hasMoreElements()) {
			stylishCommon.addAsSet(components, domains.getNext().getValue());
		}
		var urlPrefixes = this.siteURLPrefixes;
		while (urlPrefixes.hasMoreElements()) {
			stylishCommon.addAsSet(components, this.formatUrlPrefixForDisplay(urlPrefixes.getNext().getValue()));
		}
		var urls = this.siteURLs;
		while (urls.hasMoreElements()) {
			stylishCommon.addAsSet(components, this.formatUrlForDisplay(urls.getNext().getValue()));
		}
		return components;
	},

	get appliesToDisplay() {
		if (this._appliesToDisplay) {
			return this._appliesToDisplay;
		}
		this._appliesToDisplay = this.appliesToDisplayArray.join(", ");
		return this._appliesToDisplay;
	},

	formatUrlPrefixForDisplay: function(urlPrefix) {
		if (this.isUIUrl(urlPrefix)) {
			return STRINGS.getString("xulDisplay");
		}
		return urlPrefix + "*";
	},

	formatUrlForDisplay: function(url) {
		if (this.isUIUrl(url)) {
			return STRINGS.getString("xulDisplay");
		}
		return url;
	},

	isUIUrl: function(url) {
		return /^(chrome|about|x-jsd)/.test(url);
	},

	get namespaceNames() {
		if (this._namespaceNames) {
			return this._namespaceNames;
		}
		var namespaces = this.namespaces;
		this._namespaceNames = [];
		while (namespaces.hasMoreElements()) {
			var currentNamespace = namespaces.getNext().getValue();
			//STRINGS is defined in manage.js and edit.js, which is the only place that uses this code
			switch (currentNamespace) {
				case stylishCommon.XULNS:
					this._namespaceNames.push(STRINGS.getString("xulDisplay"));
					break;
				case stylishCommon.HTMLNS:
					this._namespaceNames.push(STRINGS.getString("htmlDisplay"));
					break;
				default:
					//since we don't want to show the full url, let's try grabbing the last
					//bit of the url. that works for SVG, XLink, and MathML, at least.
					this._namespaceNames[this._namespaceNames.length] = currentNamespace.substring(currentNamespace.lastIndexOf("/") + 1);
			}
		}
		return this._namespaceNames;
	},

	getParameterizedURI: function(parameter) {
		if (this.uri.substring(0, 3) == "urn" || this.uri.substring(0, 3) == "rdf") {
			return null;
		}		
		if (this.uri.indexOf("?") > -1) {
			return this.uri + "&" + parameter;
		}
		return this.uri + "?" + parameter;		
	},

	get updateURL() {
		if (this._updateURL) {
			return this._updateURL;
		}
		var updateURL = this.node.getTarget(this.updateURLURI);
		//fall back on adding a "?raw" to the end of the url
		if (updateURL) {
			this._updateURL = updateURL.getValue();
		} else {
			this._updateURL = this.getParameterizedURI("raw");
		}
		return this._updateURL;
	},

	set updateURL(updateURL) {
		this.applyValue(this.updateURLURI, updateURL);
		this._updateURL = null;
	},

	get neverUpdate() {
		if (this._neverUpdate != null) {
			return this._neverUpdate;
		}
		var neverUpdateLiteral = this.node.getTarget(this.neverUpdateURI);
		this._neverUpdate = neverUpdateLiteral != null ? neverUpdateLiteral.getValue() == "true" : false;			
		return this._neverUpdate;
	},

	set neverUpdate(neverUpdate) {
		this.applyValue(this.neverUpdateURI, neverUpdate ? "true" : "false");
		this._neverUpdate = null;
	},

	checkForUpdate: function(callback) {
		if (this.neverUpdate) {
			callback(null);
			return;
		}
		var updateURL = this.updateURL;
		if (!updateURL) {
			callback(null);
			return;
		}
		var currentCode = this.originalCode;
		var req = new XMLHttpRequest();
		req.open('GET', updateURL, true);
		req.cancelled = false;
		var requestTimer = setTimeout(function() { req.cancelled = true; req.abort(); }, 5000);
		req.onreadystatechange = function() {
			if (req.readyState != 4) {
				return;
			}
			clearTimeout(requestTimer);
			//some servers (like webrick) include charset at the end of the content type header
			if (req.cancelled || req.status != 200 || req.getResponseHeader("Content-Type").indexOf("text/css") != 0) {
				callback(null);
				return;
			}
			if (!stylishCommon.cssAreEqual(req.responseText, currentCode)) {
				callback(req.responseText);
				return;
			}
			callback(null);
		}
		try {
			req.send(null);
		} catch (ex) {
			alert(updateURL);
			callback(null);
			return;
		}
	},

	save: function() {
		this.ds.getNode(this.containerURI).addChild(this.node);
		this.ds.save();
	},

	//Returns extensions.style.fileURL if set, otherwise "file://(profile folder)/stylish.rdf"
	getDatasourceURI: function() {
		var prefs = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
		var prefPath = prefs.getCharPref("extensions.stylish.fileURL");
		if (prefPath.length > 0) {
			return prefPath;
		}
		var file = Components.classes["@mozilla.org/file/directory_service;1"].getService(Components.interfaces.nsIProperties).get("ProfD", Components.interfaces.nsIFile);
		file.append("stylish.rdf");
		var ioService = Components.classes["@mozilla.org/network/io-service;1"].getService(Components.interfaces.nsIIOService);
		if (!file.exists()) {
			//either this is the first run or the user deleted his file (the bastard)
			//read the default file's contents (courtesy Torisugari <http://forums.mozillazine.org/viewtopic.php?p=921150#921150>)
			var scriptableStream = Components.classes["@mozilla.org/scriptableinputstream;1"].getService(Components.interfaces.nsIScriptableInputStream);
			var channel = ioService.newChannel("chrome://stylish/content/stylish-default.rdf", null, null);
			var input = channel.open();
			scriptableStream.init(input);
			var data = scriptableStream.read(input.available());
			scriptableStream.close();
			input.close();

			//write the contents to the profile file
			var foStream = Components.classes["@mozilla.org/network/file-output-stream;1"].createInstance(Components.interfaces.nsIFileOutputStream);
			foStream.init(file, 0x02 | 0x08 | 0x20, 0664, 0); // write, create, truncate
			foStream.write(data, data.length);
			foStream.close();
		}
		return ioService.newFileURI(file).spec;
	},

	calculateMetadata: function(stylesheet) {
		//get an array of document rules
		var domains = [];
		var urlPrefixes = [];
		var urls = [];
		var namespaces = [];
		var isGlobal = false;
		for (var i = 0; i < stylesheet.cssRules.length; i++) {
			var rule = stylesheet.cssRules[i];
			var isDocRule;
			try {
				rule.QueryInterface(Components.interfaces.nsIDOMCSSMozDocumentRule);
				isDocRule = true;
			} catch (ex) {
				if (ex.name == "NS_NOINTERFACE") {
					isDocRule = false;
					//see if this has a global portion
					if (rule.type == Components.interfaces.nsIDOMCSSRule.STYLE_RULE) {
						isGlobal = true;
					} else if (rule.type == Components.interfaces.nsIDOMCSSRule.UNKNOWN_RULE) {
						//get the namespaces
						if (rule.cssText.indexOf("@namespace") == 0) {
							var start = rule.cssText.indexOf("url(");
							var end = rule.cssText.lastIndexOf(")");
							namespaces[namespaces.length] = rule.cssText.substring(start + 4, end);
						}
					}
				} else {
					throw ex;
				}
			}
			if (isDocRule) {
				//get an array of the sites it applies to
				var mozDocPosition = rule.cssText.indexOf(StylishStyle.prototype.documentRulePrefix);
				if (mozDocPosition == -1) {
					alert("Rule QIs to moz-document but moz-document string not found.");
					continue;
				}
				var mozDocEnd = rule.cssText.indexOf(" {");
				var sitesString = rule.cssText.substring(mozDocPosition + StylishStyle.prototype.documentRulePrefix.length, mozDocEnd - 1);
				//this could fail if a url contains ", " in it. probably won't happen
				var sites = sitesString.split(", ");
				for (var j = 0; j < sites.length; j++) {
					var openParenthesis = sites[j].indexOf("(\"");
					//open parenthesis + the size of (". length - 1 for zero based - 1 for the closing arenthesis
					var site = sites[j].substring(openParenthesis + 2, sites[j].length - 2);
					var type = sites[j].substring(0, openParenthesis);
					switch (type) {
						case "url":
							urls[urls.length] = site;
							break;
						case "url-prefix":
							//if it's just a http://-type rule, mark it as global
							if (site.indexOf(":") == -1 || /^(^\/)*:\/?\/?$/.test(site)) {
								isGlobal = true;
							} else {
								urlPrefixes[urlPrefixes.length] = site;
							}
							break;
						case "domain":
							domains[domains.length] = site;
							break;
						default:
							alert("Unrecognized site rule type '" + type + "'.");
					}
				}
			}
		}
		this.global = isGlobal;
		this.namespaces = namespaces;
		this.domains = domains;
		this.siteURLs = urls;
		this.siteURLPrefixes = urlPrefixes;
	},

	appliesToNamespace: function(namespace) {
		var styleNamespaces = this.namespaces;
		//no namespaces - yes
		if (!styleNamespaces.hasMoreElements()) {
			return true;
		}
		while (styleNamespaces.hasMoreElements()) {
			if (styleNamespaces.getNext().getValue() == namespace) {
				return true;
			}
		}
		return false;
	}
}
StylishStyle.prototype.ds = new StylishRDFDataSource(StylishStyle.prototype.getDatasourceURI());

var loadedListener;
function StylishStylesheetLoadedListener(doc, errorListener, callback) {
	loadedListener = this;
	this.doc = doc; 
	this.errorListener = errorListener;
	this.callback = callback;
}
StylishStylesheetLoadedListener.prototype = {
	checkStyleLoaded: function() {
		//any errors in here will seriously bork us. make sure to at least tell the user
		try {
			try {
				var stylesheet = loadedListener.doc.QueryInterface(Components.interfaces.nsIDOMDocumentStyle).styleSheets[0];
				//this'll throw if it's not done loading
				stylesheet.cssRules.length;
			} catch (ex) {
				if (ex.name == "NS_ERROR_DOM_INVALID_ACCESS_ERR") {
					//try again
					setTimeout(loadedListener.checkStyleLoaded, 100);
				} else {
					//some other error happened
					loadedListener.unregisterErrorListener();
					var data = {exception: ex, stylesheet: stylesheet, errors: loadedListener.errorListener.errors};
					loadedListener.callback(false, data);
					loadedListener.destroy();
				}
				return;
			}
			loadedListener.unregisterErrorListener();
			if (loadedListener.errorListener) {
				loadedListener.callback(true, {stylesheet: stylesheet, errors: loadedListener.errorListener.errors});
			} else {
				loadedListener.callback(true, {stylesheet: stylesheet, errors: []});
			}
			//the callback actually destroys the window, so this won't work here
			//loadedListener.destroy();
		} catch (ex) {
			Components.utils.reportError(ex);
			alert(ex);
		}
	},

	unregisterErrorListener: function() {
		var consoleService = Components.classes["@mozilla.org/consoleservice;1"].getService(Components.interfaces.nsIConsoleService);
		consoleService.unregisterListener(loadedListener.errorListener);
	},

	destroy: function() {
		loadedListener = null;
	}
}
