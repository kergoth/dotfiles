const CSSXULNS = "@namespace url(http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul);";
const CSSHTMLNS = "@namespace url(http://www.w3.org/1999/xhtml);";
var style = null;
var initialCode = ""; //the code we started with (for save checks)
var appliedCode = null; //the current code applied (to be able to unapply it)
var updateOriginalCode = false; //whether to update the original code, for example on install or update
var updateURL = null;
var triggeringDocument = null; //the document that triggered this dialog - we dispatch events back to it
var installPingURL = null; //the url to ping when saving
var newStyle = false;
//there are ways that the dialog can close without ondialogcancel firing. we don't want to half-save a style, so on save this gets set to true. onunload, if it's a new style, we delete it
var keepStyleOnClose = false;

var descriptionElement, codeElement, enabledElement, neverUpdateElement, STRINGS, URLS, prefs;

//load it's all text, if available
try {
	Components.classes["@mozilla.org/moz/jssubscript-loader;1"].getService(Components.interfaces.mozIJSSubScriptLoader).loadSubScript('chrome://itsalltext/content/API.js');
} catch(e) {}

//fill the values
function init() {
	STRINGS = document.getElementById("strings");
	URLS = document.getElementById("urls");

	descriptionElement = document.getElementById("description");
	codeElement = document.getElementById("code");
	enabledElement = document.getElementById("enabled");
	neverUpdateElement = document.getElementById("allow-updates");
	//wrap?
	prefs = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefService);
	prefs = prefs.getBranch("extensions.stylish.");
	var wrapLines = prefs.getBoolPref("wrap_lines");
	refreshWordWrap(wrapLines);
	document.getElementById("wrap-lines").checked = wrapLines;

	//detect the presence of rainbowpicker
	var rainbowPicker = document.getElementById("rainbowpicker-detect");
	if (getComputedStyle(rainbowPicker, "").MozBinding == "url(chrome://rainbowpicker/content/colorpicker.xml#colorpicker-button)") {
		document.getElementById("pick-color-rainbowpicker").style.display = "-moz-box";
		document.getElementById("pick-color").style.display = "none";
	}

	var o = window.arguments ? window.arguments[0] : {};
	//check for a request parameter
	if (/uri=/.test(location.href)) {
		o.uri = decodeURIComponent(location.href.substring(location.href.indexOf("uri=") + 4));
	}
	if ("uri" in o) {
		//an existing style, or one loaded from a site
		style = new StylishStyle(o.uri);
		//styles need code, so if this one doesn't have one, this is one from a site
		newStyle = !(style.code);

		if ("description" in o) {
			style.description = o.description;
		}
		descriptionElement.value = style.description;
		document.title = style.description;

		if (style.enabled) {
			appliedCode = style.code;
		}

		//if we've been passed in some code, that means the user hasn't entered it themselves. update the original code
		if ("code" in o) {
			updateOriginalCode = true;
			style.code = o.code;
		}
		if ("updateURL" in o) {
			style.updateURL = o.updateURL;
		}
		if ("installPingURL" in o) {
			installPingURL = o.installPingURL;
		}
		if ("triggeringDocument" in o) {
			triggeringDocument = o.triggeringDocument;
		}
	} else {
		//a brand new style
		document.title = STRINGS.getString("addStyle");
		style = new StylishStyle();
		//default to enabled, but we don't want to register it, so use the back door
		style._enabled = true;
		//we might have a template, for example a moz-doc
		if ("code" in o) {
			style.code = o.code;
		}
		newStyle = true;
	}

	initialEnabled = style.enabled;
	initialCode = style.code;
	codeElement.value = style.code;
	//we want to default to enabled for new styles, but not apply them, which is what the enabled setter will do
	enabledElement.checked = newStyle ? true : style.enabled;
	neverUpdateElement.checked = !style.neverUpdate;
	if ("windowtype" in o) {
		document.documentElement.setAttribute("windowtype", o.windowtype);
	}
	//is this a style installed by the site, where we have everything we need?
	if (newStyle && style.description) {
		document.getElementById("basic-view").style.display = "-moz-box";
		document.getElementById("advanced-view").style.display = "-moz-box";
		refreshBasicDisplay();
		document.getElementById("deck").selectedIndex = prefs.getIntPref("newStyleView");
	}
	//rdf uris and urns are internal
	var internalURI = style.uri.substring(0, 3) == "rdf" || style.uri.substring(0, 3) == "urn"
	if (internalURI) {
		neverUpdateElement.style.display = "none";
		if (newStyle) {
			document.getElementById("userstyles-link").style.display = "inline";
		} else {
			var link = document.getElementById("post-to-userstyles");
			link.setAttribute("href", URLS.getFormattedString("postToUserstylesUrl", [encodeURIComponent(style.uri)]));
			link.style.display = "inline";
		}
	} else {
		var link = document.getElementById("style-url-link");
		link.setAttribute("href", style.uri);
		link.style.display = "inline";
	}
	if (newStyle) {
		enabledElement.style.display = "none";
	}
}

//validate the user entries, throws an exception on invalid
function validate() {
	if (!previewOnly && (descriptionElement.value == null || descriptionElement.value == "")) {
		descriptionElement.focus();
		alert(STRINGS.getString("blankDescription"));
		return false;
	}
	if (codeElement.value == null || codeElement.value == "") {
		codeElement.focus();
		alert(STRINGS.getString("blankCode"));
		return false;
	}
	return true;
}

function cancelDialog() {
	var close = true;
	//did it change?
	if (!stylishCommon.cssAreEqual(codeElement.value, initialCode)) {
		var prompts = Components.classes["@mozilla.org/embedcomp/prompt-service;1"].getService(Components.interfaces.nsIPromptService);
		var button = prompts.confirmEx(window, STRINGS.getString("discardChangesTitle"), STRINGS.getString("discardChangesMessage"), prompts.BUTTON_POS_0 * prompts.BUTTON_TITLE_IS_STRING + prompts.BUTTON_POS_1 * prompts.BUTTON_TITLE_IS_STRING, STRINGS.getString("discardChangesDiscard"), STRINGS.getString("discardChangesReturn"), null, null, {value: false});
		close = button == 0;
	}
	if (close) {
		//if the user has previewed something and:
		// - the code previewed is different than the original code
		// - this is a new style
		// - the style was not enabled initially
		//then unapply what was previewed
		if (appliedCode && (appliedCode != style.code || newStyle || !style.enabled)) {
			stylishCommon.unregisterStyle(style.uri, appliedCode);
			//reregister the style if it existing previously and was enabled
			if (!newStyle && style.enabled) {
				style.register();
			}
		}
	}
	return close;
}

function refreshBasicDisplay() {
	loadAppliesTo();
	var simpleDescription = document.getElementById("simple-description");
	while (simpleDescription.firstChild) {
		simpleDescription.removeChild(simpleDescription.firstChild);
	}
	simpleDescription.appendChild(document.createTextNode(STRINGS.getFormattedString("basicIntro", [descriptionElement.value])));
}

function saveViewPreference() {
	prefs.setIntPref("newStyleView", document.getElementById("deck").selectedIndex);
}

/* Creates a stylesheet out of the code the user enters. It's asynchronous, so once the stylesheet is loaded, endLoadStylesheet gets called. */
function startLoadStylesheet() {
	//we want to check for errors
	var consoleService = Components.classes["@mozilla.org/consoleservice;1"].getService(Components.interfaces.nsIConsoleService);
	var errorListener = new CSSErrorListener()

	//make a fake document and apply the style to it. this will throw errors and give us a stylesheet document
	var doc = setUpDocument();
	//stylesheet loading is asynchronous
	consoleService.registerListener(errorListener);
	var loadedListener = new StylishStylesheetLoadedListener(doc, errorListener, endStylesheetLoad);
	//this actually loads the sheet
	doc.documentElement.appendChild(setUpLink(doc));
	//now start checking for completion
	loadedListener.checkStyleLoaded();
}

function setUpDocument() {
	return document.implementation.createDocument(stylishCommon.XULNS, "stylish-parse", null);
}

function setUpLink(doc) {
	var link = doc.createElementNS(stylishCommon.HTMLNS, "link");
	link.rel = "stylesheet";
	link.type = "text/css";
	link.href = stylishCommon.codePrefix + codeElement.value;
	return link;
}

function loadAppliesTo() {
	var doc = setUpDocument();
	var loadedListener = new StylishStylesheetLoadedListener(doc, null, endStylesheetLoadAppliesTo);
	doc.documentElement.appendChild(setUpLink(doc));
	loadedListener.checkStyleLoaded();
}

function endStylesheetLoadAppliesTo(success, data) {
	if (!success) {
		return;
	}
	style.calculateMetadata(data.stylesheet);
	var appliesTo = document.getElementById("applies-to");
	while (appliesTo.firstChild) {
		appliesTo.removeChild(appliesTo.firstChild);
	}
	var a = style.appliesToDisplayArray;
	for (var i = 0; i < a.length; i++) {
		var li = document.createElementNS(stylishCommon.HTMLNS, "li");
		li.appendChild(document.createTextNode(a[i]));
		appliesTo.appendChild(li);
	}
}

function cleanError(error) {
	try {
		return error.QueryInterface(Components.interfaces.nsIScriptError).errorMessage;
	} catch (ex) {
		//fall back on the long error
		return error.message;
	}
}

function endStylesheetLoad(success, data) {
	//did the stylesheet load fail?
	if (!success) {
		throw data.exception;
	}
	//did the stylesheet load succeed, but the stylesheet contains errors?
	if (data.errors.length > 0) {
		var errorString;
		for (var i = 0; i < data.errors.length; i++) {
			if (errorString) {
				errorString += "\n\n" + cleanError(data.errors[i]);
			} else {
				errorString = cleanError(data.errors[i]);
			}
		}
		var prompts = Components.classes["@mozilla.org/embedcomp/prompt-service;1"].getService(Components.interfaces.nsIPromptService);
		//should we continue, even with the errors?
		if (1 == prompts.confirmEx(window, STRINGS.getString("cssErrorDialogTitle"), STRINGS.getFormattedString("cssErrorText", [errorString]), prompts.BUTTON_POS_0 * prompts.BUTTON_TITLE_IS_STRING + prompts.BUTTON_POS_1 * prompts.BUTTON_TITLE_IS_STRING, STRINGS.getString("cssErrorAccept"), STRINGS.getString("cssErrorCancel"), null, null, {})) {
			return;
		}
	}
	if (previewOnly) {
		preview();
		return;
	}
	//proceed with the save

	style.calculateMetadata(data.stylesheet);
	//unapply the previewed code
	if (appliedCode) {
		stylishCommon.unregisterStyle(style.uri, appliedCode);
	}

	//ping the install site to increment the counter. we don't care about the response
	if (installPingURL) {
		//try {
			var req = new XMLHttpRequest();
			req.open("GET", installPingURL, true);
			req.send(null);
		//} catch (ex) {
		//	dump(ex);
		//}
	}

	stylishCommon.dispatchEvent(triggeringDocument, "styleInstalled");

	style.description = descriptionElement.value;
	style.code = codeElement.value;
	style.enabled = enabledElement.checked;
	style.neverUpdate = !neverUpdateElement.checked;;
	if (updateOriginalCode) {
		style.originalCode = initialCode;
	}
	if (updateURL) {
		style.updateURL = updateURL;
	}
	style.customized = !stylishCommon.cssAreEqual(initialCode, style.code);
	style.save();
	stylishCommon.reloadManage();
	keepStyleOnClose = true;
	close();

}

function dialogClosing() {
	//remove it from the file
	if (!keepStyleOnClose && newStyle) {
		StylishStyle.prototype.ds.deleteRecursive(style.node);
		StylishStyle.prototype.ds.save();
	}
}

function doPreview() {
	previewOnly = true;
	save();
}

function preview() {
	if (appliedCode) {
		//unregister previously previewed code
		stylishCommon.unregisterStyle(style.uri, appliedCode);
	} 
	appliedCode = codeElement.value;
	stylishCommon.registerStyle(style.uri, codeElement.value);
}

function save() {
	if (!validate()) {
		return false;
	}
	startLoadStylesheet();
	//cancel close. actually closing will be handled further down the chain
	return false;
}

function postStyle() {
	previewOnly = false;
	if (!validate()) {
		return false;
	}
	startLoadStylesheet();
	return true;
}

function ok() {
	previewOnly = false;
	return save();
}

//Process the return from the specify site dialog
function applySpecifySite(data) {
	if (data.length == 0) {
		return;
	}
	var selector = "";
	for (var i = 0; i < data.length; i++) {
		if (selector != "") {
			selector += ", ";
		}
		selector += data[i].type + "(" + data[i].site + ")";
	}
	selector = "@-moz-document " + selector + " {\n";
	if (codeElement.selectionStart != codeElement.selectionEnd) {
	//there's a selection, so let's cram the selection inside
	var selection = codeElement.value.substring(codeElement.selectionStart, codeElement.selectionEnd);
	var newValue = "";
	//if there's stuff before the selection, include whitespace
		if (codeElement.selectionStart > 0) {
			newValue = codeElement.value.substring(0, codeElement.selectionStart) + "\n";
		}
		newValue += selector;
		var newCaretPosition = newValue.length;
		newValue += selection + "\n}";
		//if there's stuff after the selection, include whitespace
		if (codeElement.selectionEnd < codeElement.value.length) {
			newValue += "\n" + codeElement.value.substring(codeElement.selectionEnd, codeElement.value.length);
		}
	} else {
		//there's no selection, just put it at the end
		//if there's stuff in the textbox, add some whitespace
		if (codeElement.value.length > 0) {
			var newValue = codeElement.value + "\n" + selector;
			var newCaretPosition = newValue.length;
			newValue += "\n}";
		} else {
			var newValue = selector;
			var newCaretPosition = newValue.length;
			newValue += "\n}";
		}
	}

	codeElement.value = newValue;
	codeElement.setSelectionRange(newCaretPosition, newCaretPosition);
	codeElement.focus();
}

function CSSErrorListener() {
	this.errors = [];
}
CSSErrorListener.prototype = {
	QueryInterface: function(aIID) {
		if (aIID.equals(Components.interfaces.nsIConsoleListener) ||
		    aIID.equals(Components.interfaces.nsISupports))
			return this;
		throw Components.results.NS_NOINTERFACE;
	},
	observe: function(message) {
		try {
			//make sure we generated this message
			if (message.QueryInterface(Components.interfaces.nsIScriptError).sourceName.indexOf(stylishCommon.codePrefix) == 0) {
				this.errors.push(message);
			}
		} catch (ex) {
			//a non nsIScriptError object. don't care about it.
		}
	}
}
