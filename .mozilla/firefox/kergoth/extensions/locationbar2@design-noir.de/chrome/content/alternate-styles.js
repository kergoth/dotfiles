var lb2_alternateStyles = {
	styles: ["domain-color","domain-strong","subdomain-inherit","favicon-remove","segments-margin","breadcrumb-domain","breadcrumb-all","fission"],
	styleSheets: {},
	prefs: Components.classes["@mozilla.org/preferences-service;1"]
	                 .getService(Components.interfaces.nsIPrefService)
	                 .getBranch("extensions.locationbar2.alternate.")
	                 .QueryInterface(Components.interfaces.nsIPrefBranch2),
	init: function() {
		this.prefs.addObserver("", this, false);
		var ss = document.styleSheets;
		for (var i = ss.length - 1; i >= 0; i--) {
			var style = ss[i].href.match(/^chrome:\/\/locationbar2\/skin\/alternate\/(.+)\.css$/);
			if (style) {
				this.styleSheets[style[1]] = ss[i];
				this.handlePref(style[1]);
			}
		}
	},
	observe: function (subject, topic, data) {
		if (data == "fission")
			var val = gURLBar.value;
		this.handlePref(data);
		if (data == "fission")
			setTimeout(function() {
				gURLBar.value = val;
			}, 0);
	},
	handlePref: function (style) {
		if (style == "domain-color")
			this.styleSheets[style].cssRules[2].style.setProperty ("color", this.prefs.getCharPref(style) || "inherit", "");
		else
			this.styleSheets[style].disabled = ! this.prefs.getBoolPref(style);
	},
	uninit: function() {
		this.prefs.removeObserver("", this);
	}
};

window.addEventListener("load", function() {
	lb2_alternateStyles.init();
}, false);
window.addEventListener("unload", function() {
	lb2_alternateStyles.uninit();
}, false);