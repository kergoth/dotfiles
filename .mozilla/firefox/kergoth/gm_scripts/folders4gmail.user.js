// ==UserScript==
// @name          Folders4Gmail
// @namespace     http://www.arend-von-reinersdorff.com/folders4gmail/
// @description   Organize your labels in a folder-like hierarchy.
// @include       http://mail.google.com/*
// @include       https://mail.google.com/*
// ==/UserScript==

/*
 * Version 1.1, June 2007
 * Written by Arend v. Reinersdorff, www.arend-von-reinersdorff.com
 * This script is Public Domain. You are welcome to use it in any way you like.
 */

//Time intverval between each parsing of the labels. In milliseconds.
var refreshTimeInSeconds = 100;
//Path seperator for the label hierarchy.
var seperatorString = "\\";
//size of the expander square in pixels including borders, must be an odd number >= 7 , <= 13
var boxSize = 13;
//always show labels with unread messages
var always_show_unread = true;

var expandedList;
var expanderSize = boxSize - 4;
if(-1 != navigator.userAgent.indexOf("MSIE")){
	boxSize += 2;
}


//refresh is set only once, in the frameset
if(1 == document.getElementsByTagName("frameset").length){
	expandedList = new Array();
	window.setInterval(refreshSublabels, refreshTimeInSeconds);
}


//check if the sublabels need to be recreated after a reload
function refreshSublabels(){
	if(!frames[0]){
		return;
	}
	for (var i = 0; i <= 3; i++){
		if(!frames[0].frames[i]){
			return;
		}

		var editNode = frames[0].frames[i].document.getElementById("prf_l");
		if((null != editNode) && (!editNode.title)){
			editNode.title = editNode.firstChild.data;
			parseLabels(editNode);
		}
	}
}


//create the hierarchy of sublabels by parsing the label names
function parseLabels(labelNode){
	var isParentLabel = new Array();

	while(null != (labelNode = labelNode.previousSibling)){

		//don't process anything but a correct pathname
		if(!isValidSublabel(labelNode)){
			continue;
		}

		//find the label's parent
		var expandParentLabels = false;
		var doc = labelNode.ownerDocument;
		var parentId = getParentId(labelNode.id, doc);
		if(null != parentId) {
			isParentLabel[parentId] = true;
		}

		//set label name
		var lastSeparator = labelNode.id.lastIndexOf(seperatorString);
		if(-1 == lastSeparator){
			lastSeparator = 2;
		}
		var textNode   = labelNode.firstChild;
		var labelName  = labelNode.id.substring((lastSeparator + 1), labelNode.id.length);
		var suffixText = "";

		//take care of new emails
		if("B" == labelNode.firstChild.nodeName.toUpperCase()){
			textNode = textNode.firstChild;
			suffixText = textNode.data.substr(textNode.data.lastIndexOf(" "));
			var parentIdRec = parentId;
			expandParentLabels = always_show_unread;
		}

		textNode.data = labelName + suffixText;

		//if in view for this label, expand parent labels
		if(null != doc.getElementById("ac_r" + labelNode.id.substr(1))){
			expandParentLabels = true;
			expandedList[labelNode.id] = true;
		}

		if(expandParentLabels){
			var parentIdRec = parentId;
			while(null != parentIdRec) {
				expandedList[parentIdRec] = true;
				parentIdRec = getParentId(parentIdRec, doc);
			}
		}

		//indention and expander
		var indentionLevel = getIndentionDepth(labelNode.id, doc);

		/*if(null != parentId){
			indentionLevel += getIndentionDepth(labelNode.id, doc);
		}*/
		labelNode.style.width = (16 - indentionLevel*1.6) + "ex";

		var indentedNode = labelNode;

		if(isParentLabel[labelNode.id]) {
			var expanderNode = getExpandSign(doc);
			indentedNode = expanderNode;

			labelNode.parentNode.insertBefore(expanderNode, labelNode);
			indentionLevel--;

			if(!expandedList[labelNode.id]){
				collapse(new function(){this.target = expanderNode;});
			}
		}
		indentedNode.style.marginLeft = "" + indentionLevel*boxSize + "px";
	}
}


//checks if a label node and its id have the proper format
function isValidSublabel(labelNode){
	return(
		(labelNode.id) &&
		(3 != labelNode.id.indexOf(seperatorString)) &&
		(labelNode.id.length-1 != labelNode.id.lastIndexOf(seperatorString)) &&
		(-1 == labelNode.id.indexOf(seperatorString + seperatorString)) &&
		("prf_l" != labelNode.id)
	);
}


//parses the parent id and checks if the parent label exists
function getParentId(labelId, doc){
	//return null if there is no parent label
	var lastSeparator = labelId.lastIndexOf(seperatorString);

	while(-1 != lastSeparator){
		labelId = labelId.substring(0, lastSeparator);
		if(null != doc.getElementById(labelId)) {
			 return labelId
		}
		lastSeparator = labelId.lastIndexOf(seperatorString);
	}

	return null;
}

//retrieves the number of parent folders for this labelId
function getIndentionDepth(labelId, doc){
	var countDepth = 1;
	var seperator = labelId.indexOf(seperatorString);

	while(-1 != seperator){
		if(null != doc.getElementById(labelId.substring(0, seperator))){
			countDepth++;
		}
		seperator = labelId.indexOf(seperatorString, seperator + 1);
	}

	return countDepth;
}


//create a new expand sign node
//doc parameter for Opera
function getExpandSign(doc){
	var expNode = doc.createElement("img");
	expNode.src = "http://www.google.com/ig/images/skins/teahouse/2pm/min_dark_blue.gif";
	expNode.style.cssFloat    = "left";
	expNode.style.styleFloat  = "left"; //float for Internet Explorer
	expNode.style.marginTop   = "2px";
	expNode.style.cursor      = "pointer";

	addEventListenerAll(expNode, "click", collapse);
	addEventListenerAll(expNode, "mouseover", highlightExpander);
	addEventListenerAll(expNode, "mouseout", unhighlightExpander);
	return expNode;
}

function highlightExpander(evt){
	var eventTarget = evt.target;
	if(!evt.target){
		eventTarget = evt.srcElement;

	}


	eventTarget.src = eventTarget.src.replace(/\.gif/, "_highlight.gif");
}

function unhighlightExpander(evt){
	var eventTarget = evt.target;
	if(!evt.target){
		eventTarget = evt.srcElement;
	}

	eventTarget.src = eventTarget.src.replace(/_highlight/, "");
}

//event for a click on a + expander
function expand(event){
	var expanderNode = event.target;
	//for Internet Explorer
	if(!event.target){
		expanderNode = event.srcElement;
	}

	var expandedLabelId = expanderNode.nextSibling.getAttribute("id");
	expandedList[expandedLabelId] = true;
	expanderNode.src = expanderNode.src.replace(/max/, "min");
	var labelNode = expanderNode.nextSibling;
	var displayList = new Array();
		displayList[expandedLabelId] = true;

	while(null != (labelNode = labelNode.nextSibling)){
		if(!isValidSublabel(labelNode)){
			continue;
		}

		if(0 != labelNode.id.indexOf(expandedLabelId + seperatorString)){
			break;
		}

		var parentId = getParentId(labelNode.id, labelNode.ownerDocument);
		if((displayList[parentId]) && (expandedList[parentId])){

			displayList[labelNode.id] = true;
			labelNode.style.display = "block";

			var labelNodeExpander = labelNode.previousSibling;
			if(!labelNodeExpander.id){
				labelNodeExpander.style.display = "block";
			}
		}
	}
	removeClickEvent(expanderNode, expand);
	addEventListenerAll(expanderNode, "click", collapse);
}


//click on a - expand sign
function collapse(event) {
	var expanderNode = event.target;
	//for Internet Explorer
	if(!event.target){
		expanderNode = event.srcElement;
	}

	var expandedLabelId = expanderNode.nextSibling.getAttribute("id");
	expandedList[expandedLabelId] = false;
	expanderNode.src = expanderNode.src.replace(/min/, "max");
	var labelNode = expanderNode.nextSibling;

	while(null != (labelNode = labelNode.nextSibling)){
		if(!isValidSublabel(labelNode)){
			continue;
		}

		if(0 != labelNode.id.indexOf(expandedLabelId + seperatorString)){
			break;
		}

		labelNode.style.display = "none";
		var labelNodeExpander = labelNode.previousSibling;
		if(!labelNodeExpander.id){
			labelNodeExpander.style.display = "none";
		}
	}
	removeClickEvent(expanderNode, collapse);
	addEventListenerAll(expanderNode, "click", expand);
}


//cross browser addEventListener
function addEventListenerAll(targetNode, eventName, action){
	//for Internet Explorer
	if(!targetNode.addEventListener)  {
		targetNode.attachEvent("on" + eventName, action);

	//for W3C DOM (Firefox, Opera)
	} else {
		targetNode.addEventListener(eventName, action, false);
	}
}


//cross browser removeEventListener
function removeClickEvent(targetNode, action){
	//for Internet Explorer
	if(!targetNode.removeEventListener)  {
		targetNode.detachEvent("onclick", action);

	//for W3C DOM (Firefox, Opera)
	} else {
		targetNode.removeEventListener("click", action, false);
	}
}

