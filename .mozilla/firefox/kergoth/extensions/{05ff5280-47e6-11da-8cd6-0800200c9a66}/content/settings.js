var prefs = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);

function sfdirectdl_load_prefs() {
	if (prefs.getPrefType("extensions.sfdirectdl.mirrorName") == prefs.PREF_STRING)
		document.getElementById("sfdirectdl.prefs.mirrorName").value = prefs.getCharPref("extensions.sfdirectdl.mirrorName");
	sfdirectdl_populate_list();
}

function sfdirectdl_save_prefs() {
	prefs.setCharPref("extensions.sfdirectdl.mirrorName", document.getElementById("sfdirectdl.prefs.mirrorName").value);
}

function sfdirectdl_populate_list() {
	const XUL_NS = "http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul";

	if (prefs.getPrefType("extensions.sfdirectdl.mirrors.count") != prefs.PREF_INT)
		return;
	var count = prefs.getIntPref("extensions.sfdirectdl.mirrors.count");

	var k, name, location, continent, url, image_url;
	var listitem, elem, list, label, hbox, box;
	list = document.getElementById("mirrorList");
	while (list.getRowCount())
		list.removeChild(list.getItemAtIndex(0));

	for (k = 0; k < count; k++) {
		name = prefs.getCharPref("extensions.sfdirectdl.mirrors." + k + ".name");
		location = prefs.getCharPref("extensions.sfdirectdl.mirrors." + k + ".location");
		continent = prefs.getCharPref("extensions.sfdirectdl.mirrors." + k + ".continent");
		url = prefs.getCharPref("extensions.sfdirectdl.mirrors." + k + ".url");
		image_url = prefs.getCharPref("extensions.sfdirectdl.mirrors." + k + ".image_url");

		listitem = document.createElementNS(XUL_NS, "richlistitem");
		listitem.setAttribute("mirrorName", name);

		box = document.createElementNS(XUL_NS, "hbox");
		box.setAttribute("class", "image");
		box.setAttribute("flex", "1");
		elem = document.createElementNS(XUL_NS, "image");
		elem.setAttribute("src", image_url);
		box.appendChild(elem);
		elem = document.createElementNS(XUL_NS, "spacer");
		elem.setAttribute("flex", "1");
		box.appendChild(elem);
		listitem.appendChild(box);

		label = document.createElementNS(XUL_NS, "label");
		label.setAttribute("value", name);
		label.setAttribute("class", "title");
		listitem.appendChild(label);

		box = document.createElementNS(XUL_NS, "vbox");
		box.setAttribute("flex", "1");

		label = document.createElementNS(XUL_NS, "label");
		label.setAttribute("value", location + ", " + continent);
		box.appendChild(label);
		
		label = document.createElementNS(XUL_NS, "label");
		label.setAttribute("value", url);
		label.setAttribute("class", "text-link");
		label.setAttribute("href", url);
		label.setAttribute("flex", "0");
		box.appendChild(label);

		listitem.appendChild(box);
	
		list.appendChild(listitem);
	}
}


function sfdirectdl_list_select(list) {
	document.getElementById('sfdirectdl.prefs.mirrorName').value = list.selectedItem.getAttribute("mirrorName");
//	if (list.selectedItem)
//		document.getElementById('sfdirectdl.prefs.mirrorName').value = list.value;
}

function sfdirectdl_update_loaded(req) {
	document.getElementById('updateButton').removeAttribute("disabled");
	if (req.status != 200) {
		document.getElementById('throbber').setAttribute("state", "error");
		document.getElementById('updateLabel').setAttribute("value",
			document.getElementById('prefStrings').getString('sfdirectdl.updatestatus.error') +
			" " + req.status + ": " + req.statusText);
		return;
	}
	document.getElementById('throbber').removeAttribute("state");
	document.getElementById('updateLabel').setAttribute("value", document.getElementById('prefStrings').getString('sfdirectdl.updatestatus.done'));

	var text = req.responseText;
	text = text.replace(/\n/g, "");
	prefs.deleteBranch("extensions.sfdirectdl.mirrors");

	var re = /<td><a href="([^"]+)"><img alt="([^"]+) logo" border="0" src="([^"]+)" \/><\/a><\/td>\s+<td>([^<]+)<\/td>\s+<td>([^<]+)<\/td>/ig;

	var idx = 0;
	while (1) {
		var result = re.exec(text);
		if (!result)
			break;
		prefs.setCharPref("extensions.sfdirectdl.mirrors." + idx + ".url", result[1]);
		prefs.setCharPref("extensions.sfdirectdl.mirrors." + idx + ".name", result[2]);
		prefs.setCharPref("extensions.sfdirectdl.mirrors." + idx + ".image_url", result[3]);
		prefs.setCharPref("extensions.sfdirectdl.mirrors." + idx + ".location", result[4]);
		prefs.setCharPref("extensions.sfdirectdl.mirrors." + idx + ".continent", result[5]);
		idx++;
	}
	prefs.setIntPref("extensions.sfdirectdl.mirrors.count", idx);
	sfdirectdl_populate_list();
}

function sfdirectdl_update() {
	document.getElementById('updateButton').setAttribute("disabled", "true");
	document.getElementById('throbber').setAttribute("state", "loading");
	document.getElementById('updateLabel').setAttribute("value", document.getElementById('prefStrings').getString('sfdirectdl.updatestatus.loading'));

	var my_req = Components.classes["@mozilla.org/xmlextras/xmlhttprequest;1"].
		createInstance(Components.interfaces.nsIXMLHttpRequest);
	my_req.open("GET", "http://prdownloads.sourceforge.net/index-sf.html", true);
	my_req.setRequestHeader("Cache-Control", "no-cache");

	my_req.onload = function (event) { sfdirectdl_update_loaded(my_req); };
	my_req.onerror = function (event) { sfdirectdl_update_loaded(my_req); };
	my_req.send(null);
}
