var urlElement, STRINGS, siteListElement, addElement, typeElement, deleteElement, siteListTreeElement;

function init() {
	urlElement = document.getElementById("url");
	siteListElement = document.getElementById("site-list");
	addElement = document.getElementById("add");
	typeElement = document.getElementById("type");
	deleteElement = document.getElementById("delete");
	siteListTreeElement = document.getElementById("site-list-tree");
	STRINGS = document.getElementById("strings");

	urlElement.focus();
}

function addSpecifySiteEntry() {
	var typeGroup = typeElement.selectedItem;
	var url = urlElement.value;
	if (url.length == 0) {
		return;
	}
	switch (typeGroup.value) {
		case "url":
			//Make a URI. This will throw if it's not valid
			try {
				var ios = Components.classes["@mozilla.org/network/io-service;1"].getService(Components.interfaces.nsIIOService);
				var uri = ios.newURI(url, "UTF-8", null);
			} catch (ex) {
				try {
					//maybe someone forgot to put the protocol in. let's assume they meant http://
					var uri = ios.newURI("http://" + url, "UTF-8", null);
				} catch (ex) {
					//I have no idea.
					alert(STRINGS.getString("urlNotValid"));
					return;
				}
			}
			url = uri.spec;
			break;
		case "url-prefix":
			//not really any way to validate this other than making sure the protocol is there
			var position = url.indexOf("://");
			if (position == -1) {
				url = "http://" + url;
			}
			break;
		case "domain":
			//The user might have mistakenly included the protocol. Let's strip it.
			var position = url.indexOf("://");
			if (position > -1) {
				url = url.substring(position + 3, url.length);
			}
			break;
		default:
			alert("Unrecognized site entry type '" + typeGroup.value + "'");
			return;
	}
		
	//add it to the list
	var item = document.createElementNS(stylishCommon.XULNS, "treeitem");
	var row = document.createElementNS(stylishCommon.XULNS, "treerow");
	var typeCell = document.createElementNS(stylishCommon.XULNS, "treecell");
	typeCell.setAttribute("label", typeGroup.label);
	typeCell.setAttribute("value", typeGroup.value);
	var siteCell = document.createElementNS(stylishCommon.XULNS, "treecell");
	siteCell.setAttribute("label", url);
	row.appendChild(typeCell);
	row.appendChild(siteCell);
	item.appendChild(row);
	siteListElement.appendChild(item);

	urlElement.value = "";
	urlElement.focus();
	addElement.disabled = true;
}

function closeSpecifySite() {
	var data = [];
	for (var i = 0; i < siteListElement.childNodes.length; i++) {
		var currentRow = siteListElement.childNodes[i].firstChild;
		data[i] = {type: currentRow.firstChild.getAttribute("value"), site: currentRow.childNodes[1].getAttribute("label")};
	}
	window.arguments[0](data);
}

function urlKeyPress(aEvent) {
	if (aEvent.keyCode == 13) {
		addSpecifySiteEntry();
		aEvent.preventDefault();
	}
}

function urlInput() {
	addElement.disabled = !(urlElement.value);
}

function siteListKeyPress(aEvent) {
	//delete
	if (aEvent.keyCode == 46) {
		deleteSiteList();
	}
}

function deleteSiteList() {
	var itemsToRemove = getSelectedStyles();
	for (var i = 0; i < itemsToRemove.length; i++) {
		itemsToRemove[i].parentNode.removeChild(itemsToRemove[i]);
	}
}

function changeSelection() {
	deleteElement.disabled = (getSelectedStyles().length == 0);
}

function getSelectedStyles() {
	var selectedItems = [];
	var rangeCount = siteListTreeElement.view.selection.getRangeCount();
	for (var i = 0; i < rangeCount; i++) {
		var start = {};
		var end = {};
		siteListTreeElement.view.selection.getRangeAt(i,start,end);
		for (var c = start.value; c <= end.value; c++) {
			selectedItems[selectedItems.length] = siteListTreeElement.view.getItemAtIndex(c);
		}
	}
	return selectedItems;
}
