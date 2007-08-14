var stylesToUpdate = [];
var enumerator, progress, styleCount, style, list, strings;
var numberDone = 0;

function init() {
	list = document.getElementById("style-list");
	styleCount = StylishStyle.prototype.ds.getNode(StylishStyle.prototype.containerURI).getChildCount();
	enumerator = StylishStyle.prototype.ds.getNode(StylishStyle.prototype.containerURI).getChildren();
	progress = document.getElementById("progress");
	strings = document.getElementById("strings");
	checkNext();
}

function updateAll() {
	document.getElementById("update-all").setAttribute("disabled", "true")
	update(stylesToUpdate);
	stylesToUpdate = [];
	StylishStyle.prototype.ds.save();
}

function update(styles) {
	progress.style.display = "";
	for (var i = 0; i < styles.length; i++) {
		var originallyEnabled = styles[i].enabled;
		//if it's enabled, turn it off first
		if (originallyEnabled) {
				styles[i].enabled = false;
		}
		styles[i].code = styles[i].updatedCode;
		styles[i].originalCode = styles[i].updatedCode;
		styles[i].customized = false;
		if (originallyEnabled) {
			styles[i].enabled = true;
		}
		list.removeChild(document.getElementById(styles[i].uri));
		progress.setAttribute("value", (0.0 + i) / styles.length * 100 + "%");
	}
	progress.style.display = "none";
	progress.setAttribute("value", "0%");	
}

function neverUpdate(styles) {
	for (var i = 0; i < styles.length; i++) {
		styles[i].neverUpdate = true;
		list.removeChild(document.getElementById(styles[i].uri));
	}
}

function checkNext() {
	if (enumerator.hasMoreElements()) {
		style = new StylishStyle(enumerator.getNext());
		style.checkForUpdate(updateCheckDone);
	} else {
		progress.style.display = "none";
		progress.setAttribute("value", "0%");
		document.getElementById("style-list-tree").setAttribute("disabled", "false");
		if (stylesToUpdate.length > 0) {
			document.getElementById("update-all").setAttribute("disabled", "false");
		}
	}
}

function updateCheckDone(updatedCode) {
	if (updatedCode) {
		style.updatedCode = updatedCode;
		var item = document.createElementNS(stylishCommon.XULNS, "treeitem");
		item.setAttribute("id", style.uri);
		var row = document.createElementNS(stylishCommon.XULNS, "treerow");
		var uriCell = document.createElementNS(stylishCommon.XULNS, "treecell");
		uriCell.setAttribute("label", style.uri);
		var descriptionCell = document.createElementNS(stylishCommon.XULNS, "treecell");
		descriptionCell.setAttribute("label", style.description);
		var customizedCell = document.createElementNS(stylishCommon.XULNS, "treecell");
		customizedCell.setAttribute("label", style.customized ? strings.getString("yes") : strings.getString("no"));
		customizedCell.setAttribute("class", "customized-column");
		row.appendChild(uriCell);
		row.appendChild(descriptionCell);
		row.appendChild(customizedCell);
		item.appendChild(row);
		list.appendChild(item);
		stylesToUpdate.push(style);
	}
	numberDone++;
	progress.setAttribute("value", (0.0 + numberDone) / styleCount * 100 + "%");
	checkNext();
}

function updateSelected(never) {
	var indices = getSelectedIndices();
	var styles = [];
	for (var i = 0; i < indices.length; i++) {
		styles.push(stylesToUpdate[indices[i]]);
	}
	var stylesNotUpdated = [];
	for (var i = 0; i < stylesToUpdate.length; i++) {
		var found = false;
		for (var j = 0; j < indices.length; j++) {
			if (i == indices[j]) {
				found = true;
				break;
			}
		}
		if (!found) {
			stylesNotUpdated.push(stylesToUpdate[i]);
		}
	}
	if (never) {
		neverUpdate(styles);
	} else {
		update(styles);
	}
	stylesToUpdate = stylesNotUpdated;
	if (stylesToUpdate.length == 0) {
		document.getElementById("update-all").setAttribute("disabled", "true");
	}
	StylishStyle.prototype.ds.save();
}

function getSelectedIndices() {
	var indices = [];
	var rangeCount = list.parentNode.view.selection.getRangeCount();
	for (var i = 0; i < rangeCount; i++) {
		var start = {};
		var end = {};
		list.parentNode.view.selection.getRangeAt(i,start,end);
		for (var c = start.value; c <= end.value; c++) {
			indices.push(c);
		}
	}
	return indices;
}

function changeSelection() {
	document.getElementById("update-selected").setAttribute("disabled", getSelectedIndices().length == 0 ? "true" : "false");
	document.getElementById("never-update-selected").setAttribute("disabled", getSelectedIndices().length == 0 ? "true" : "false");
}
