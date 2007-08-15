var stylishDomi = {
	generateSelectors: function(event) {
		var node = viewer.selectedNode;
		if (!(node instanceof Element)) {
			return;
		}
		var popup = event.target;

		//element selector
		stylishDomi.addSelectorMenuItem(popup, node.nodeName);
		//id selector
		if (node.hasAttribute("id")) {
			stylishDomi.addSelectorMenuItem(popup, "#" + node.getAttribute("id"));
		}
		//class selector
		if (node.hasAttribute("class")) {
			var classes = node.getAttribute("class").split(/\s+/);
			stylishDomi.addSelectorMenuItem(popup, "." + classes.join("."));
		}
		//attribute selectors. it's pointless to create a complicated attribute selector including an id or only a class
		if (node.attributes.length > 1 || (node.attributes.length == 1 && node.attributes[0].name != "id" && node.attributes[0].name != "class")) {
			var selector = node.nodeName;
			for (var i = 0; i < node.attributes.length; i++) {
				if (node.attributes[i].name != "id") {
					selector += "[" + node.attributes[i].name + "=\"" + node.attributes[i].value + "\"]";
				}
			}
			stylishDomi.addSelectorMenuItem(popup, selector);
		}
		//position selector - worthless if we have an id
		if (!node.hasAttribute("id")) {
			stylishDomi.addSelectorMenuItem(popup, stylishDomi.getPositionalSelector(node));
		}
	},

	addSelectorMenuItem: function(popup, selector) {
		var menuitem = document.createElementNS(stylishCommon.XULNS, "menuitem");
		menuitem.setAttribute("label", selector);
		menuitem.setAttribute("oncommand", "stylishDomi.copySelectorToClipboard(event)");
		popup.appendChild(menuitem);
	},

	getPositionalSelector: function(node) {
		if (node instanceof Document) {
			return "";
		}
		if (node.hasAttribute("id")) {
			return "#" + node.getAttribute("id");
		}
		//are we the only child of the parent with this node name?
		var uniqueChild = true;
		var nodeName = node.nodeName;
		for (var i = 0; i < node.parentNode.childNodes.length; i++) {
			var currentNode = node.parentNode.childNodes[i];
			//css ignores everything but elements
			if (!(currentNode instanceof Element)) {
				continue;
			}
			if (node != currentNode && node.nodeName == currentNode.nodeName) {
				uniqueChild = false;
				break;
			}
		}
		if (uniqueChild) {
			return stylishDomi.getParentPositionalSelector(node) + node.nodeName;
		}
		//are we the first child?
		if (stylishDomi.isCSSFirstChild(node)) {
			return stylishDomi.getParentPositionalSelector(node) + node.nodeName + ":first-child";
		}
		//are we the last child?
		if (stylishDomi.isCSSLastChild(node)) {
			return stylishDomi.getParentPositionalSelector(node) + node.nodeName + ":last-child";
		}
		//get our position among our siblings
		var selectorWithinSiblings = ""
		for (var i = 0; i < node.parentNode.childNodes.length; i++) {
			var currentNode = node.parentNode.childNodes[i];
			//css ignores everything but elements
			if (!(currentNode instanceof Element)) {
				continue;
			}
			if (currentNode == node) {
				selectorWithinSiblings += node.nodeName;
				break;
			}
			if (stylishDomi.isCSSFirstChild(currentNode)) {
				selectorWithinSiblings += currentNode.nodeName + ":first-child + ";
			} else {
				selectorWithinSiblings += currentNode.nodeName + " + ";
			}
		}
			return stylishDomi.getParentPositionalSelector(node) + selectorWithinSiblings;
	},

	isCSSFirstChild: function(node) {
		for (var i = 0; i < node.parentNode.childNodes.length; i++) {
			var currentNode = node.parentNode.childNodes[i];
			if (currentNode instanceof Element) {
				return currentNode == node;
			}
		}
		return false;
	},

	isCSSLastChild: function(node) {
		for (var i = node.parentNode.childNodes.length - 1; i >= 0 ; i--) {
			var currentNode = node.parentNode.childNodes[i];
			if (currentNode instanceof Element) {
				return currentNode == node;
			}
		}
		return false;
	},

	getParentPositionalSelector: function(node) {
		if (node.parentNode instanceof Document) {
			return "";
		}
		return stylishDomi.getPositionalSelector(node.parentNode) + " > ";
	},

	copySelectorToClipboard: function(event) {
		Components.classes["@mozilla.org/widget/clipboardhelper;1"].getService(Components.interfaces.nsIClipboardHelper).copyString(event.target.getAttribute("label"));
	}
}
