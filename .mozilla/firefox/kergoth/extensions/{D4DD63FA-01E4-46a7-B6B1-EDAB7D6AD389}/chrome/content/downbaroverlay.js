/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Download Statusbar.
 *
 * The Initial Developer of the Original Code is
 * Devon Jensen.
 *
 * Portions created by the Initial Developer are Copyright (C) 2003
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s): Devon Jensen <velcrospud@hotmail.com>
 *
 * folder.png from Windows 2000 Icon Theme by asifalirizwaan - kde-look.org
 * download_manager.png from Crystal_SVG by everaldo - kde-look.org
 *
 * Uninstall observer code adapted from Ook? Video Ook! extension by tnarik
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */


var db_gDownloadManager;
//var db_queueNum;
var db_pref = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
var db_miniMode = false;
var db_useGradients = true;
var db_speedColorsEnabled = false;
var db_speedDivision1, db_speedDivision2, db_speedDivision3;
var db_speedColor0, db_speedColor1, db_speedColor2, db_speedColor3;
window.addEventListener("load", downbarInit, true);
window.addEventListener('unload', downbarClose, false);
window.addEventListener("focus", db_newWindowFocus, false);
window.addEventListener("blur", db_hideOnBlur, true);
var db_strings;
var db_currTooltipAnchor;

function downbarInit() {

	var downbarelem = document.getElementById("downbar");

	const db_dlmgrContractID = "@mozilla.org/download-manager;1";
	const db_dlmgrIID = Components.interfaces.nsIDownloadManager;
	db_gDownloadManager = Components.classes[db_dlmgrContractID].getService(db_dlmgrIID);

	var db_ds = db_gDownloadManager.datasource;
	downbarelem.database.AddDataSource(db_ds);

	// Load localized strings
	db_strings = document.getElementById("downbarbundle");

	db_readPrefs();
	db_checkMiniMode();  // checkMiniMode calls setStyles, setStyles calls checkShouldShow and startInProgress

	try {
		var firstRun = db_pref.getBoolPref("downbar.function.firstRun");
		var oldVersion = db_pref.getCharPref("downbar.function.version"); // needs to be last because it's likely not there (throws error)
	} catch (e) {}

	if (firstRun) {
		db_pref.setBoolPref("browser.download.manager.showWhenStarting", false);
		db_pref.setBoolPref("browser.download.manager.showAlertOnComplete", false);
		db_pref.setBoolPref("downbar.function.firstRun", false);

		// Give first runner time before the donate text shows up in the add-ons manager
		var now = ( new Date() ).getTime();
		db_pref.setCharPref("downbar.function.donateTextInterval", now);
		
		try {
			db_showSampleDownload();	
		} catch(e){}
		
		try {
			// Set "keep download history" pref
			// browser.download.manager.retention must be 2, set their downbar history pref, based on their previous setting
			var retenPref = db_pref.getIntPref('browser.download.manager.retention');
			if(retenPref == 2)  // "Remember what I've downloaded"
				db_pref.setBoolPref('downbar.function.keepHistory', true);
			else
				db_pref.setBoolPref('downbar.function.keepHistory', false);
			db_pref.setIntPref('browser.download.manager.retention', 2);  // must be 2
		} catch(e){}
		
	}

	// Show "About Dlsb" on first time this version is used - currversion 0.9.5
	// XXX need to add that donate text is shown again in addons mgr, set supressDonateText to false, Interval reset too

	var showAbout = false;
	if(oldVersion) {
		var oldVersionArray = oldVersion.split(".");
		if(oldVersionArray[0] < "0")
			showAbout = true;
		else if (oldVersionArray[0] == "0") {
			if(oldVersionArray[1] < "9")
				showAbout = true;
			else if(oldVersionArray[1] == "9") {
				if(oldVersionArray[2] < "5")
					showAbout = true;
			}
		}
	}
	else  // there was no pref set
		showAbout = true;

	if(showAbout) {
		
	    window.setTimeout(function(){
	    	// Open page in new tab
			var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService();
	    	var wmed = wm.QueryInterface(Components.interfaces.nsIWindowMediator);
	    
	    	var win = wmed.getMostRecentWindow("navigator:browser");
	    	
	    	var content = win.document.getElementById("content");
	    	content.selectedTab = content.addTab("chrome://downbar/content/aboutdownbar.xul");	
	    }, 2500);
		
		//window.open('chrome://downbar/content/aboutdownbar.xul', "downbar_about", 'chrome,dialog=no,resizable');
		db_pref.setCharPref("downbar.function.version", "0.9.5");
	}
	
	// Setup whether to use default partially transparent tooltips (windows) or opaque solid backed tooltips (linux, mac)
	try {
		var useOpTooltips = db_pref.getBoolPref("downbar.function.useTooltipOpacity"); // Null on first install
	} catch (e) {}
	if(useOpTooltips == null) {
		// xxx this should probably go with the "first run" stuff in the future
		var os = Components.classes["@mozilla.org/xre/app-info;1"].getService(Components.interfaces.nsIXULRuntime).OS;
		if(os != "WINNT") {
			db_pref.setBoolPref("downbar.function.useTooltipOpacity", false);
			useOpTooltips = false;
		}
		else {
			db_pref.setBoolPref("downbar.function.useTooltipOpacity", true);
			useOpTooltips = true;
		}
			
	}
	
	// Because tooltip background transparency cannot be set on the fly, 
	//   (not sure why this is, seems like the background is cached or 
	//    set permanently to opaque if is not explicitly transparent at startup)
	// There are two tooltips each for "finshed" downloads and "progress" downloads. 
	// We decide which to use, then move the tooltip content from a temporary tooltip
	// onto the one we want.
	// Right now, tooltip background transparency is crashing linux (June 2007)
	
	if(useOpTooltips == true) {
		
		var finTooltipContent = document.getElementById("db_finTooltipContent");
		var fintip_tr = document.getElementById("fintip_transparent");
		fintip_tr.removeChild(fintip_tr.firstChild);
		fintip_tr.appendChild(finTooltipContent);
		fintip_tr.setAttribute("id", "fintip");
		
		var progTooltipContent = document.getElementById("db_progTooltipContent");
		var progtip_tr = document.getElementById("progresstip_transparent");
		progtip_tr.removeChild(progtip_tr.firstChild);
		progtip_tr.appendChild(progTooltipContent);
		progtip_tr.setAttribute("id", "progresstip");
		
	}
	else {
		var finTooltipContent = document.getElementById("db_finTooltipContent");
		var fintip_op = document.getElementById("fintip_opaque");
		fintip_op.removeChild(fintip_op.firstChild);
		fintip_op.appendChild(finTooltipContent);
		fintip_op.setAttribute("id", "fintip");
		
		var progTooltipContent = document.getElementById("db_progTooltipContent");
		var progtip_op = document.getElementById("progresstip_opaque");
		progtip_op.removeChild(progtip_op.firstChild);
		progtip_op.appendChild(progTooltipContent);
		progtip_op.setAttribute("id", "progresstip");
		
		// Set the proper background images for opaque tooltips, (default is for transparent)
		document.getElementById("finTipLeftImg").setAttribute("style", "list-style-image: url('chrome://downbar/skin/leftTooltip_white_square.png');");
		document.getElementById("finTipRightImg").setAttribute("style", "list-style-image: url('chrome://downbar/skin/rightTooltip_white_square.png');");
		document.getElementById("finTipMiddle").setAttribute("style", "background-image: url('chrome://downbar/skin/middleTooltip_white_160.png');");
		document.getElementById("progTipLeftImg").setAttribute("style", "list-style-image: url('chrome://downbar/skin/leftTooltip_white_square.png');");
		document.getElementById("progTipRightImg").setAttribute("style", "list-style-image: url('chrome://downbar/skin/rightTooltip_white_square.png');");
		document.getElementById("progTipMiddle").setAttribute("style", "background-image: url('chrome://downbar/skin/middleTooltip_white_160.png');");
		document.getElementById("db_tipImgPreviewBox").setAttribute("style", "background-image: url('chrome://downbar/skin/middleTooltip_white_160.png');");
		
	}
		
	// The default hide key is CTRL+SHIFT+z  Doing it this way should allow the user to change it with the downbar pref, or with the keyconfig extension
	try {
		var hideKey = db_pref.getCharPref("downbar.function.hideKey");
		if(hideKey != "z")
			document.getElementById("key_togDownbar").setAttribute("key", db_pref.getCharPref("downbar.function.hideKey"));
	} catch(e) {}

	// Developer features to be disabled
	//toJavaScriptConsole();
	//BrowserOpenExtensions('extensions');
	//document.getElementById("menu_FilePopup").parentNode.setAttribute("onclick", "if(event.button == 1) goQuitApplication();");

	window.removeEventListener("load", downbarInit, true);
}

function downbarClose() {

	// Leaving this feature in the browser window code rather than the downbar xpcom component because then I don't have to parse through all of downloads.rdf looking for DownbarShow=1
	var windowCount = 0;
	var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"]
	                  .getService(Components.interfaces.nsIWindowMediator);
	                  
	// Make sure download statusbar popups up somewhere...
	var recentBrowser = wm.getMostRecentWindow("navigator:browser");
	if(recentBrowser)
		recentBrowser.db_newWindowFocus();
	                  
	var e = wm.getEnumerator("navigator:browser");
	while (e.hasMoreElements()) {
		var w = e.getNext();
		if (++windowCount == 2)
		  break;
	}

	if(windowCount == 0) {
		var clearOnClose = db_pref.getBoolPref("downbar.function.clearOnClose");
		if(clearOnClose) {
			db_clearAll();
		}
	}
}

function db_newWindowFocus() {

	db_checkShouldShow();
	db_updateMini();

	if (db_miniMode)
		window.document.getElementById("downbarMini").collapsed = false;
	else
		window.document.getElementById("downbarHolder").collapsed = false;

}

// When a new window is opened, wait, then test if it is a browser window.  If so, collapse the downbar in the old window.  (It won't get updated anyway)
function db_hideOnBlur() {
	window.setTimeout("db_blurWait()", 100);
}

function db_blurWait() {
	var ww = Components.classes["@mozilla.org/embedcomp/window-watcher;1"].getService(Components.interfaces.nsIWindowWatcher);

	if (window != ww.activeWindow) {
		var wintype = ww.activeWindow.document.documentElement.getAttribute('windowtype');
		if (wintype == "navigator:browser") {
			if (db_miniMode)
				window.document.getElementById("downbarMini").collapsed = true;
			else
				window.document.getElementById("downbarHolder").collapsed = true;
		}
	}
}
/*
// if there are more downloads than the queue allows, return false
function db_checkQueue() {
	var currDLs = db_gDownloadManager.activeDownloadCount;
	//d(currDLs);
	//d(db_queueNum);
	if (currDLs > db_queueNum)
		return false;
	else
		return true;
}*/

// This function waits until there is a valid element created for a download before it sends it off to the update repeat function
// (There is a variable lag between the download start notification and element creation
function db_startUpdateDLrepeat(dlElemID) {

	var progElem = document.getElementById(dlElemID);
	if(progElem) {
		db_updateProgressNow();
		db_updateDLrepeat(dlElemID);
		db_checkShouldShow();
	}
	else {  // the element is not yet available - try again in 100ms
		window.setTimeout(function(){db_startUpdateDLrepeat(dlElemID);}, 20);
	}
}

// Update inprogress downloads every sec, calls a timeout to itself at the end
function db_updateDLrepeat(progElemID) {
	var progElem = document.getElementById(progElemID);
	try {
		var testContext = progElem.getAttribute("context");  // just see if it's a valid element
	} catch(e) {return;}

	if(testContext == "progresscontext" | testContext == "pausecontext") {  // now see if it's an in progress element

		db_calcAndSetProgress(progElemID);
		progElem.pTimeout = window.setTimeout(function(){db_updateDLrepeat(progElemID);}, 1000);
	}
}

function db_calcAndSetProgress(progElemID) {

	var progElem = document.getElementById(progElemID);
	var aDownload = db_gDownloadManager.getDownload(progElemID).QueryInterface(Components.interfaces.nsIDownload_MOZILLA_1_8_BRANCH);

	var newsize = aDownload.amountTransferred;
	var totalsize = aDownload.size;
	progElem.pTotalKBytes = totalsize;
	var oldsize = progElem.pOldSavedKBytes;
	if (!oldsize) oldsize = 0;

	// If download stops, Download manager will incorrectly tell us the last positive speed, this fixes that - speed can go to zero
	// Count up to 3 intervals of no progress and only set speed to zero if we hit that

	var newrate = aDownload.speed  / 1024;
	var noProgressIntervals = progElem.noProgressIntervals;
	if(!noProgressIntervals)
		noProgressIntervals = 0;

	if(newsize - oldsize > 0) {
		progElem.noProgressIntervals = 0;
	}
	else {
		// There was no progress
		noProgressIntervals++;
		progElem.noProgressIntervals = noProgressIntervals;
		if(noProgressIntervals > 3) {
			newrate = 0;
		}
	}
	// Firefox download manager doesn't set the speed to zero when the download is paused
	if(progElem.getAttribute("context") == "pausecontext")
		newrate = 0;
	
	progElem.pOldSavedKBytes = newsize;

	// Fix and set the size downloaded so far
	var currkb = parseInt(newsize / 1024); // KBytes
	if(newsize > 1024)
		var currSize = db_convertToMB(newsize) + " " + db_strings.getString("MegaBytesAbbr");
	else
		var currSize = newsize + " " + db_strings.getString("KiloBytesAbbr");
	progElem.lastChild.lastChild.lastChild.previousSibling.value = currSize;

	// Fix and set the speed
	var fraction = parseInt( ( newrate - ( newrate = parseInt( newrate ) ) ) * 10);
	var newrate = newrate + "." + fraction;
	progElem.lastChild.lastChild.firstChild.nextSibling.value = newrate;
	newrate = parseFloat(newrate);

	// If the mode is undetermined, just count up the MB
	// Firefox bug - totalsize should be -1 when the filesize is unknown, but here they are giving us the wraparound value 2^54
	if (totalsize == "18014398509481984" | parseInt(newsize) > parseInt(totalsize) ) {

		var db_unkAbbr = db_strings.getString("unknownAbbreviation");  // "Unk." in english

		// Percent and remaining time will be unknown
		progElem.lastChild.lastChild.firstChild.value = db_unkAbbr;
		progElem.lastChild.lastChild.lastChild.value = db_unkAbbr;

	}
	else {
		// Get and set percent
		var currpercent = aDownload.percentComplete;
		var newWidth = parseInt(currpercent/100 *  progElem.boxObject.width);
		progElem.firstChild.firstChild.minWidth = newWidth;
		progElem.lastChild.lastChild.firstChild.setAttribute("value", (currpercent + "%"));

		// Calculate and set the remaining time
		var remainingkb = parseInt(totalsize - newsize);
		if(newrate != 0) {
			var secsleft = (1 / newrate) * remainingkb;
			var remaintime = db_formatSeconds(secsleft);
			progElem.lastChild.lastChild.lastChild.value = remaintime;
		}
		else {
			var db_unkAbbr = db_strings.getString("unknownAbbreviation");  // "Unk." in english
			progElem.lastChild.lastChild.lastChild.value = db_unkAbbr;
		}
	}
	// Speed sensitive color
	if(db_speedColorsEnabled) {
		// Incremental
		var newcolor = db_speedColor0;
		if(newrate > db_speedDivision3)
			newcolor = db_speedColor3;
		else if (newrate > db_speedDivision2)
			newcolor = db_speedColor2;
		else if (newrate > db_speedDivision1)
			newcolor = db_speedColor1;

		if(db_useGradients)
			progElem.firstChild.firstChild.setAttribute("style", "background-color:" + newcolor + ";background-image:url(chrome://downbar/skin/whiteToTransGrad.png);border-right:0px solid transparent");
		else
			progElem.firstChild.firstChild.setAttribute("style", "background-color:" + newcolor + ";background-image:url();border-right:0px solid transparent");

		/*// Continuously Variable
		var baseRed = 0;
		var baseGreen = 0;
		var baseBlue = 254;
		var finalRed = 90;
		var finalGreen = 90;
		var finalBlue = 255;

		var maxSpeed = 700;
		var conversionRed = maxSpeed / (finalRed - baseRed);
		var conversionGreen = maxSpeed / (finalGreen - baseGreen);
		var conversionBlue = maxSpeed / (finalBlue - baseBlue);
		d("convR " + conversionRed);
		d("convG " + conversionGreen);
		d("convB " + conversionBlue);
		var newRed = parseInt(baseRed + newrate / conversionRed);
		var newGreen = parseInt(baseGreen + newrate / conversionGreen);
		var newBlue = parseInt(baseBlue + newrate / conversionBlue);
		if(newRed > 255)
			newRed = 255;
		if(newGreen > 255)
			newGreen = 255;
		if(newBlue > 255)
			newBlue = 255;

		d("newGreen: " + newGreen + "   " + "newRed: " + newRed);
		progElem.firstChild.firstChild.setAttribute("style", "background-color:rgb("+ newRed + "," + newGreen + "," + newBlue + ");");
	*/
	}
}

// The clicked-on node could be a child of the actual download element we want
// The child nodes won't have an id
function db_findDLNode(popupNode) {
	while(!popupNode.id) {
		popupNode = popupNode.parentNode;
	}
	return(popupNode.id);
}

function db_startOpenFinished(idtoopen) {

	if(db_useAnimation) {
		document.getElementById(idtoopen).firstChild.firstChild.src = "chrome://downbar/skin/greenArrow16.png";
		document.getElementById(idtoopen).firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.id = "slidePic";
		document.getElementById(idtoopen).firstChild.lastChild.firstChild.nextSibling.lastChild.flex = "0";

		// Do shift to right, after right is done, it calls shift from left
		db_openFinishedContRight(idtoopen, 16);
		window.setTimeout(function(){db_finishOpen(idtoopen);}, 150);
	}
	else {
		db_finishOpen(idtoopen);
	}
}

function db_openFinishedContRight(idtoopen, currshift) {

	if(currshift < 0) {
		document.getElementById(idtoopen).firstChild.lastChild.firstChild.nextSibling.lastChild.flex = "1";
		document.getElementById(idtoopen).firstChild.lastChild.firstChild.nextSibling.firstChild.flex = "0";
		db_openFinishedContLeft(idtoopen, 16)
	}
	else {
		var styleAttr = "list-style-image:url('moz-icon:" + idtoopen + "');-moz-image-region:rect(0px " + currshift + "px 16px 0px);";
		document.getElementById("slidePic").setAttribute("style", styleAttr);
		window.setTimeout(function(){db_openFinishedContRight(idtoopen, currshift-2);}, 10);
	}
}

function db_openFinishedContLeft(idtoopen, currshift) {

	if(currshift < 0) {
		//d("exiting");
		//db_finishOpen(idtoopen);
		document.getElementById(idtoopen).firstChild.firstChild.src = "moz-icon:" + idtoopen;
		document.getElementById(idtoopen).firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.id = "";
		document.getElementById(idtoopen).firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.setAttribute("style", "");
		document.getElementById(idtoopen).firstChild.lastChild.firstChild.nextSibling.firstChild.flex = "1";
	}
	else {
		var styleAttr = "list-style-image:url('moz-icon:" + idtoopen + "');-moz-image-region:rect(0px 16px 16px " + currshift + "px);";
		document.getElementById("slidePic").setAttribute("style", styleAttr);
		window.setTimeout(function(){db_openFinishedContLeft(idtoopen, currshift-2);}, 10);
	}
}

function db_finishOpen(idtoopen) {

	var file = db_getLocalFileFromNativePathOrUrl(idtoopen);
	if(!file.exists()) {
		var browserStrings = document.getElementById("bundle_browser");
		document.getElementById("statusbar-display").label = db_strings.getString("fileNotFound");
    	window.setTimeout(function(){document.getElementById("statusbar-display").label = browserStrings.getString("nv_done");}, 3000);
		return;
	}

	try {
    	file.launch();
    } catch (ex) {
    	// if launch fails, try sending it through the system's external
    	// file: URL handler
    	db_openExternal(file);
    }

	try {
		var removeOnOpen = db_pref.getBoolPref("downbar.function.removeOnOpen");
		if (removeOnOpen) {
			db_animateDecide(idtoopen, "clear", {shiftKey:false});
		}
	} catch (e) {}

}

function db_startShowFile(idtoshow) {

	if(db_useAnimation) {
		document.getElementById(idtoshow).firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.id = "picToShrink";
		document.getElementById("picToShrink").src = "moz-icon:" + idtoshow;
		document.getElementById(idtoshow).firstChild.firstChild.src = "chrome://downbar/skin/folder.png";
		document.getElementById("picToShrink").style.MozOpacity = .5;
		db_showAnimateCont(idtoshow, 16);
		window.setTimeout(function(){db_finishShow(idtoshow);}, 50);
	}
	else {
		db_finishShow(idtoshow);
	}
}

function db_showAnimateCont(idtoshow, newsize) {

	if(newsize < 8) {

		// put the icon back how it's supposed to be after 1 sec.
		window.setTimeout(function(){	try{
											document.getElementById("picToShrink").src = "";
											document.getElementById("picToShrink").setAttribute("style", "height:16px;width:16px;");
											document.getElementById(idtoshow).firstChild.firstChild.src = "moz-icon:" + idtoshow;
											document.getElementById("picToShrink").id = "";
										} catch(e){}
									}, 1000);
	}
	else {
		document.getElementById("picToShrink").setAttribute("style", "height:" + newsize + "px;width:" + newsize + "px;");
		window.setTimeout(function(){db_showAnimateCont(idtoshow, newsize-2);}, 25);
	}
}

function db_finishShow(idtoshow) {

	var file = db_getLocalFileFromNativePathOrUrl(idtoshow);
	try {
		file.reveal();
	} catch(e) {
		var parent = file.parent;
      if (parent) {
        db_openExternal(parent);
      }
	}

	try {
		var removeOnShow = db_pref.getBoolPref("downbar.function.removeOnShow");
		if (removeOnShow) {
			db_animateDecide(idtoshow, "clear", {shiftKey:false});
		}
	} catch (e) {}
}

function db_pause(elemid, aEvent) {
	try {
		if (aEvent.button == 2)	return;
	}
	catch (e) {}
	db_gDownloadManager.pauseDownload(elemid);
	// Update display now so there is no lag time without good values
	db_calcAndSetProgress(elemid);
}

function db_resume(elemid, aEvent) {
	try {
		if (aEvent.button == 2)	return;
	}
	catch (e) {}

	db_gDownloadManager.resumeDownload(elemid);
	// Update display now so there is no lag time without good values
	db_calcAndSetProgress(elemid);
}

// This is needed to do timeouts in multiple browser windows from the downbar.js component, (enumerating each window and calling timeout doesn't work)
function db_startAutoClear(elmpath, timeout) {

	window.setTimeout(function(){db_animateDecide(elmpath, "clear", {shiftKey:false});}, timeout)

}

function db_animateDecide(elemid, doWhenDone, event) {

	if(db_useAnimation && !event.shiftKey) {
		if(db_miniMode)
			db_clearAnimate(elemid, 1, 20, "height", doWhenDone);
		else
			db_clearAnimate(elemid, 1, 125, "width", doWhenDone);
	}

   	else {
   		if(doWhenDone == "clear")
   			db_clearOne(elemid);
   		//else if(doWhenDone == "remove")
   		//	db_removeit(elemid);
   		else
   			db_startDelete(elemid, event);
   	}
}

function db_clearAnimate(idtoanimate, curropacity, currsize, heightOrWidth, doWhenDone) {

	if(curropacity < .05) {
		if(doWhenDone == "clear")
			db_clearOne(idtoanimate);
		else
			db_finishDelete(idtoanimate);
		return;
	}
	document.getElementById(idtoanimate).style.MozOpacity = curropacity-.04;
	if(heightOrWidth == "width") {
		document.getElementById(idtoanimate).maxWidth = currsize-5.2;
		window.setTimeout(function(){db_clearAnimate(idtoanimate, curropacity-.04, currsize-5.2, "width", doWhenDone);}, 10);
	}
	else {
		document.getElementById(idtoanimate).maxHeight = currsize-0.8;
		window.setTimeout(function(){db_clearAnimate(idtoanimate, curropacity-.04, currsize-0.8, "height", doWhenDone);}, 10);
	}

}

function db_clearOne(idtoclear) {

	try {
		var keepHist = db_pref.getBoolPref('downbar.function.keepHistory');
		if(keepHist) {
			var rdf = Components.classes["@mozilla.org/rdf/rdf-service;1"].getService(Components.interfaces.nsIRDFService);
			var intNode = rdf.GetIntLiteral(0);
			db_setRDFProperty(idtoclear, "DownbarShow", intNode);
		}
		else {
			db_gDownloadManager.removeDownload(idtoclear);
		}
	} catch(e){}
	db_checkShouldShow();
	window.setTimeout("db_updateMini()", 444);
}

function db_clearAll() {
	
	var keepHist = db_pref.getBoolPref('downbar.function.keepHistory');
	var downbarelem = document.getElementById("downbar");
	var comparray = downbarelem.getElementsByAttribute("context", "donecontext"); // just using context as an indicator of that type of element
	var rdf = Components.classes["@mozilla.org/rdf/rdf-service;1"].getService(Components.interfaces.nsIRDFService);
	var intNode = rdf.GetIntLiteral(0);
	for (i = 1; i <= comparray.length - 1; i) {
		try {
			if(keepHist) {
       			db_setRDFProperty(comparray[i].id, "DownbarShow", intNode);
			}
			else {
				db_gDownloadManager.removeDownload(comparray[i].id);
			}
       	} catch (e) {}
    }
	window.setTimeout("db_checkShouldShow()", 50);
	window.setTimeout("db_updateMini()", 444);
}

function db_startDelete(elemtodelete, event) {

	try {
		var askOnDelete = db_pref.getBoolPref("downbar.function.askOnDelete");
	} catch (e) {}
	if (askOnDelete) {
		var db_confirmMsg = db_strings.getString("deleteConfirm");
		if (!confirm(db_confirmMsg))
			return;
	}

	if(db_useAnimation && !event.shiftKey) {
		document.getElementById(elemtodelete).firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.src = "chrome://downbar/skin/delete1.png";
		window.setTimeout(function(){db_deleteAnimateCont(elemtodelete);}, 150);
	}
	else
		db_finishDelete(elemtodelete);

}

function db_deleteAnimateCont(elemtodelete) {

	document.getElementById(elemtodelete).firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.src = "chrome://downbar/skin/delete2.png";

	if(db_miniMode)
		db_clearAnimate(elemtodelete, 1, 20, "height", "delete");
	else
		db_clearAnimate(elemtodelete, 1, 125, "width", "delete");
}

function db_finishDelete(elemtodelete) {

	var file = db_getLocalFileFromNativePathOrUrl(elemtodelete);
	db_clearOne(elemtodelete);

	if (file.exists())
		file.remove(false); // false is the recursive setting
}

function db_cancelprogress(elemtocancel) {

	var dbelems = document.getElementById("downbar").childNodes;
	db_gDownloadManager.cancelDownload(elemtocancel);
	db_checkShouldShow();
	db_clearOne(elemtocancel);
	db_updateProgressNow();

	var localFile = db_getLocalFileFromNativePathOrUrl(elemtocancel);
	if (localFile.exists())
		localFile.remove(false);
}

function db_cancelAll() {

	var dbelems = document.getElementById("downbar").childNodes;
	var cancPos = new Array(); // hold the child id of elements that are canceled, so that they can be removed in the 2nd for loop
	var posCount = 1;
	var contextAttr;
	for (var i = 1; i <= dbelems.length - 1; ++i) {
			contextAttr = dbelems[i].getAttribute("context");
			if (contextAttr == "progresscontext" | contextAttr == "pausecontext") {  // just using context as an indicator of that type of element
				db_gDownloadManager.cancelDownload(dbelems[i].id);
				cancPos[posCount] = dbelems[i].id;
				++posCount;
			}
	}

	var localFile;
	// Need to clear them after the first for loop is complete
	for (var j = 1; j < posCount; ++j) {
		db_clearOne(cancPos[j]);
		localFile = db_getLocalFileFromNativePathOrUrl(cancPos[j]);
		if (localFile.exists())
			localFile.remove(false);
	}
	db_checkShouldShow();
}

function db_pauseAll() {
	var dbelems = document.getElementById("downbar").childNodes;
	var i = 1;
	// I don't know why a for loop won't work here but okay
	while (i < dbelems.length) {

		if (dbelems[i].getAttribute("context") == "progresscontext") { // just using context as an indicator of that type of element
			db_pause(dbelems[i].id, null);
		}
		i = i + 1;
	}
}

function db_resumeAll() {
	var dbelems = document.getElementById("downbar").childNodes;
	var i = 1;
	while (i < dbelems.length) {
		if (dbelems[i].getAttribute("context") == "pausecontext") {  // just using context as an indicator of that type of element
			db_resume(dbelems[i].id, null);
		}
		i = i + 1;
	}
}

function db_stopAll() {

	var dbelems = document.getElementById("downbar").childNodes;
	for (i = 1; i <= dbelems.length - 1; ++i) {
		if (dbelems[i].getAttribute("context") == "progresscontext") {  // just using context as an indicator of that type of element
			db_gDownloadManager.cancelDownload(dbelems[i].id);
		}
	}
}

function db_copyURL(elemtocopy) {

	const gClipboardHelper = Components.classes["@mozilla.org/widget/clipboardhelper;1"]
														.getService(Components.interfaces.nsIClipboardHelper);
	gClipboardHelper.copyString(db_getRDFProperty(elemtocopy, "URL"));
}

function db_startit(elemid) {

	// This is how the new download manager does it, but it never resumes
	var src = db_getRDFProperty(elemid, "URL");
    var f = db_getLocalFileFromNativePathOrUrl(elemid);

    saveURL(src, f, null, true, true);

	/* This is how I used to do it - which magically resumes... sometimes
	var aElem = document.getElementById(elemid);
	var sourcepath = aElem.getAttribute("sourcepath");
	var aFilename = aElem.firstChild.value;
	var browser = top.document.getElementById("content");
  	browser.loadURI(sourcepath, getReferrer(document));
  	*/
}

function db_stopit(elemtostop) {
	db_gDownloadManager.cancelDownload(elemtostop);
	var f = db_getLocalFileFromNativePathOrUrl(elemtostop);
	if (f.exists())
		f.remove(false); // false is the recursive setting

	window.setTimeout("db_updateMini()", 444);
}

// Determine if downbar holder should be shown based on presence of downloads
function db_checkShouldShow() {

	var downbarelem = document.getElementById("downbar");

	if(!db_miniMode) {

		if (downbarelem.childNodes.length > 1) {   // one child is the template
			document.getElementById("downbarHolder").hidden = false;
		}
		else {
			document.getElementById("downbarHolder").hidden = true;
		}
	}
}

function db_setStyles() {

	var downbarelem = document.getElementById("downbar");

	try {
		var styleDefault = db_pref.getBoolPref("downbar.style.default");
		var showMainButton = db_pref.getBoolPref("downbar.display.mainButton");
		var showClearButton = db_pref.getBoolPref("downbar.display.clearButton");
		var showToMiniButton = db_pref.getBoolPref("downbar.display.toMiniButton");
	} catch (e){}

	if(showMainButton)
		document.getElementById("downbarMainMenuButton").hidden = false;
	else
		document.getElementById("downbarMainMenuButton").hidden = true;

	if(showClearButton)
		document.getElementById("downbarClearButton").hidden = false;
	else
		document.getElementById("downbarClearButton").hidden = true;

	if(showToMiniButton)
		document.getElementById("downbarToMiniButton").hidden = false;
	else
		document.getElementById("downbarToMiniButton").hidden = true;

	if(styleDefault) {
		//Set class back to what it is supposed to be and set style to nothing ("")
		downbarelem.setAttribute("style", "");
		downbarelem.firstChild.childNodes[0].firstChild.setAttribute("style", "");
		if(db_useGradients) {
			downbarelem.firstChild.childNodes[1].firstChild.setAttribute("style", "background-image:url(chrome://downbar/skin/whiteToTransGrad.png);");
			downbarelem.firstChild.childNodes[2].firstChild.setAttribute("style", "background-image:url(chrome://downbar/skin/whiteToTransGrad.png);");
			downbarelem.firstChild.childNodes[0].firstChild.firstChild.firstChild.setAttribute("style", "background-image:url(chrome://downbar/skin/whiteToTransGrad.png);");
			downbarelem.firstChild.childNodes[3].firstChild.firstChild.firstChild.setAttribute("style", "background-image:url(chrome://downbar/skin/whiteToTransGrad.png);");
			downbarelem.firstChild.childNodes[4].firstChild.setAttribute("style", "background-image:url(chrome://downbar/skin/whiteToTransGrad.png);");
		}
		else {
			downbarelem.firstChild.childNodes[1].firstChild.setAttribute("style", "");
			downbarelem.firstChild.childNodes[2].firstChild.setAttribute("style", "");
			downbarelem.firstChild.childNodes[0].firstChild.firstChild.firstChild.setAttribute("style", "");
			downbarelem.firstChild.childNodes[3].firstChild.firstChild.firstChild.setAttribute("style", "");
			downbarelem.firstChild.childNodes[4].firstChild.setAttribute("style", "");
		}
		downbarelem.firstChild.childNodes[3].firstChild.setAttribute("style", "");
		downbarelem.firstChild.childNodes[0].firstChild.firstChild.lastChild.setAttribute("style", "");
		downbarelem.firstChild.childNodes[3].firstChild.firstChild.lastChild.setAttribute("style", "");
		downbarelem.firstChild.childNodes[0].firstChild.lastChild.firstChild.setAttribute("style", "");
		downbarelem.firstChild.childNodes[3].firstChild.lastChild.firstChild.setAttribute("style", "");
		downbarelem.firstChild.childNodes[1].firstChild.lastChild.setAttribute("style", "");
		downbarelem.firstChild.childNodes[2].firstChild.firstChild.setAttribute("style", "");
		downbarelem.firstChild.childNodes[4].firstChild.firstChild.setAttribute("style", "");
		for(var i=0; i<4; ++i)
			downbarelem.firstChild.childNodes[0].firstChild.lastChild.lastChild.childNodes[i].setAttribute("style", "");
		for(var i=0; i<4; ++i)
			downbarelem.firstChild.childNodes[3].firstChild.lastChild.lastChild.childNodes[i].setAttribute("style", "");
		document.getElementById("db_widthSpacer").setAttribute("style", "min-width:125px;");

	}
	else {
		//Read custom prefs
		try {
			var downbarStyle = db_pref.getCharPref("downbar.style.db_downbar");
			var downbarPopupStyle = db_pref.getCharPref("downbar.style.db_downbarPopup");
			var progressStackStyle = db_pref.getCharPref("downbar.style.db_progressStack");
			var finishedHboxStyle = db_pref.getCharPref("downbar.style.db_finishedHbox");
			var notdoneHboxStyle = db_pref.getCharPref("downbar.style.db_notdoneHbox");
			var pausedHboxStyle = db_pref.getCharPref("downbar.style.db_pausedHbox");
			var progressbarStyle = db_pref.getCharPref("downbar.style.db_progressbar");
			var progressremainderStyle = db_pref.getCharPref("downbar.style.db_progressremainder");
			var filenameLabelStyle = db_pref.getCharPref("downbar.style.db_filenameLabel");
			var progressIndicatorStyle = db_pref.getCharPref("downbar.style.db_progressIndicator");
		} catch (e){}

		//Set styles to the new style - automatically overrides the class css rules
		if(db_miniMode)
			downbarelem.setAttribute("style", downbarPopupStyle);
		else
			downbarelem.setAttribute("style", downbarStyle);
		downbarelem.firstChild.childNodes[0].firstChild.setAttribute("style", progressStackStyle);
		downbarelem.firstChild.childNodes[1].firstChild.setAttribute("style", finishedHboxStyle);
		downbarelem.firstChild.childNodes[2].firstChild.setAttribute("style", notdoneHboxStyle);
		downbarelem.firstChild.childNodes[4].firstChild.setAttribute("style", notdoneHboxStyle);
		downbarelem.firstChild.childNodes[3].firstChild.setAttribute("style", pausedHboxStyle);
		downbarelem.firstChild.childNodes[0].firstChild.firstChild.firstChild.setAttribute("style", progressbarStyle);
		downbarelem.firstChild.childNodes[3].firstChild.firstChild.firstChild.setAttribute("style", progressbarStyle);
		downbarelem.firstChild.childNodes[0].firstChild.firstChild.lastChild.setAttribute("style", progressremainderStyle);
		downbarelem.firstChild.childNodes[3].firstChild.firstChild.lastChild.setAttribute("style", progressremainderStyle);
		downbarelem.firstChild.childNodes[0].firstChild.lastChild.firstChild.setAttribute("style", filenameLabelStyle);
		downbarelem.firstChild.childNodes[3].firstChild.lastChild.firstChild.setAttribute("style", filenameLabelStyle);
		downbarelem.firstChild.childNodes[1].firstChild.lastChild.setAttribute("style", filenameLabelStyle);
		downbarelem.firstChild.childNodes[2].firstChild.firstChild.setAttribute("style", filenameLabelStyle);
		downbarelem.firstChild.childNodes[4].firstChild.firstChild.setAttribute("style", filenameLabelStyle);
		for(var i=0; i<4; ++i)
			downbarelem.firstChild.childNodes[0].firstChild.lastChild.lastChild.childNodes[i].setAttribute("style", progressIndicatorStyle);
		for(var i=0; i<4; ++i)
			downbarelem.firstChild.childNodes[3].firstChild.lastChild.lastChild.childNodes[i].setAttribute("style", progressIndicatorStyle);

		var spacerW = parseInt(finishedHboxStyle.split(":")[2]);
		document.getElementById("db_widthSpacer").setAttribute("style", "min-width:" + spacerW + "px;");
	}
//downbarelem.builder.rebuild();  db_checkShouldShow();
    window.setTimeout(function(){downbarelem.builder.rebuild();  db_checkShouldShow();  db_startInProgress();}, 10);  // Fixes bug #13537. Don't know why this is necessary, but it fixes a bug where the back button isn't available on the second page of a newly opened window
}

function db_stopTooltip(dlElem) {
	//d("in stopTooltip");
	try {
		var elem = document.getElementById(dlElem);
		window.clearTimeout(elem.pTimeCode);
	} catch(e) {}
}

function db_setupProgTooltip(progElem) {
	//d("in setupProgTooltip");

	document.getElementById("db_progTipIcon").setAttribute("src", "moz-icon:" + progElem + "?size=32");
	document.getElementById("db_progTipFileName").value = db_getRDFProperty(progElem, "Name");

	var elem = document.getElementById(progElem);
	document.getElementById("progTipSource").value = elem.getAttribute("pURL");
	document.getElementById("progTipTarget").value = elem.id;

	db_makeTooltip(progElem);
}


// Calls a timeout to itself at the end so the tooltip keeps updating with in progress info
function db_makeTooltip(dlElem) {
	//d("in makeTooltip");
	try {  // if there's an error, (the download completed) we won't continue calling settimeout
		var elem = document.getElementById(dlElem);

		var percent = elem.lastChild.lastChild.firstChild.value;
		var speed = elem.lastChild.lastChild.firstChild.nextSibling.value;
		var currSize = elem.lastChild.lastChild.lastChild.previousSibling.value;
		var remainTime = elem.lastChild.lastChild.lastChild.value;
		var totalSize = elem.pTotalKBytes;

		var db_unkStr = db_strings.getString("unknown");

		// If the mode is undetermined, we won't know these - firefox bug is giving us the wraparound 2^54 value instead of -1
		if (totalSize == "18014398509481984")  {
			percent = db_unkStr;
			totalSize = db_unkStr;
			remainTime = db_unkStr;
		}
		else {
			if (totalSize > 1024)
				totalSize = db_convertToMB(totalSize) + " " + db_strings.getString("MegaBytesAbbr");
			else
				totalSize = totalSize + " " + db_strings.getString("KiloBytesAbbr");
		}

		/*if (elem.pSavedBytes && elem.pTotalBytes) {
			var currbytes = elem.pSavedBytes;
			var totalbytes = elem.pTotalBytes;

			var currkb = parseInt(currbytes / 1024); // KBytes
			var totalkb = parseInt(totalbytes / 1024); // KBytes
			var remainingkb = totalkb - currkb;

			if (currkb > 1024)
				var currSize = db_convertToMB(currkb) + " MB";
			else
				var currSize = currkb + " KB"


		}
		else {
			var currkb = db_unkStr;
			var totalkb = db_unkStr;
		}
*/

		document.getElementById("progTipStatus").value = currSize + " of " + totalSize + " (at " + speed + " " + db_strings.getString("KBperSecond") + ")";
		document.getElementById("progTipTimeLeft").value = remainTime;
		document.getElementById("progTipPercentText").value = percent;

		elem.pTimeCode = window.setTimeout(function(){db_makeTooltip(dlElem);}, 1000);
	} catch(e) {
		document.getElementById("progresstip").hidePopup();
	}
}

function db_makeFinTip(idtoview) {
	//d("in makeFinTip");
	
	// have to use this parser to get the 'correct' filepath because "file://" gets appended on linux cross session downloads IDs for stupid reasons. See bug 239948
	var localFile = db_getLocalFileFromNativePathOrUrl(idtoview);
	var url = db_getRDFProperty(idtoview, "URL");

	var localFilename = db_getRDFProperty(idtoview, "Name");
	document.getElementById("db_fintipIcon").setAttribute("src", "moz-icon:" + localFile.path + "?size=32");

	document.getElementById("db_fintipFileName").value = localFilename;
	var localFileSplit = localFilename.split(".");
	var fileext = localFileSplit[localFileSplit.length-1].toLowerCase();
	
	if(fileext == "gif" | fileext == "jpg" | fileext == "png" | fileext == "jpeg") {
		db_getImgSize(localFile);
		document.getElementById("db_tipImgPreviewBox").hidden = false;
	}
	
	// Get DL size from the filesystem so that bad translations won't break this, see mozdev bug
	// Also, bug: if downloads.rdf is telling us 0KB or 1KB, then it's probably a directly opened file, or an image saved from cache and this isn't the real size
	// In the future if downloads.rdf is more reliable, might want to switch back.
	try {
		var dlSize = parseInt(localFile.fileSize / 1024);  // convert bytes to kilobytes
	} catch(e){
		// Not found in file system, fall back on downloads.rdf (xxx or should we warn that file wasn't found)
		var dlSize = db_getRDFProperty(idtoview, "Transferred");
		dlSize = dlSize.split(" ")[0];
		dlSize = dlSize.substring(0, dlSize.length-2);  // Takes off "KB" so we can do math
	}

	var startTime = db_getRDFProperty(idtoview, "DateStarted");
	// images saved from cache don't get a start time in ff2.0
	if(startTime) {
		var endTime = db_getRDFProperty(idtoview, "DateEnded");
		seconds = (endTime-startTime)/1000000;
		completeTime = db_formatSeconds(seconds);
		var avgSpeed = dlSize / seconds;
		avgSpeed = Math.round(avgSpeed*100)/100;  // two decimal points
	}
	else {
		var db_unkStr = db_strings.getString("unknown");
		completeTime = db_unkStr;
		avgSpeed = db_unkStr;
	}

	if (dlSize > 1024) {
		dlSize = db_convertToMB(dlSize);
		dlSize = dlSize + " " + db_strings.getString("MegaBytesAbbr")
	}
	else
		dlSize = dlSize + " " + db_strings.getString("KiloBytesAbbr")


	if (completeTime == "00:00")
		completeTime = "<00:01";

	document.getElementById("finSource").value = url;
	document.getElementById("finTarget").value = idtoview;
	document.getElementById("finSize").value = dlSize;
	document.getElementById("finTime").value = completeTime;
	document.getElementById("finSpeed").value = avgSpeed + " " + db_strings.getString("KBperSecond");

}

function db_getImgSize(localFile) {
	//d("in getImgSize");
	
	// xxx Test if image is still in filesystem and display a "file not found" if it isn't
	
	var aImage = new Image();
	aImage.onload = function() {
		db_resizeShowImg(aImage.width, aImage.height, localFile);
	}
	aImage.src = "file://" + localFile.path;

}

function db_resizeShowImg(width, height, localFile) {
	//d("in resizeShowImg");

	//d(width + " x " + height);
	var newHeight = 100;
	var newWidth = 100;
	
	if(width>height) {
		ratio = width / 100;
		newHeight = parseInt(height / ratio);
	//	d(newHeight);
		
	}
	if(height>width) {
		ratio = height / 100;
		newWidth = parseInt(width / ratio);
	//	d(newWidth);
		
	}
	
	document.getElementById("db_tipImgPreview").setAttribute("width", newWidth);
	document.getElementById("db_tipImgPreview").setAttribute("height", newHeight);
	
	document.getElementById("db_tipImgPreview").setAttribute("src", "file://" + localFile.path);
	
}

function db_closeFinTip() {
	//d("in closeFinTip");
	document.getElementById("db_tipImgPreview").setAttribute("src", "");
	document.getElementById("db_tipImgPreviewBox").hidden = true;
	
}

// Intercept the tooltip and show my fancy tooltip (placed at the correct corner) instead
function db_redirectTooltip(elem) {

    var popupAnchor = elem;
    while(!popupAnchor.id) {
		popupAnchor = popupAnchor.parentNode;
	}

	var dltype = popupAnchor.getAttribute("context");
	if(dltype == "donecontext")
    	document.getElementById("fintip").showPopup(popupAnchor,  -1, -1, 'tooltip', 'topleft' , 'bottomleft');

    if(dltype == "progresscontext" | dltype == "pausecontext")
    	document.getElementById("progresstip").showPopup(popupAnchor,  -1, -1, 'tooltip', 'topleft' , 'bottomleft');

    // holds a ref to this anchor node so we can remove the onmouseout later
    db_currTooltipAnchor = popupAnchor;
    //document.popupNode = popupAnchor;
    
	popupAnchor.setAttribute("onmouseout", "db_hideRedirPopup(event);");
    return false;  // don't show the default tooltip

}

function db_hideRedirPopup(aEvent) {
	//d("in hideRedir");
	
	try {
		if(aEvent) {
			
			var target = aEvent.target;
		    while(!target.id) {
				target = target.parentNode;
			}
			var otherTarget;
			// relatedTarget works on Windows, explicitOriginalTarget on Linux, Mac??
			// but linux is also missing something that closes the tooltip when mousing off the tooltip
			// so just have it close on linux, by erroring out.
			//try {
				otherTarget = aEvent.relatedTarget;
			    while(!otherTarget.id) {
					otherTarget = otherTarget.parentNode;
				}
			/*} catch(e) {
				otherTarget = aEvent.explicitOriginalTarget;
			    while(!otherTarget.id) {
					otherTarget = otherTarget.parentNode;
				}
			}
			
			var currtarget = aEvent.currentTarget;
		    while(!currtarget.id) {
				currtarget = currtarget.parentNode;
			}
			var oritarget = aEvent.originalTarget;
		    while(!oritarget.id) {
				oritarget = oritarget.parentNode;
			}
			*/
			
			//d('tar ' + target.id);
			//d('currtarget ' + currtarget.id);
			//d('oritarget ' + oritarget.id);
			//d('othtar ' + otherTarget.id);
			//d('expOritarget ' + expOritarget.id);
			//d(" ");	
			
			
			othID = otherTarget.id;
			// Allow cursor to go up on the tooltip and not close, Note: tooltip background images have a 2px transparent
				// bottom so that the cursor can move directly between DL elem and tooltip
			if(othID == "fintip" | othID == "progresstip" | othID == "finTipMiddle" | othID == "finTipLeftImg" | othID == "progTipMiddle" | othID == "progTipLeftImg")
				return;
	
			// we are still on the same elem
			if(target.id == otherTarget.id)
				return;
		}
		
	} catch(e) {
		//d("error in hideredir");
	}
	
	// If there was no proper event, hide the popup by default anyway
	document.getElementById("fintip").hidePopup();
   	document.getElementById("progresstip").hidePopup();
}

function db_convertToMB(size) {
	size = size/1024;
	size = Math.round(size*100)/100;  // two decimal points
	return size;
}

function db_formatSeconds(secs) {
// Round the number of seconds to remove fractions.
	secs = parseInt( secs + .5 );
	var hours = parseInt( secs/3600 );
	secs -= hours*3600;
	var mins = parseInt( secs/60 );
	secs -= mins*60;
	var result;

    if ( mins < 10 )
        mins = "0" + mins;
    if ( secs < 10 )
        secs = "0" + secs;

    if (hours) {
    	if ( hours < 10 ) hours = "0" + hours;
    	result = hours + ":" + mins + ":" + secs;
	}
	else result = mins + ":" + secs;

    return result;
}

function db_readPrefs() {
	// Get and save display prefs
	try {
		var percentDisp = db_pref.getBoolPref("downbar.display.percent");
		var speedDisp = db_pref.getBoolPref("downbar.display.speed");
		var sizeDisp = db_pref.getBoolPref("downbar.display.size");
		var timeDisp = db_pref.getBoolPref("downbar.display.time");
	} catch (e){}

	var downbarelem = document.getElementById("downbar");

	// set which text status is set on the templates for both progress and paused rules
	//percent
	downbarelem.firstChild.childNodes[0].firstChild.lastChild.lastChild.firstChild.hidden = !percentDisp;
	downbarelem.firstChild.childNodes[3].firstChild.lastChild.lastChild.firstChild.hidden = !percentDisp;
	//speed
	downbarelem.firstChild.childNodes[0].firstChild.lastChild.lastChild.firstChild.nextSibling.hidden = !speedDisp;
	downbarelem.firstChild.childNodes[3].firstChild.lastChild.lastChild.firstChild.nextSibling.hidden = !speedDisp;
	//size
	downbarelem.firstChild.childNodes[0].firstChild.lastChild.lastChild.lastChild.previousSibling.hidden = !sizeDisp;
	downbarelem.firstChild.childNodes[3].firstChild.lastChild.lastChild.lastChild.previousSibling.hidden = !sizeDisp;
	//time
	downbarelem.firstChild.childNodes[0].firstChild.lastChild.lastChild.lastChild.hidden = !timeDisp;
	downbarelem.firstChild.childNodes[3].firstChild.lastChild.lastChild.lastChild.hidden = !timeDisp;

	// Get the anti-virus filetype exclude list and num for queue
	try {
		var excludeRaw = db_pref.getCharPref("downbar.function.virusExclude");
		excludeRaw = excludeRaw.toLowerCase().replace(/\s/g,'');  // remove all whitespace
		db_excludeList = excludeRaw.split(",");
		//db_queueNum = db_pref.getIntPref("downbar.function.queueNum");
	} catch(e){}

	// Get autoClear and ignore filetypes
	try {
		var clearRaw = db_pref.getCharPref("downbar.function.clearFiletypes");
		clearRaw = clearRaw.toLowerCase().replace(/\s/g,'');  // remove all whitespace
		db_clearList = clearRaw.split(",");

		var ignoreRaw = db_pref.getCharPref("downbar.function.ignoreFiletypes");
		ignoreRaw = ignoreRaw.toLowerCase().replace(/\s/g,'');  // remove all whitespace
		db_ignoreList = ignoreRaw.split(",");
	} catch(e){}

	//Get SpeedColor settings
	try{
		db_speedColorsEnabled = db_pref.getBoolPref("downbar.style.speedColorsEnabled");
		if(db_speedColorsEnabled) {
			var speedRaw0 = db_pref.getCharPref("downbar.style.speedColor0");
			db_speedColor0 = speedRaw0.split(";")[1];
			// no division necessary should always be 0
			var speedRaw1 = db_pref.getCharPref("downbar.style.speedColor1");
			db_speedDivision1 = speedRaw1.split(";")[0];
			db_speedColor1 = speedRaw1.split(";")[1];
			var speedRaw2 = db_pref.getCharPref("downbar.style.speedColor2");
			db_speedDivision2 = speedRaw2.split(";")[0];
			db_speedColor2 = speedRaw2.split(";")[1];
			var speedRaw3 = db_pref.getCharPref("downbar.style.speedColor3");
			db_speedDivision3 = speedRaw3.split(";")[0];
			db_speedColor3 = speedRaw3.split(";")[1];
		}
	} catch(e){}

	// Open dlmgr onclose settings
	var db_observerService = Components.classes["@mozilla.org/observer-service;1"]
	                                  .getService(Components.interfaces.nsIObserverService);
	// first remove the observer to avoid adding duplicate observers
	try{
		db_observerService.removeObserver(db_gDownloadManager, "quit-application-requested");
	} catch(e){}
	try{
		var launchDLWin = db_pref.getBoolPref("downbar.function.launchOnClose");
	} catch(e){}
	// Add back the download manager observer if we don't want to control onclose downloads
	if(!launchDLWin)
		 db_observerService.addObserver(db_gDownloadManager, "quit-application-requested", false);
	// Animation setting
	try{
		db_useAnimation = db_pref.getBoolPref("downbar.function.useAnimation");
	} catch(e){}
	// Color Gradients Setting
	try{
		db_useGradients = db_pref.getBoolPref("downbar.style.useGradients");
	} catch(e){}
	try {
		db_miniMode = db_pref.getBoolPref("downbar.function.miniMode");
	} catch(e){}

	window.setTimeout(function(){downbarelem.builder.rebuild();}, 10); // fixes bug 13537, don't know why
}

function db_finishedClickHandle(aElem, aEvent) {

	if(aEvent.button == 0 && aEvent.shiftKey)
		db_renameFinished(aElem.id);

	if(aEvent.button == 1) {
		if(aEvent.ctrlKey)
			db_startDelete(aElem.id, aEvent);
		else
			db_animateDecide(aElem.id, "clear", aEvent);
	}
}

var db_aPromptObj = {value:""};

function db_renameFinished(elemid) {

	var rename = db_strings.getString("rename");
	var to = db_strings.getString("to");
	var promptTitle = db_strings.getString("renameTitle");
	var oldfilename = db_getRDFProperty(elemid, "Name");
	var ext = "";
	var oldArray = oldfilename.split(".");
	if(oldArray.length > 1)
		ext = oldArray.pop();
	var oldname = oldArray.join(".");
	if(ext != "")
		ext = "." + ext;

	var promptText = rename + "\n" + oldname + "\n" + to;
	db_aPromptObj.value = oldname;
	var ps = Components.classes["@mozilla.org/embedcomp/prompt-service;1"].getService(Components.interfaces.nsIPromptService);
	var nameChanged = ps.prompt(window, promptTitle, promptText, db_aPromptObj, null, {value: null});

	if(nameChanged) {
		var file = db_getLocalFileFromNativePathOrUrl(elemid);
		var newfilename = db_aPromptObj.value + ext;
		if(oldfilename == newfilename)
			return;
		try {
			file.moveTo(null, newfilename);
		} catch(e) {
			// File not found
			var browserStrings = document.getElementById("bundle_browser");
			document.getElementById("statusbar-display").label = db_strings.getString("fileNotFound");
    		window.setTimeout(function(){document.getElementById("statusbar-display").label = browserStrings.getString("nv_done");}, 3000);
			return;
		}

		// fix the downloads.rdf graph
		var db_RDFC = '@mozilla.org/rdf/container;1';
		db_RDFC = Components.classes[db_RDFC].createInstance();
		db_RDFC = db_RDFC.QueryInterface(Components.interfaces.nsIRDFContainer);

		var db_RDFCUtils = '@mozilla.org/rdf/container-utils;1';
		db_RDFCUtils = Components.classes[db_RDFCUtils].getService();
		db_RDFCUtils = db_RDFCUtils.QueryInterface(Components.interfaces.nsIRDFContainerUtils);

		var db_RDF = '@mozilla.org/rdf/rdf-service;1';
		db_RDF = Components.classes[db_RDF].getService();
		db_RDF = db_RDF.QueryInterface(Components.interfaces.nsIRDFService);

		var dsource = db_gDownloadManager.datasource;
		var dlRootNode = db_RDF.GetResource("NC:DownloadsRoot");
		try {
	      db_RDFC.Init(dsource,dlRootNode);
	    } catch (e) {
	      // it should always already be there
	      //ds_RDFCUtils.MakeSeq(dsource,dlRootNode);
	      //ds_RDFC.Init(dsource,dlRootNode);
	    }

	    // get old and new resources, insert the new where the old one is, (old goes to +1)
		var oldRes = db_RDF.GetResource(elemid);
		var oldIndex = db_RDFC.IndexOf(oldRes);
		var newfile = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);
    	newfile.initWithPath(file.parent.path);
		newfile.appendRelativePath(newfilename);
		var newRes = db_RDF.GetResource(newfile.path);

		db_RDFC.InsertElementAt(newRes, oldIndex, true);

		// Move the download properties we want to keep over to the new resource
		var propertyArc, value;
		// xxx prob should enumerate ArcLabelsOut instead of this static array
		var dlProps = ["Transferred", "URL", "DateEnded",
						"DownloadState", "ProgressPercent", "DownbarShow"];
		for (var i = 0; i < dlProps.length; ++i) {
			propertyArc = db_RDF.GetResource("http://home.netscape.com/NC-rdf#" + dlProps[i]);
			var target = dsource.GetTarget(oldRes, propertyArc, true);
			dsource.Move(oldRes, newRes, propertyArc, target);
		}
		// Images saved from cache don't have a DateStarted in ff2.0
		// This would be unnecessary if we enumerate ArcLabelsOut
		try {
			propertyArc = db_RDF.GetResource("http://home.netscape.com/NC-rdf#" + "DateStarted");
			var target = dsource.GetTarget(oldRes, propertyArc, true);
			dsource.Move(oldRes, newRes, propertyArc, target);
		} catch(e) {}

		db_RDFC.RemoveElementAt(oldIndex+1, true);

		// Unassert the name and file from the old resource, (we didn't move these)
		// now nothing pointing at the resource, it dies
		var nameArc = db_RDF.GetResource("http://home.netscape.com/NC-rdf#Name");
		var fileArc = db_RDF.GetResource("http://home.netscape.com/NC-rdf#File");
		var nameTarget = dsource.GetTarget(oldRes, nameArc, true);
		var fileTarget = dsource.GetTarget(oldRes, fileArc, true);
		dsource.Unassert(oldRes, nameArc, nameTarget);
		dsource.Unassert(oldRes, fileArc, fileTarget);

		// Give the new resource the proper name and file
		var newNameTarget = db_RDF.GetLiteral(newfilename);
		var newFileTarget = db_RDF.GetResource(newfile.path);
		dsource.Assert(newRes, nameArc, newNameTarget, true);
		dsource.Assert(newRes, fileArc, newFileTarget, true);

		// save the datasource
		var rdfsource = dsource.QueryInterface(Components.interfaces.nsIRDFRemoteDataSource);
		rdfsource.Flush();

		document.getElementById("downbar").builder.rebuild();

		// make the filename text bold for 2 sec - this way works for both default and custom styles
		var origStyle = document.getElementById(newfile.path).lastChild.getAttribute("style");
		var tempStyle = origStyle + "font-weight:bold;";

		document.getElementById(newfile.path).lastChild.setAttribute("style", tempStyle);
		window.setTimeout(function(){
			document.getElementById(newfile.path).lastChild.setAttribute("style", origStyle);
		}, 2000);
	}
}

// xxx still needed?
function db_toggleDownbar() {

	var downbarHoldElem = document.getElementById("downbarHolder");
	if (downbarHoldElem.hidden) {
		downbarHoldElem.hidden = false;
		db_checkShouldShow();
	}
	else
		downbarHoldElem.hidden = true;
}

// These two RDF functions slightly modified from built-in download manager - downloads.js in firefox 0.8
function db_setRDFProperty(aID, aProperty, aValue) {

	var rdf = Components.classes["@mozilla.org/rdf/rdf-service;1"].getService(Components.interfaces.nsIRDFService);
	var db = db_gDownloadManager.datasource;
	var propertyArc = rdf.GetResource("http://home.netscape.com/NC-rdf#" + aProperty);
	var res = rdf.GetResource(aID);
	var node = db.GetTarget(res, propertyArc, true);

	if (node)
		db.Change(res, propertyArc, node, aValue);
	else
		db.Assert(res, propertyArc, aValue, true);
	var remoteDS = db.QueryInterface(Components.interfaces.nsIRDFRemoteDataSource);
    remoteDS.Flush();
}

function db_getRDFProperty(aID, aProperty) {
	var rdf = Components.classes["@mozilla.org/rdf/rdf-service;1"].getService(Components.interfaces.nsIRDFService);

	var db = db_gDownloadManager.datasource;
	var propertyArc = rdf.GetResource("http://home.netscape.com/NC-rdf#" + aProperty);

	var res = rdf.GetResource(aID);
	var node = db.GetTarget(res, propertyArc, true);
	if (!node) return "";
	try {
		node = node.QueryInterface(Components.interfaces.nsIRDFLiteral);
		return node.Value;
	}
	catch(e) {
		try {
			node = node.QueryInterface(Components.interfaces.nsIRDFInt);
			return node.Value;
		}
		catch(e) {
			try {
				node = node.QueryInterface(Components.interfaces.nsIRDFResource);
				return node.Value;
			} catch(e) {
				node = node.QueryInterface(Components.interfaces.nsIRDFDate);
				return node.Value;
			}

		}
	}
	return "";
}

function db_checkMiniMode() {

	var currDownbar = document.getElementById("downbar").localName;
	var downbarHolder = document.getElementById("downbarHolder");

	if(db_miniMode) {

		if(currDownbar == "hbox") { // convert to miniMode
			var db_ds = db_gDownloadManager.datasource;
			document.getElementById("downbar").database.RemoveDataSource(db_ds);
			document.getElementById("downbar").id = "downbarHboxTemp";
			document.getElementById("downbarPopupTemp").id = "downbar";

			document.getElementById("downbar").database.AddDataSource(db_ds);
			document.getElementById("downbar").builder.rebuild();

			document.getElementById("downbarHboxTemp").builder.rebuild();  // gets rid of the download items that were already there on the old mode
																		   // Apparently this needs to be before the next line, where it is hidden or else causes a crash when del.ici.ous is installed
																		   // This line " var docStyleSheets =  document.styleSheets;" in del.ici.ous appears to be involved somehow, commentting it out also fixes crash
			downbarHolder.hidden = true;

			document.getElementById("downbarMini").collapsed = false;
			db_updateMini();
			db_readPrefs();
		}
		document.getElementById("changeModeContext").label = db_strings.getString("toFullMode");
		document.getElementById("changeModeContext2").label = db_strings.getString("toFullMode");
	}
	else {
		if(currDownbar == "vbox") { // convert to fullMode
			var db_ds = db_gDownloadManager.datasource;
			document.getElementById("downbar").database.RemoveDataSource(db_ds);
			document.getElementById("downbar").id = "downbarPopupTemp";
			document.getElementById("downbarHboxTemp").id = "downbar";

			document.getElementById("downbar").database.AddDataSource(db_ds);
			document.getElementById("downbar").builder.rebuild();

			document.getElementById("downbarMini").collapsed = true;
			document.getElementById("downbarPopupTemp").builder.rebuild();  // gets rid of the download items that were already there on the old mode
			downbarHolder.hidden = false;
			db_readPrefs();
		}
		document.getElementById("changeModeContext").label = db_strings.getString("toMiniMode");
		document.getElementById("changeModeContext2").label = db_strings.getString("toMiniMode");
	}
	db_setStyles();
}

function db_startUpdateMini() {

	window.setTimeout(function(){db_updateMini();}, 444);

}

function db_updateMini() {

	var activeDownloads = db_gDownloadManager.activeDownloadCount;
	var dbelems = document.getElementById("downbar").childNodes;
	var finishedDownloads = dbelems.length - activeDownloads - 1;  //one for the template
	document.getElementById("downbarMiniText").value = activeDownloads + ":" + finishedDownloads;
	//downbarMini:  Collapsed if it isn't being used, hidden if it is being used but there is nothing in it
	if(activeDownloads + finishedDownloads == 0)
		document.getElementById("downbarMini").hidden = true;
	else
		document.getElementById("downbarMini").hidden = false;
}

function db_showMiniPopup(miniElem, event) {

	if(event.button == 1)
		db_modeToggle();

	if(event.button == 0)
		document.getElementById("downbarPopup").showPopup(miniElem,  -1, -1, 'popup', 'topright' , 'bottomright');

	var dbelems = document.getElementById("downbar").childNodes;
	for (var i = 1; i <= dbelems.length - 1; ++i) {
		contextAttr = dbelems[i].getAttribute("context");
		if (contextAttr == "progresscontext") {
			window.clearTimeout(dbelems[i].pTimeout);
			db_updateDLrepeat(dbelems[i].id);
		}
	}
}

function db_modeToggle() {

	db_pref.setBoolPref("downbar.function.miniMode", !db_miniMode);
	db_miniMode = !db_miniMode;

	db_checkMiniMode();
}

function db_showMainPopup(buttonElem, event) {

	if(event.button == 0)
		document.getElementById("db_mainButtonMenu").showPopup(buttonElem,  -1, -1, 'popup', 'topleft' , 'bottomleft');

}

function db_updateProgressNow() {

	// Go through in progress downloads and update the progress right away
	var dbelems = document.getElementById("downbar").childNodes;
	var percent, newWidth;
	for (var i = 1; i <= dbelems.length - 1; ++i) {
		contextAttr = dbelems[i].getAttribute("context");
		if (contextAttr == "progresscontext" | contextAttr == "pausecontext") {
			db_calcAndSetProgress(dbelems[i].id);
		}
	}
}

// This is in case a new window is opened while a download is already in progress - need to start the update repeat
function db_startInProgress() {
	var dbelems = document.getElementById("downbar").childNodes;
	for (var i = 1; i <= dbelems.length - 1; ++i) {
		contextAttr = dbelems[i].getAttribute("context");
		if (contextAttr == "progresscontext" | contextAttr == "pausecontext") {
				db_startUpdateDLrepeat(dbelems[i].id);
		}
	}
}

function db_hideDownbarPopup() {
	try {
		// This is only for the miniDownbar - prevents the downbar popup from getting stuck after using the context menu on an item
		// gets called from the onpopuphidden of each download item context menu
		document.getElementById("downbarPopup").hidePopup();
	} catch(e){}
}

// this function and following comments from firefox 1.0.4 download manager
// we should be using real URLs all the time, but until
// bug 239948 is fully fixed, this will do...
function db_getLocalFileFromNativePathOrUrl(aPathOrUrl) {
  if (aPathOrUrl.substring(0,7) == "file://") {

    // if this is a URL, get the file from that
    ioSvc = Components.classes["@mozilla.org/network/io-service;1"]
      .getService(Components.interfaces.nsIIOService);

    // XXX it's possible that using a null char-set here is bad
    const fileUrl = ioSvc.newURI(aPathOrUrl, null, null).
      QueryInterface(Components.interfaces.nsIFileURL);
    return fileUrl.file.clone().
      QueryInterface(Components.interfaces.nsILocalFile);

  } else {

    // if it's a pathname, create the nsILocalFile directly
    f = Components.classes["@mozilla.org/file/local;1"].
      createInstance(Components.interfaces.nsILocalFile);
    f.initWithPath(aPathOrUrl);

    return f;
  }
}

// This function from firefox 1.5beta2
function db_openExternal(aFile)
{
  var uri = Components.classes["@mozilla.org/network/io-service;1"]
                      .getService(Components.interfaces.nsIIOService)
                      .newFileURI(aFile);

  var protocolSvc =
      Components.classes["@mozilla.org/uriloader/external-protocol-service;1"]
                .getService(Components.interfaces.nsIExternalProtocolService);

  protocolSvc.loadUrl(uri);

  return;
}

function db_showSampleDownload() {
	
	var rdf = Components.classes["@mozilla.org/rdf/rdf-service;1"].getService(Components.interfaces.nsIRDFService);
	var ds = db_gDownloadManager.datasource;
		
	var dlRes = rdf.GetResource("NC:DownloadsRoot");
	var dlCont = Components.classes["@mozilla.org/rdf/container;1"].getService(Components.interfaces.nsIRDFContainer);
	dlCont.Init(ds, dlRes);
	var numDL = dlCont.GetCount();
	
	// show them their last download
	if(numDL > 0) {
		var allDownloads = dlCont.GetElements();
		var latestDownload = allDownloads.getNext();
		
		downloadPath = latestDownload.QueryInterface(Components.interfaces.nsIRDFResource).ValueUTF8;
		
		var intNode = rdf.GetIntLiteral(1);
		db_setRDFProperty(downloadPath, "DownbarShow", intNode);
		
	}
	
	else {
		// xxxshow a fake sample download?
	}
}

// Drag and drop TO the filesystem, Don't completely understand why this has to be so complicated.  
// Modeled after the thunderbird drag and drop of email attachments.  See msgHdrViewOverlay.js
var db_dragDropObserver = {

	onDragStart: function (event, transferData, aDragAction) {
		var elem = event.target;
		while(elem.localName != "hbox")
			elem = elem.parentNode;
		//d(elem.id);
		var localFile = db_getLocalFileFromNativePathOrUrl(elem.id);
		//d(localFile.path);
		
		//ioSvc = Components.classes["@mozilla.org/network/io-service;1"].getService(Components.interfaces.nsIIOService);
		//var fileUrl = ioSvc.newURI(localFile.path, null, null);
		//d(fileUrl.spec);
      
		transferData.data = new TransferData();
		
		//transferData.data.addDataForFlavour("text/x-moz-url",localFile.path);
        //transferData.data.addDataForFlavour("text/x-moz-url-data", localFile.path);
        //transferData.data.addDataForFlavour("text/x-moz-url-desc", localFile.leafName);

        transferData.data.addDataForFlavour("application/x-moz-file-promise-url", localFile.path);
        //transferData.data.addDataForFlavour("application/x-moz-file-promise-dir",localFile.parent.path);
        transferData.data.addDataForFlavour("application/x-moz-file-promise", new nsFlavorDataProvider(), 0, Components.interfaces.nsISupports);

        //transferData.data.addDataForFlavour("text/unicode",localFile.path);

		//aDragAction.action = Components.interfaces.nsIDragService.DRAGDROP_ACTION_COPY;
		// need to remove file from bar after it is moved by dragging

	}

};

function nsFlavorDataProvider(){}
nsFlavorDataProvider.prototype =
{
  QueryInterface : function(iid)
  {
      if (iid.equals(Components.interfaces.nsIFlavorDataProvider) ||
          iid.equals(Components.interfaces.nsISupports))
        return this;
      throw Components.results.NS_NOINTERFACE;
  },
  getFlavorData : function(aTransferable, aFlavor, aData, aDataLen)
  {
  		
	var urlPrimitive = { };
	var dataSize = { };
	aTransferable.getTransferData("application/x-moz-file-promise-url", urlPrimitive, dataSize);
	var srcUrlPrimitive = urlPrimitive.value.QueryInterface(Components.interfaces.nsISupportsString);
	//d(srcUrlPrimitive);
	
	var file = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);
	file.initWithPath(srcUrlPrimitive);
	aData.value = file;
	aDataLen.value = 4;	
  }
}


// Dump a message to Javascript Console
function d(msg){
	var acs = Components.classes["@mozilla.org/consoleservice;1"].getService(Components.interfaces.nsIConsoleService);
	acs.logStringMessage(msg);
}