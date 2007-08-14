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
 * This pref overlay stuff was inspired by Tab Mix Plus v0.3.5.2 by CPU and onemen
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


window.addEventListener("load", db_initPrefChanges, true);

function db_initPrefChanges() {
	
	try{
		var prefWindow = document.getElementById('BrowserPreferences');
	    db_newPaneLoad(prefWindow.lastSelected);
	
	    eval("prefWindow.showPane ="+prefWindow.showPane.toString().replace(
	    'this._outer._selectPane(this._pane);',
	    '$& db_newPaneLoad(this._pane.id);'
	    ));
	} catch(e){}

}

function db_newPaneLoad(newPane) {
	
	// In the privacy pane, we need to have the "Remember what I've downloaded" option obey the downbar.function.keepHistory pref
	// instead of the browser.download.mananger.retention pref. <-- This pref needs to always be 2 (keep history) so that
	// the default download manager doesn't remove downloads before download statusbar is done with it
	// See browser/content/preferences/privacy.js for original readDownloadRetention and writeDownloadRetention functions
	
	if(newPane == "panePrivacy") {
		
		//var retentionElem = document.getElementById('browser.download.manager.retention');
		try {
			//eval("gPrivacyPane.readDownloadRetention = function(){var db_pref = Components.classes['@mozilla.org/preferences-service;1'].getService(Components.interfaces.nsIPrefBranch);return db_pref.getBoolPref('downbar.function.keepHistory');}");
			eval("gPrivacyPane.readDownloadRetention = function(){}");
			eval("gPrivacyPane.writeDownloadRetention = function(){var db_pref = Components.classes['@mozilla.org/preferences-service;1'].getService(Components.interfaces.nsIPrefBranch);var checkbox = document.getElementById('rememberDownloads');db_pref.setBoolPref('downbar.function.keepHistory', checkbox.checked);return 2;}");
			//alert(gPrivacyPane.readDownloadRetention);
			//alert(gPrivacyPane.writeDownloadRetention);
			
			var db_pref = Components.classes['@mozilla.org/preferences-service;1'].getService(Components.interfaces.nsIPrefBranch);
			
			var checkbox = document.getElementById("rememberDownloads");
			checkbox.checked = db_pref.getBoolPref('downbar.function.keepHistory');
			
			// Add label here so people know where to complain if something goes wrong...
			checkbox.label = checkbox.label + " - (Download Statusbar)";
			
		} catch(e){}		
	}
	
}