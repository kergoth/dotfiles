var ds, container, styleCount, enumerator, progress, numberDone, style;
function init() {
	ds = StylishStyle.prototype.ds;
	container = ds.getNode(StylishStyle.prototype.containerURI);
	styleCount = container.getChildCount();
	enumerator = ds.getAllResources();
	progress = document.getElementById("progress");
	numberDone = 0;
	repairNext();
}

function repairNext() {
	if (!enumerator.hasMoreElements()) {
		ds.save();
		close();
		return;
	}
	var node = enumerator.getNext();
	if (node.source.Value == container.source.Value) {
		//it's the container, skip
		repairNext();
		return;
	}
	if (container.getChildIndex(node) == -1) {
		//it's not in the container, remove it;
		ds.deleteRecursive(node);
		//don't increment the number done, because we didn't count this one at the start since we looked at the container's children
		repairNext();
		return;		
	}
	style = new StylishStyle(node);
	if (!style.code) {
		//if there's no code, this is a screwed up entry and should be deleted
		ds.deleteRecursive(style.node);
		numberDone++;
		progress.setAttribute("value", (0.0 + numberDone) / styleCount * 100 + "%");
		repairNext();
		return;
	}
	//update the update url
	if (style.updateURL) {
		if (/http:\/\/userstyles.org\/style\/show\/[0-9]+\?raw/.test(style.updateURL)) {
			style.updateURL = style.updateURL.replace("/style/", "/styles/").replace("/show/", "/").replace("?raw", ".css");
			style.save();
		} else if (/http:\/\/userstyles.org\/style\/raw\/[0-9]+/.test(style.updateURL)) {
			style.updateURL = style.updateURL.replace("/style/", "/styles/").replace("/raw/", "/") + ".css";
			style.save();
		} else if (/http:\/\/userstyles.org\/styles\/raw\/[0-9]+/.test(style.updateURL)) {
			style.updateURL = style.updateURL.replace("/raw/", "/") + ".css";
			style.save();
		}
	}
	//update the id url
	if (/http:\/\/userstyles.org\/style\/show\/[0-9]+/.test(style.uri)) {
		var newStyle = new StylishStyle(style.uri.replace("/style/", "/styles/").replace("/show/", "/"));
		style.copy(newStyle);
		StylishStyle.prototype.ds.deleteRecursive(style.node);
		newStyle.save();
		repairNext();
		return;
	}
	check();
}

function check() {
	//make a fake document and apply the style to it. this will throw errors and give us a stylesheet document
	var doc = document.implementation.createDocument(stylishCommon.XULNS, "stylish-parse", null);
	var link = doc.createElementNS(stylishCommon.HTMLNS, "link");
	link.rel = "stylesheet";
	link.type = "text/css";
	link.href = stylishCommon.codePrefix + style.code;

	//stylesheet loading is asynchronous
	var loadedListener = new StylishStylesheetLoadedListener(doc, null, loaded);
	//this actually loads the sheet
	doc.documentElement.appendChild(link);
	//now start checking for completion
	loadedListener.checkStyleLoaded();
}

function loaded(success, data) {
	style.calculateMetadata(data.stylesheet);
	numberDone++;
	progress.setAttribute("value", (0.0 + numberDone) / styleCount * 100 + "%");
	repairNext();
}
