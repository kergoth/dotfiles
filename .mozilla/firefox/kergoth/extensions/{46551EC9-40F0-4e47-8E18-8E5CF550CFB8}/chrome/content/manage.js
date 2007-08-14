const FILE_VERSION = 5;
var table, tree, STRINGS, hideTree, updateElement;
var filterText = "";

function init() {
	STRINGS = document.getElementById("strings");
	//check for an upgrade
	var prefs = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefService);
	prefs = prefs.getBranch("extensions.stylish.");
	if (prefs.getIntPref("fileVersion") != FILE_VERSION) {
		openDialog("chrome://stylish/content/repair.xul", "stylishRepair", "chrome,dialog,modal,center,resizable=no", {});
		prefs.setIntPref("fileVersion", FILE_VERSION);
	}

	//apply sidebar-specific style?
	if (location.href.indexOf("sidebar=1") > -1) {
		var sidebarStyle = document.createProcessingInstruction("xml-stylesheet", "href=\"chrome://stylish/skin/sidebar.css\" type=\"text/css\"");
		document.insertBefore(sidebarStyle, document.documentElement);
	}

	//do we need to tell them about how the stylesheet service sucks?
	if (stylishCommon.hasSSSFix) {
		document.getElementById("manage-info").style.display = "none";
	}
	tree = document.getElementById("styles");
	hideTree = document.getElementById("hide-tree");
	updateElement = document.getElementById("update");
	loadTable();
}

function loadTable() {
	//if we're reloading, remember scroll position
	var topVisibleRow = null;
	if (table) {
		topVisibleRow = getTopVisibleRow();
	}
	table = [];
	var enumerator = StylishStyle.prototype.ds.getNode(StylishStyle.prototype.containerURI).getChildren();
	var atLeastOne = enumerator.hasMoreElements();
	while (enumerator.hasMoreElements()) {
		var node = enumerator.getNext();
		var style = new StylishStyle(node);
		if (filterText == "" || style.description.toLowerCase().indexOf(filterText) >= 0) {
			table.push(style);
		}
	}
	sort();
	if (topVisibleRow) {
		setTopVisibleRow(topVisibleRow);
	}
	hideTree.selectedIndex = atLeastOne ? 0 : 1;
	updateElement.disabled = !atLeastOne;
	changeSelection();
}

function treeView(table) {
	//table = table;
	this.rowCount = table.length;
	this.getCellText = function(row, col) {
		return table[row][col.id];
	};
	this.getCellValue = function(row, col) {
		return table[row][col.id];
	};
	this.setCellValue = function(row, col, value) {
		table[row].enabledString = value;
		StylishStyle.prototype.ds.save();
		loadTable();
	};
	this.setTree = function(treebox) {
		this.treebox = treebox;
	};
	this.isEditable = function(row, col) {
		return col.editable;
	};
	this.isContainer = function(row){ return false; };
	this.isSeparator = function(row){ return false; };
	this.isSorted = function(){ return false; };
	this.getLevel = function(row){ return 0; };
	this.getImageSrc = function(row,col){ return null; };
	this.getRowProperties = function(row,props){};
	this.getCellProperties = function(row,col,props){};
	this.getColumnProperties = function(colid,col,props){};
	this.cycleHeader = function(col, elem) {};
	this.performActionOnRow = function(action, row) {
		switch (action) {
			case "open":
				if (row == -1) {
					//if the user double-clicked a blank spot, they want to add
					openAdd();
				} else {
					stylishCommon.openEdit(table[row]);
				}
				break;
			default:
				alert("Unrecognized action " + action + " on row " + row + ".");
		}
	};
	this.performAction = function(action) {
		switch (action) {
			case "delete":
				var styles = getSelectedStyles();
				//make sure this is what they want to do
				var prompt, parms, title;
				if (styles.length == 1) {
					parms = [styles[0].description];
					title = STRINGS.getString("deleteStyleTitle")
					prompt = STRINGS.getFormattedString("deleteStyle", parms)
				} else {
					parms = [styles.length];
					title = STRINGS.getString("deleteStylesTitle")
					prompt = STRINGS.getFormattedString("deleteStyles", parms);
				}
				var prompts = Components.classes["@mozilla.org/embedcomp/prompt-service;1"].getService(Components.interfaces.nsIPromptService);
				if (prompts.confirmEx(window, title, prompt, prompts.BUTTON_POS_0 * prompts.BUTTON_TITLE_IS_STRING +
            prompts.BUTTON_POS_1 * prompts.BUTTON_TITLE_CANCEL, STRINGS.getString("deleteStyleOK"), null, null, null, {})) {
					return;
				}

				for (var i = 0; i < styles.length; i++) {
					//unapply the style if it's applied
					if (styles[i].enabled) {
						styles[i].unregister();
					}
					//delete it from the file
					StylishStyle.prototype.ds.deleteRecursive(styles[i].node);
				}
				StylishStyle.prototype.ds.save();
				loadTable();
				break;
			default:
				alert("Unrecognized action " + action + ".");
		}
	}
}

function sort(column) {
	var columnName;
	var order = tree.getAttribute("sortDirection") == "ascending" ? 1 : -1;
	//if the column is passed and it's already sorted by that column, reverse sort
	if (column) {
		columnName = column.id;
		if (tree.getAttribute("sortResource") == columnName) {
			order *= -1;
		}
	} else {
		columnName = tree.getAttribute("sortResource");
	}

	function columnSort(a, b) {
		if (prepareForComparison(a[columnName]) > prepareForComparison(b[columnName])) return 1 * order;
		if (prepareForComparison(a[columnName]) < prepareForComparison(b[columnName])) return -1 * order;
		//description ascending is the second level sort
		if (columnName != "description") {
			if (prepareForComparison(a["description"]) > prepareForComparison(b["description"])) return 1;
			if (prepareForComparison(a["description"]) < prepareForComparison(b["description"])) return -1;
		}
		return 0;
	}
	table.sort(columnSort);
	tree.setAttribute("sortDirection", order == 1 ? "ascending" : "descending");
	tree.setAttribute("sortResource", columnName);
	tree.view = new treeView(table);
	//set the appropriate attributes to show to indicator
	var cols = tree.getElementsByTagName("treecol");
	for (var i = 0; i < cols.length; i++) {
		cols[i].removeAttribute("sortDirection");
	}
	document.getElementById(columnName).setAttribute("sortDirection", order == 1 ? "ascending" : "descending");
}

function prepareForComparison(o) {
	if (typeof o == "string") {
		return o.toLowerCase();
	}
	return o;
}

function getSelectedIndices() {
	var indices = [];
	var rangeCount = tree.view.selection.getRangeCount();
	for (var i = 0; i < rangeCount; i++) {
		var start = {};
		var end = {};
		tree.view.selection.getRangeAt(i,start,end);
		for (var c = start.value; c <= end.value; c++) {
			indices.push(c);
		}
	}
	return indices;
}

//returns an array of the uris of the selected styles
function getSelectedStyles() {
	var indices = getSelectedIndices();
	var styles = [];
	for (var i = 0; i < indices.length; i++) {
		styles.push(table[indices[i]]);
	}
	return styles;
}

function getTopVisibleRow() {
	return tree.treeBoxObject.getFirstVisibleRow();
}

function setTopVisibleRow(topVisibleRow) {
	return tree.treeBoxObject.scrollToRow(topVisibleRow);
}

//open the add dialog
function openAdd() {
	//random window name will let us open as many as we want
	openDialog("chrome://stylish/content/edit.xul", stylishCommon.getRandomDialogName("stylishEdit"), stylishCommon.editDialogOptions);
}

function handleEditButtonClick() {
	tree.view.performActionOnRow("open", getSelectedIndices()[0]);
}

function handleDeleteButtonClick() {
	tree.view.performAction("delete");
}

function findUpdateButtonClick() {
	openDialog("chrome://stylish/content/update.xul", "stylishUpdate", "chrome,resizable,dialog=no,centerscreen");
}

function styleListKeyPress(aEvent) {
	//delete
	if (aEvent.keyCode == 46) {
		tree.view.performAction("delete");
	}
}

//Handles changes in selection for the manage dialog tree.
function changeSelection() {
	var edit = document.getElementById("edit");
	var deleteB = document.getElementById("delete");
	var selectedStyleCount = getSelectedStyles().length;
	switch (selectedStyleCount) {
		case 0:
			edit.disabled = true;
			deleteB.disabled = true;
			break;
		case 1:
			edit.disabled = false;
			deleteB.disabled = false;
			break;
		default:
			edit.disabled = true;
			deleteB.disabled = false;
			break;
	}
}

function handleStyleListDoubleClick(event) {
	var row = {}, col = {}, obj = {};
	tree.treeBoxObject.getCellAt(event.clientX, event.clientY, row, col, obj);
	tree.view.performActionOnRow("open", row.value);
}

function inputFilter(event) {
	var value = event.target.value.toLowerCase();
	setFilter(value);
	document.getElementById("clearFilter").disabled = value.length == 0;
}

function clearFilter() {
	document.getElementById("clearFilter").disabled = true;
	var filterElement = document.getElementById("filter");
	filterElement.focus();
	filterElement.value = "";
	setFilter("");
}

function setFilter(text) {
	filterText = text;
	loadTable();
}

var listObserver = {
  onDragStart: function (event, transferData, action) {
		var row = {}, col = {}, obj = {};
		tree.treeBoxObject.getCellAt(event.clientX, event.clientY, row, col, obj);
    transferData.data = new TransferData();
    transferData.data.addDataForFlavour("text/unicode", "chrome://stylish/content/edit.xul?uri=" + encodeURIComponent(table[row.value].uri));
  }
}
