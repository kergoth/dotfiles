// ==UserScript==
// @name        Slashdot - comment tree
// @namespace   http://www.cs.uni-magdeburg.de/~vlaube/Projekte/GreaseMonkey/
// @description Allows you to collapse and expand comments
// @include     http://slashdot.org/*
// @include     http://*.slashdot.org/*
// ==/UserScript==

// This script was inspired by Matthew Gertners "Slashdot Live Comment Tree" script (http://www.allpeers.com/blog/?p=137)
// Updated 09 April 2006 for /. structure changes by Matthew Carroll (http://carroll.org.uk)

function addGlobalStyle(css) {
	var head, style;
	head = document.getElementsByTagName('head')[0];
	if (!head) { return; }
	style = document.createElement('style');
	style.type = 'text/css';
	style.innerHTML = css;
	head.appendChild(style);
}

function addClass(node, name) {
	node.className += " "+name;
}

function removeClass(node, name) {
	var regex = new RegExp("(.*)"+name+"(.*)");
	node.className = node.className.replace(regex, "$1$2");
}

function hasClass(node, name) {
	var regex = new RegExp(".*"+name+".*")
	return node.className.match(regex);
}

function collapseComment(titlenode) {
	// get all following siblings of titlenode and its parent
	var xpath = "following-sibling::* | parent::div[@class='commentTop']/parent::div/following-sibling::* | parent::div[@class='commentTop']/following-sibling::*";
	var results=document.evaluate(xpath,titlenode,null,XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE,null);
	for (var i=0; i<results.snapshotLength; i++) {
		var node = results.snapshotItem(i);
		addClass(node, "sct_collapsed");
	}
	addClass(titlenode, "sct_collapsedtitle");
}

function expandComment(titlenode) {
	// get all following siblings of titlenode and its parent
	var xpath = "following-sibling::* | parent::div[@class='commentTop']/parent::div/following-sibling::* | parent::div[@class='commentTop']/following-sibling::*";
	var results=document.evaluate(xpath,titlenode,null,XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE,null);
	for (var i=0; i<results.snapshotLength; i++) {
		var node = results.snapshotItem(i);
		removeClass(node,"sct_collapsed");
	}
	removeClass(titlenode, "sct_collapsedtitle");
}

function setCollapsedStyle(titlenode) {
	titlenode.firstChild.firstChild.nodeValue = "[+]";
}

function setExpandedStyle(titlenode) {
	titlenode.firstChild.firstChild.nodeValue = "[-]";
}

function toggleState(event) {
	var titlenode = event.target.parentNode;
	if(hasClass(titlenode, "sct_collapsedtitle")) {
		expandComment(titlenode);
		setExpandedStyle(titlenode);
	}
	else {
		collapseComment(titlenode);
		setCollapsedStyle(titlenode);
	}
}

function addIcon(titlenode) {
	var icon = document.createElement("div");
	var text = document.createTextNode("[-]");
	icon.className="sct_icon";
	icon.addEventListener("mousedown", toggleState, false);
	icon.appendChild(text);
	titlenode.insertBefore(icon, titlenode.firstChild);
}

addGlobalStyle("div.sct_icon { display:inline; cursor:pointer;}");
addGlobalStyle("div.sct_icon:hover { display:inline; color:white; }");
addGlobalStyle(".sct_collapsed { display:none; }");
addGlobalStyle(".sct_collapsedtitle { }");

var xpath="//li[@class='comment']/div/div[@class='commentTop']/div[@class='title']";
var results=document.evaluate(xpath,document,null,XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE,null);
for(var i=0; i<results.snapshotLength; i++) {
	addIcon(results.snapshotItem(i));
}
