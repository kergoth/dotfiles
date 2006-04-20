//	window.addEventListener('load', ViamaticThumbTabSettingsOnLoad, false); 
if (undefined == Viamatic) var Viamatic = new Object();
if (undefined == Viamatic.Xpose) Viamatic.Xpose = new Object();

Viamatic.Xpose.Settings = new Object();
Viamatic.Xpose.Version = "0.3";
Viamatic.Xpose.prefsService = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefService);
Viamatic.Xpose.prefs = Viamatic.Xpose.prefsService.getBranch("viamatic.xpose.");
const nsISupportsString = Components.interfaces.nsISupportsString;

Viamatic.Xpose.getUnicodePref = function(prefName) {
    try {
        return Viamatic.Xpose.prefs.getComplexValue(prefName,
                        Components.interfaces.nsISupportsString).data;
    } catch (e) {
        return null;
    }
}

Viamatic.Xpose.setUnicodePref = function(prefName, prefValue) {
    var sString = Components.classes["@mozilla.org/supports-string;1"].createInstance(nsISupportsString);
    sString.data = prefValue;
    Viamatic.Xpose.prefs.setComplexValue(prefName,nsISupportsString,sString);
}

Viamatic.Xpose.Settings.FirstTime = function() {
    Viamatic.Xpose.setUnicodePref("version", Viamatic.Xpose.Version);
    Viamatic.Xpose.setUnicodePref("theme", "black");
    Viamatic.Xpose.setUnicodePref("shortcutmodifier", "");
    Viamatic.Xpose.setUnicodePref("shortcutkey", "VK_F8");
    Viamatic.Xpose.setUnicodePref("showicon", "true" );
    Viamatic.Xpose.setUnicodePref("showkeyboardtitle", "true"); 
    Viamatic.Xpose.setUnicodePref("thumbsize", "large");    
    Viamatic.Xpose.setUnicodePref("showtab", "true");
    Viamatic.Xpose.setUnicodePref("autorefresh", "true");
    Viamatic.Xpose.setUnicodePref("autosize", "true");      
}