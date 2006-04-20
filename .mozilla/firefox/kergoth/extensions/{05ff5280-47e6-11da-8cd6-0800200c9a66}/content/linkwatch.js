/*
 * Some code borrowed from Disable Targets for Downloads by Ben Basson (Cusser)
 */

var linkWatch = 
{
	loaded: null,

	init: function () {
		if (linkWatch.loaded)
			return; 
		linkWatch.loaded = true;
		getBrowser().addEventListener("mousedown", linkWatch.mousedown, true);
		document.getElementById("contentAreaContextMenu").addEventListener("popupshowing", linkWatch.checkPopup, false);
	},
  
	mousedown: function (aEvent)
	{
		if (!aEvent)
			return;
		if (!aEvent.originalTarget)
			return;
		var targ = aEvent.originalTarget;
		if (targ.tagName.toUpperCase() != "A") {
			// Recurse until reaching root node
			while (targ.parentNode) {
				targ = targ.parentNode;
				// stop if an anchor is located
				if (targ.tagName && targ.tagName.toUpperCase() == "A")
					break;
			}
			if (!targ.tagName || targ.tagName.toUpperCase() != "A")
				return;
		}

		var prefs = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
		if (prefs.getPrefType("extensions.sfdirectdl.mirrorName") != prefs.PREF_STRING)
			return;
		var mirror = prefs.getCharPref("extensions.sfdirectdl.mirrorName");

		/* if no mirror selected, use http://dl.sf.net/* */
		if (mirror)
			mirror = mirror + ".";

		var linkHref;
		/* pick up pref changes for links we've already seen */
		if (!(linkHref = targ.getAttribute("sfOrigHref")))
			linkHref = targ.getAttribute("href");
		
		var re = /^http:\/\/prdownloads\.s(ource)f(orge)\.net\/(.*?)\/(.*?)\?download$/i;
		if (linkHref.match(re)) {
			targ.setAttribute("sfOrigHref", linkHref);
			targ.href = "http://" + mirror + "dl.s" +
				RegExp.$1 + "f" + RegExp.$2 + ".net/sourceforge/" + 
				RegExp.$3 + "/" + RegExp.$4;
		}
	},

	checkPopup: function (ev) {
		if (!gContextMenu)
			return;
		var show = gContextMenu.onLink;
		if (show && !gContextMenu.link.getAttribute("sfOrigHref"))
			show = false;
		gContextMenu.showItem("sfdirectdl-context-menu", show);
	},
	
	openOriginal: function() {
		if (!gContextMenu)
			return;
		var show = gContextMenu.onLink;
		var orig = gContextMenu.link.getAttribute("sfOrigHref");
		if (orig)
			window.content.document.location.href = orig;
	}
}

window.addEventListener("load", linkWatch.init, false);
