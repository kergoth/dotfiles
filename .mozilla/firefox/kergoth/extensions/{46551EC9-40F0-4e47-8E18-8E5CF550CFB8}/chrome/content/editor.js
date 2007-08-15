var colorChosen = false;
var rainbowPickerJustChanged = false;
const nsIFilePicker = Components.interfaces.nsIFilePicker;

//Insert the snippet at the start of the code textbox or highlight it if it's already in there
function insertCodeAtStart(snippet) {
	var position = codeElement.value.indexOf(snippet);
	if (position == -1) {
		//insert the code
		//put some line breaks in if there's already code there
		if (codeElement.value.length > 0) {
			codeElement.value = snippet + "\n" + codeElement.value;
		} else {
			codeElement.value = snippet + "\n";
		}
	}
	//highlight it
	codeElement.setSelectionRange(snippet.length + 1, snippet.length + 1);
	codeElement.focus();
}

function insertCodeAtCaret(snippet) {
	var selectionEnd = codeElement.selectionStart + snippet.length;
	codeElement.value = codeElement.value.substring(0, codeElement.selectionStart) + snippet + codeElement.value.substring(codeElement.selectionEnd, codeElement.value.length);
	codeElement.focus();
	codeElement.setSelectionRange(selectionEnd, selectionEnd);
}

function insertChromePath() {
	var ios = Components.classes["@mozilla.org/network/io-service;1"].getService(Components.interfaces.nsIIOService);
	var fileHandler = ios.getProtocolHandler("file").QueryInterface(Components.interfaces.nsIFileProtocolHandler);
	var chromePath = fileHandler.getURLSpecFromFile(Components.classes["@mozilla.org/file/directory_service;1"].getService(Components.interfaces.nsIProperties).get("UChrm", Components.interfaces.nsIFile));
	insertCodeAtCaret(chromePath);
}

function chooseColor(event) {
	colorChosen = true;
	var parent = event.target.parentNode;
	while (parent != null) {
		switch (parent.nodeName) {
			case "menupopup":
				parent.hidePopup();
				break;
			case "button":
				parent.open = false;
		}
		parent = parent.parentNode;
	}
	setTimeout(insertColor, 1);
}

function insertColor() {
	if (colorChosen) {
		insertCodeAtCaret(document.getElementById("normal-colorpicker").color);
		colorChosen = false;
	}
}

function insertRainbowPickerColor(event) {
	//rainbowpicker does it twice...
	if (rainbowPickerJustChanged) {
		return;
	}
	rainbowPickerJustChanged = true;
	setTimeout(function() {rainbowPickerJustChanged = false}, 100);
	insertCodeAtCaret(event.target.color);
}

function openSitesDialog() {
	openDialog("chrome://stylish/content/specifySites.xul", "stylishSpecifySites", "chrome,modal,resizable,centerscreen", this.applySpecifySite);
}

function changeWordWrap(on) {
	var prefs = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefService);
	prefs = prefs.getBranch("extensions.stylish.");
	prefs.setBoolPref("wrap_lines", on);
	refreshWordWrap(on);
}

function refreshWordWrap(on) {
	//bug 41464 (wrap doesn't work dynamically) workaround
	codeElement.style.display = "none";
	codeElement.setAttribute("wrap", on ? "on" : "off");
	setTimeout("document.getElementById('code').style.display = '';", 10);
}

function insertDataURI() {
	var fp = Components.classes["@mozilla.org/filepicker;1"].createInstance(nsIFilePicker);
	fp.init(window, STRINGS.getString("dataURIDialogTitle"), nsIFilePicker.modeOpen);
	if (fp.show() != nsIFilePicker.returnOK) {
		return;
	}
	var file = fp.file;
	var contentType = Components.classes["@mozilla.org/mime;1"].getService(Components.interfaces.nsIMIMEService).getTypeFromFile(file);
	var inputStream = Components.classes["@mozilla.org/network/file-input-stream;1"].createInstance(Components.interfaces.nsIFileInputStream);
	inputStream.init(file, 0x01, 0600, 0);
	var stream = Components.classes["@mozilla.org/binaryinputstream;1"].createInstance(Components.interfaces.nsIBinaryInputStream);
	stream.setInputStream(inputStream);
	var encoded = btoa(stream.readBytes(stream.available()));
	stream.close();
	inputStream.close();
	insertCodeAtCaret("data:" + contentType + ";base64," + encoded);
}

function makeImportant() {
	//preserve scroll position
	var box = codeElement.mInputField;
	var scroll = [box.scrollTop, box.scrollLeft];

	var code = codeElement.value;
	//change ;base64 to __base64__ so we don't match it on the ; when we split declarations
	code = code.replace(/;base64/g, "__base64__");
	var declarationBlocks = code.match(/\{[^\{\}]*[\}]/g);
	if (declarationBlocks == null) {
		return;
	}
	var declarations = [];
	declarationBlocks.forEach(function (declarationBlock) {
		declarations = declarations.concat(declarationBlock.split(/;/));
	});
	//make sure everything is really a declaration, and make sure it's not already !important
	declarations = declarations.filter(function (declaration) {
		return /[A-Za-z0-9-]+\s*:\s*[^};]+/.test(declaration) && !/!\s*important/.test(declaration);
	});
	//strip out any extra stuff like brackets and whitespace
	declarations = declarations.map(function (declaration) {
		return declaration.match(/[A-Za-z0-9-]+\s*:\s*[^};]+/)[0].replace(/\s+$/, "");
	});
	//replace them with "hashes" to avoid a problem with multiple identical name/value pairs
	var replacements = [];
	declarations.forEach(function (declaration) {
		var replacement = {hash: Math.random(), value: declaration};
		replacements.push(replacement);
		code = code.replace(replacement.value, replacement.hash);
	});
	replacements.forEach(function (replacement) {
		code = code.replace(replacement.hash, replacement.value + " !important");
	});
	//put ;base64 back
	code = code.replace(/__base64__/g, ";base64");
	codeElement.value = code;

	//restore scroll position
	box.scrollTop = scroll[0];
	box.scrollLeft = scroll[1];
}
