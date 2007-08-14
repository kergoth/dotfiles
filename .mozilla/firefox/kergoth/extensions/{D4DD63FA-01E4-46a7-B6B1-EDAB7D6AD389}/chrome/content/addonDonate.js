window.addEventListener("load", db_addonDonateInit, true);
var enzy_pref = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
var enzy_observerService = Components.classes["@mozilla.org/observer-service;1"].getService(Components.interfaces.nsIObserverService);

function db_addonDonateInit() {

	// The donate text can be either: 
	//    1) shown 
	//    2) supressed indefinitely (or until next major update) with <supressDonateText> 
	//    3) cleared for an interval of time before it comes back with <donateTextInterval> Cleared with the X button
	
	// Test pref to see if we should supress donate text
	try {
		var supDonateText = enzy_pref.getBoolPref("downbar.function.supressDonateText");  // if not set, errors, goes onto the interval test
		if(supDonateText)
			return;
	} catch (e) {}
	
	// Test clear interval, currently 2 months to begin with, 6 months if click on donate link (60 and 180 days)
	try {
		var intervalSet = enzy_pref.getCharPref("downbar.function.donateTextInterval");  // if not set, errors, will go on to put the donate text on
		var intervalDays = enzy_pref.getIntPref("downbar.function.donateTextHideDays");
		intervalSet = parseInt(intervalSet);
		var now = ( new Date() ).getTime();
		
		var currInterval = now - intervalSet;  // milliseconds
		currIntervalDays = parseInt(currInterval / 1000 / 60 / 60 / 24);

		if(currIntervalDays < intervalDays)
			return;
		
	} catch (e) {}
	
	window.addEventListener('unload', db_addonDonateClose, false);
	enzy_observerService.addObserver(db_observer,"removeDonatePressed",false);
	
	db_gExtensionsView = document.getElementById("extensionsView");
	db_gExtensionsView.addEventListener("select", db_setDonateText, false);
	db_setDonateText();
	
	// Add this to make sure text is there after switching groups (buttons at top)
	var viewGroup = document.getElementById("viewGroup");
	var currCommand = viewGroup.getAttribute("onclick");
	viewGroup.setAttribute("onclick", currCommand + " window.setTimeout(db_setDonateText, 200);");
}

function db_setDonateText() {
	
	// Check if the text is already there, if so return
	if(document.getElementById("db_donateContainerOn"))
		return;
	
	var myext = document.getElementById("urn:mozilla:item:{D4DD63FA-01E4-46a7-B6B1-EDAB7D6AD389}");
	
	var donateContainer = document.getElementById("donateContainer");
	var donateSpacer = document.getElementById("donateSpacer");
	var donateClearImg = document.getElementById("donateClearImg");
	
	var nameVersionBox;
	try {
		// this ext is currently selected
		nameVersionBox = document.getAnonymousElementByAttribute(myext, "anonid", "addonNameVersion");
		if(!nameVersionBox)  // this ext is not currently selected
			nameVersionBox = document.getAnonymousElementByAttribute(myext, "class", "addon-name-version");
		
		var spacerClone = donateSpacer.cloneNode(true);
		spacerClone.hidden = false;
		//spacerClone.id = "donateSpacerOn";
		nameVersionBox.appendChild(spacerClone);
		
		var clearImgClone = donateClearImg.cloneNode(true);
		clearImgClone.hidden = false;
		nameVersionBox.appendChild(clearImgClone);
		
		var containerClone = donateContainer.cloneNode(true);
		containerClone.id = "db_donateContainerOn";
		containerClone.hidden = false;
		nameVersionBox.appendChild(containerClone);
	} catch (e) {}
	
}

function db_openDonate() {
	
	// Open page in new tab
	var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService();
    var wmed = wm.QueryInterface(Components.interfaces.nsIWindowMediator);
    
    var win = wmed.getMostRecentWindow("navigator:browser");
    if (!win)
    	win = window.openDialog("chrome://browser/content/browser.xul", "_blank", "chrome,all,dialog=no", "http://downloadstatusbar.mozdev.org/aboutDonations.html", null, null);
    else {
    	var content = win.document.getElementById("content");
    	content.selectedTab = content.addTab("http://downloadstatusbar.mozdev.org/aboutDonations.html");	
    }
    
    // Set to hide with interval and change the interval to 6 months after donate link is clicked
    enzy_pref.setIntPref("downbar.function.donateTextHideDays", 180);
    var now = ( new Date() ).getTime();
	enzy_pref.setCharPref("downbar.function.donateTextInterval", now);
}

// Using observer service to do this so that if more than one of my extensions is installed, all of them can respond to the same keypress
function enzy_removeDonate() {
	enzy_observerService.notifyObservers(null,"removeDonatePressed", null);
}

var db_observer = {
observe: function(subject,topic,data) {
	
	enzy_pref.setBoolPref("downbar.function.supressDonateText", true);
	var db_strings = document.getElementById("downbarbundle");
	alert(db_strings.getString("removeDonateConfirm"));
	
  }
};

// Clicked the x button to clear - set curr time to base interval off of
function db_donateClearInterval() {
	
	var now = ( new Date() ).getTime();
	enzy_pref.setCharPref("downbar.function.donateTextInterval", now);
	
	var db_strings = document.getElementById("downbarbundle");
	alert(db_strings.getString("removeDonateConfirm"));
	
}


function db_addonDonateClose() {
	
	enzy_observerService.removeObserver(db_observer,"removeDonatePressed");
	
}
