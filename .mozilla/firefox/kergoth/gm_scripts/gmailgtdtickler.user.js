// ==UserScript== 
// @name           GMail - GTD Tickler
// @author         Martin Ruiz
// @namespace      Martin Ruiz
// @description    Very Simple Ticker file functionality to GMail/GTDGMail using GCal
// @include        *
// ==/UserScript==

/* 
   Author: Martin Ruiz

   Credits:

     - I adapted code from a lot of other scripts on userscripts...  lost track:)

   Features:

     + Adds 'Remind me with Google Calendar Button' on the right of message in message view.
     + Adds 'Remind me' button on the top of message near Archive and Delete Buttons.
     + Opens and Fills out GCal Template in separate window with link to original message.
     + Link in GCal reminder will open GMail message in a seperate window.

   Requirements:
     + GMail view must be set to "standard with chat".

   Testing:
     + Works with Firefox 2.0 for PC with Greasemonkey

   Version History:
 
       1.0 - 02.18.2007 - Initial Release
       1.1 - 04.05.2007 - Bug Fixes
		+ Added 'Remind Me' Button on top of message near Archive and Delete buttons
		  to avoid conflicts with other scripts that remove the right div - often done 
		  by cleanup scripts.
		+ Automatically places original message subject in Title of Calendar entry
		+ Fix Bug related to special unescaped characters
       1.15- 04.15.2007 - Bug Fixes
                + Sometimes Header and/or link to gmail is not placed.
		+ Automatically closes gcal entry window if reminder successfully entered. 
		+ Avoid conflict with "Add to Calendar"
       1.2 - 04.26.2007 - Bug Fixes
                + Fixed bug due to slow GCal Entry Form load - before the link to gmail would not
                  load if it took 10 seconds or more to load.
*/

function SnapTime()
{
	var now = new Date();
	GM_setValue("LastRun", now.toUTCString());
}

function CheckLastRun()
{
	var time_str = GM_getValue("LastRun");
	if (!time_str || time_str=="") return false;
	return true;

	// ignore this bit
	var lastrun = new Date(time_str);
	var now = new Date();
	if ((now-lastrun)<10000) return true;
	return false;		
}

function ModifyCalEntry(msgid)
{
	//var regex_str = 'D\\(\\[\\"cs\\"\\,\\"'+msgid+'\\"\\,\\"(.*?)\\"';//\\,';
	var regex_str = 'D\\(\\[\\"cs\\"\\,\\".*?\\"\\,\\"(.*?)\\"\\,';
	var regex = new RegExp(regex_str, 'm');
	var params = "?&view=cv&search=all&th=" + msgid + "&lvp=-1&cvp=2&qt=";
	var url = "http://mail.google.com/mail/";

	var email_ref = "http://mail.google.com/mail/?view=cv&search=inbox&th="+msgid+"&ww=1024&lvp=0&cvp=0&qt=&tf=1&fs=1";

	var desc = document.getElementById("descrip");
	var title = document.getElementById("title");

	GM_setValue("LastRun","");

    	GM_xmlhttpRequest({
        	method:"GET",
        	headers:{ 'Accept': 'text/plain'}, 
        	url: url + params,
        	onload:function(result) {
			var data = result.responseText;
			var s = regex.exec(data);
			if (s.length>0)
			{	
				var str = s[1];
				desc.value = email_ref;
				title.value = eval("'"+str+"'");
			}
        	}
    	});		
}

function CreateGCalEntry(evt)
{
	var newEvt = document.createEvent("HTMLEvents");
	newEvt.initEvent("change", true, true);
	
	var action_id = "ce"; //Create Event
	var actions = document.getElementById("ctam");

	if (!actions) return;

	var option;
	var i;

	for (i=0;i<actions.options.length;i++)
	{
		option = actions.options[i];
		if (option.value==action_id)
		{
			option.selected=true;
			SnapTime();
			actions.dispatchEvent(newEvt);
			return;
		}
	}
}

function CreateGTDReminderButton() 
{
	//
	// Place Calendar Button in Right Nav above Ads
	//	

	var target_div = document.getElementById('rh');
	if (target_div)
	{
		var div = document.createElement('div');
		var html = '<div>';
		html = html + '<img src="http://www.google.com/calendar/images/ext/gc_button2.gif">';
		html = html + '</div>'
		div.innerHTML=html;
		div.addEventListener("click",CreateGCalEntry,false);
		target_div.insertBefore(div, target_div.childNodes[0]);	
	}
	//
	// Place Regular Button Near Action Buttons like Archive and Delete
	//

	var btn_div = document.getElementById('ac_tr').parentNode;
	if (btn_div)
	{
		var btn = document.createElement('button');
		btn.setAttribute("class","ab");
		btn.setAttribute("type", "button");
		btn.innerHTML="Remind Me";
		btn.addEventListener("click",CreateGCalEntry,false);
		btn_div.appendChild(btn);
	}
}

function evaluateXPath(aNode, aExpr) {
  var xpe = new XPathEvaluator();
  var nsResolver = xpe.createNSResolver(aNode.ownerDocument == null ? aNode.documentElement : 

Node.ownerDocument.documentElement);
  var result = xpe.evaluate(aExpr, aNode, nsResolver, 0, null);
  var found = [];
  var res;
  while (res = result.iterateNext()) {
    found.push(res);
  }
  return found;
}

function IsMessageView() {
	var query="//div[@id='fic']";
	var result=evaluateXPath(unsafeWindow.document,query);

	return (result.length > 0 ? true : false);
}

function IsListView() {
	var query="//div[@id='tbd']";
	var result=evaluateXPath(unsafeWindow.document,query);

	return (result.length > 0 ? true : false);
}

function IsGmail()
{
	var url = document.URL;
	var gmurl_regex = /mail\.google\.com/;

	if (!gmurl_regex.test(url)) return false;
	if (!IsChatEnabled() || !IsMessageView()) return false;

	return true;
}

function IsGcal()
{
	var url = document.URL;
	var gcal_regex = /www\.google\.com\/calendar\/event\?action\=TEMPLATE\&pprop\=gmailid/;

	if (!gcal_regex.test(url)) return false;

	var gmailid_regex = /.*gmailid\%3A(.*?)\&/;
	var ids = gmailid_regex.exec(url);
	
	if (ids.length==0) return false;
	
	return ids[1];
}

function IsGcalEntrySaved()
{
	var url = document.URL;
	var referrer = document.referrer;

	var gcal_saved = /www\.google\.com\/calendar\/event$/;
	var gcal_regex = /www\.google\.com\/calendar\/event\?action\=TEMPLATE\&pprop\=gmailid/;

	if (!gcal_saved.test(url)) return false;
	if (!gcal_regex.test(referrer)) return false;

	var query="//div[@class='messageToUser']";
	var msg=evaluateXPath(unsafeWindow.document,query);

	if (msg.length==0) return false;

	if (msg[0].textContent=="Your event was created.") return true;	
	
	return false;
}

function IsChatEnabled() {
	var chat=document.getElementById("nvq");
	if (chat) { 
		return true; 
	}
	else { 
		return false; 
	}
}

function start()
{
	if (IsGmail())
	{
		CreateGTDReminderButton();
		return;
	}
	var msgid=IsGcal();
	if (msgid)
	{
		if (!CheckLastRun()) return;
		setTimeout(function(){ModifyCalEntry(msgid)},500);
		return;
	}
	if (IsGcalEntrySaved())
	{
		window.close();
	}
}

start();
