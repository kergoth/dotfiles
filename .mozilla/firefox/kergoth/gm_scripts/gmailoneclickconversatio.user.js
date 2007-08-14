// ==UserScript==
// @name           Gmail - One Click Conversations
// @namespace      http://www.jeffreykeen.com/projects/oneclickconversations
// @description    Allows you to view recent conversations with someone in just one click.  Also adds rollover popup menu (ala built in quick contacts) to messages.
// @include        http://mail.gmail.com/*
// @include        https://mail.gmail.com/*
// @include        http://mail.google.com/*
// @include        https://mail.google.com/*
// ==/UserScript==

/* 
   Author: Jeff Keen - http://www.jeffreykeen.com

   Features:

     + Adds icon just to the left of sender name in list view and in message view
         + Clicking on icon takes you to the recent conversations with that user
         + Rolling over icon pops up menu, as found via the "quick contacts" panel 
	 	 + (as of 5/2007 and due to a Google code change, this only works when in message view, with one exception)
     + Adds "Recent Conversations" item to pull down menu in the message view.

   Requirements:
     + GMail view must be set to "standard with chat".

   Testing:
     + Works with Firefox 2.0 for Mac or PC with Greasemonkey
     + Definitely doesn't work with Cream Monkey for Safari.

   Version History:
 
       1.0   - 12.29.2006 - Initial Release
       1.1.0 - 12.30.2006 - One bug fix turned into major restructuring.  
       1.1.1 - 01.17.2007 - Checks if chat is enabled to prevent icons from showing up without any functionality.
       1.1.2 - 04.06.2007 - I changed the name from Quicker Contacts to One Click Conversations, a name that better describes what the main use of this script is.  
       1.1.3 - 04.19.2007 - The script now alerts you if chat isn't enabled, and provides a link to enable it.
       1.2.0 - 06.20.2007 - Fixed logic after google changed their code.
			  - Added rollover image to icon as well as tooltip, to make it more obvious that it's clickable. 
*/


const CLOCK_IMAGE = "data:image/gif;base64,R0lGODlhCgAKAKIAADMzM//M/7CwsGZmZv///8fHxwAAAAAAACH5BAEHAAEALAAAAAAKAAoAAAMp" +
"GDo8+kOUItwqJJPioh5ZNWAEmHHjdzKCRrRVAJAn8AASZT/BAACWQAIAOw==";

const PERSON_IMAGE_OVER = "data:image/gif;base64,R0lGODlhCgAKALMAADMzM//M/9LS0mZmZrm5ue7u7v///+rq6t3d3QAAAAAAAAAAAAAAAAAAAAAA" +
"AAAAACH5BAEHAAEALAAAAAAKAAoAAAQpMMhBh7xDGCMsPtvhTaAhXkF2HB2aEsQ4ITQyDkWNFB5e" +
"/D8PYEgcBiIAOw==";

const PERSON_IMAGE = "data:image/gif;base64,R0lGODlhCgAKAPcAAAAAAKzT/gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" +
"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAP8ALAAAAAAKAAoA" +
"AAgkAP8JDEAwgMCDBhEe/Jdw4MKGDB9KnAgxokKHCy1W1Fiw47+AADs=";


function evaluateXPath(aNode, aExpr) {
  var xpe = new XPathEvaluator();
  var nsResolver = xpe.createNSResolver(aNode.ownerDocument == null ? aNode.documentElement : Node.ownerDocument.documentElement);
  var result = xpe.evaluate(aExpr, aNode, nsResolver, 0, null);
  var found = [];
  var res;
  while (res = result.iterateNext()) {
    found.push(res);
  }
  return found;
}


function chatEnabled() {
	var chat=document.getElementById("nvq");
	if (chat) { 
		return true; 
	}
	else { 
		return false; 
	}
}


function listenToList(bool) {
	/* adds/removes event listener to the list view */
	var list=document.getElementById("co");
	if (list) { 
		if (bool==true) {
			 list.addEventListener("DOMNodeInserted", modListView, false); 
		}
		if (bool==false) {
			list.removeEventListener("DOMNodeInserted", modListView, false); 
		}
	}
}

function listenToMessages(bool) {
	/* adds/removes event listener to the message view */
	var msgs=document.getElementById("msgs");
	if (msgs) { 
		if (bool==true) {
			msgs.addEventListener("DOMNodeInserted", modMessageView, false); 
		}
		if (bool==false) {
			msgs.removeEventListener("DOMNodeInserted", modMessageView, false); 
		}
	}
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

function OKToModList() {
	if (IsListView() == true) {
		/* make sure we're haven't already made our mod */
		var query="//div[@id='tbd']//img[contains(@id,'_pro')]";
		var icons=evaluateXPath(unsafeWindow.document, query);
		return (icons.length > 0 ? false : true);
	}
	else {
		return false;
	}
}

function modListView() {
	if (OKToModList() == true) {
		/* Remove event listener to prevent unnecessary recursion */
		listenToList(false);
				
		/* get our address, so we don't create quick link to ourself in the case of conversations */
		var myAddressNode=evaluateXPath(unsafeWindow.document, "//td[@class='trb']/b");
		
		if (myAddressNode.length > 0 ) {
			var myAddress=myAddressNode[0].innerHTML;
		}
		
		/* find all message objects */
		var msgs = evaluateXPath(unsafeWindow.document, "//tr[contains(@id, 'w_')]"); 
		for (i=0;i<msgs.length;i++) {
			var message=msgs[i];
		
			/* Check if we have already modified this message.  If so, skip to next */
			var exists = evaluateXPath(unsafeWindow.document, "//tr[@id ='" + message.id + "']//span[contains(@id, 'pastc_')]");
			if (exists.length > 0) { continue;}
			
			/* find email addresses corresponding to this message */
			var query="//tr[contains(@id, '" + message.id + "')]//span[contains(@id, '_upro')]";
			var email= evaluateXPath(unsafeWindow.document, query);

			/* get the first address that isn't ours */
			var searchterm="";
			for (j=0; j< email.length; j++) {
				searchterm=email[j].id.substring(6,email[j].id.length);
				if (searchterm != myAddress) {
					break;
				}
			}

			if (searchterm == "") {
				/* 
				   This was put in because Google changed their code in May 2007 and removed the vital 
				   <span id="_upro_username@gmail.com">Sender Name</span> that let this script
				   know the email address of the message.  Now that it's gone this script searches by name when in list view, 
				   instead of by email address, as it used to.  Also, since the email address isn't available, the pop-up 
				   functionality on the front page won't work either unless the sender's name is an email address.
				   
				   Message view was unaffected by the Google code change, and I've left the code in place so original functionality
				   will be restored to message view if Google listens to my pleas and puts back in that tiny piece of code.
				*/
			
				var searchterms=msgs[i].childNodes[2].firstChild.textContent;

				/* cut out the message count if it's present.  i.e. Jeff (3) will yield just 'Jeff' */
				searchterms=searchterms.replace(/\(\d+\)/g,'');

				/* search for the first name that isn't 'me' */
				var search_array=searchterms.split(",");
				for (k=0; k< search_array.length; k++) {
					searchterm=search_array[k];
					if (searchterm != "me") {
						break;
					}
				}							
			}

			var TextSpan = document.createElement("span");
			/* Gmail will add click to search functionality to id's beginning with "pastc_" */
			TextSpan.id="pastc_" + searchterm;
			TextSpan.style.display='inline';
			TextSpan.style.textAlign='right';
			TextSpan.style.paddingRight='5px';

			var reg = new RegExp("@");
			var Image = document.createElement("img");
			if (reg.exec(searchterm)) {
			  	/* Gmail will add a rollover popup to id's beginning with "_pro_" */
				Image.id="_pro_" + searchterm;
			}
			else {
				/* This id should begin with _pro so OkToModList() still functions, but shouldn't 
				   be _pro_ so an invalid popup doesn't show up.
				*/
				Image.title="View Recent Conversations";
			  	Image.id= "_prox_" + searchterm;;
			}

			Image.width='10';
			Image.height='10';
			Image.src=PERSON_IMAGE;
			Image.setAttribute('onmouseover', "javascript: this.setAttribute('src', '" +  PERSON_IMAGE_OVER + "')");
			Image.setAttribute('onmouseout', "javascript: this.setAttribute('src', '" +  PERSON_IMAGE + "')");

			TextSpan.appendChild(Image);

			/* Insert the span right before the sender name */
			msgs[i].childNodes[2].insertBefore(TextSpan,msgs[i].childNodes[2].firstChild);
		}
		
		/* Listen for changes, again */
		listenToList(true);
	}

}


function modMessageView() {
	if (IsMessageView() == true) {
		/* Remove event listener to prevent unnecessary recursion */
		listenToMessages(false);
		
		var menus = evaluateXPath(document, "//div[@class='om']"); // find all menu objects
		var results= evaluateXPath(document, "//td//span[contains(@id, '_user_')]"); // find all address objects

		for (i=0;i<results.length;i++) {
			
			/* Check if we have already modified this message.  If so, skip to next */
			var address=results[i].id.substring(6,results[i].id.length); // get email from _user_blah@email.com
			var messageAlreadyModified = false;
			for (j=0;j<results[i].childNodes.length;j++) {
				if (results[i].childNodes[j].id == "pastc_" + address) {
					messageAlreadyModified= true;
				}
			}
		
			if (messageAlreadyModified==true) {continue;}
			
			/* add recent conversations item to menu, if menu exists */
			if (i < menus.length) {
				var len = menus[i].id.length;
				var menuNum=menus[i].id.substring(len-1,len); // get the actual menu number. i.e. the 3 from "om_3"
				var index=menuNum-1;

				var email=results[index].id.substring(6,results[index].id.length); // get email from _user_blah@email.com

				var Span = document.createElement("span");
				var TextSpan = document.createElement("span");
				Span.className='oi cbut h';
				Span.id="omi_" + menuNum;

				TextSpan.id="pastc_" + email;
				TextSpan.style.display='block';
				TextSpan.innerHTML="<img width='10' height='10' style='padding-right:3px; padding-left:2px; padding-top:5px; padding-bottom:0px;' src='" + CLOCK_IMAGE + "' />&nbsp;Recent conversations";

				Span.appendChild(TextSpan);
				menus[i].appendChild(Span);
			}
			
			var TextSpan = document.createElement("span");
			TextSpan.id="pastc_" + address;
			TextSpan.style.display='inline';
			TextSpan.style.textAlign='right';
			TextSpan.style.paddingRight='5px';
		
			var Image = document.createElement("img");
			Image.id="_pro_" + address;
			Image.width='10';
			Image.height='10';
			Image.src=PERSON_IMAGE;
			Image.setAttribute('onmouseover', "javascript: this.setAttribute('src', '" +  PERSON_IMAGE_OVER + "')");
			Image.setAttribute('onmouseout', "javascript: this.setAttribute('src', '" +  PERSON_IMAGE + "')");
	
			TextSpan.appendChild(Image);

			/* we need to insert our image in a slightly different place if the message details are showing */
			if (results[i].parentNode.className == "au") {
				results[i].insertBefore(TextSpan,results[i].childNodes[1]);
			}
			else {
				results[i].insertBefore(TextSpan,results[i].childNodes[0]);
			}
		}
		
		/* Listen for changes, again */
		listenToMessages(true);
	}
}

if (chatEnabled()==true) {
	modListView();
	modMessageView();
}


else if ((IsListView() == true) || (IsMessageView() == true)) { 
	// Must be in ListView or MessageView so we don't pop up a message while Gmail is loading.
	
	// Alert user that chat is not enabled
	var icon="<img src='" + PERSON_IMAGE + "' width='10' height='10' style='padding-right:5px; position:relative; top:0px;'/>";

	var messageText="<b>One Click Conversations</b> needs to enable Gmail chat in order to function.";
	var msghtml='<table width="100%" cellspacing="0" cellpadding="4" border="0" style="background-color:rgb(255,255,230); border-bottom:1px solid gray; font-size:11px; font-family:Arial; height:25px; padding-left:5px; margin-bottom:5px;"><tbody><tr><td>' + icon + unescape (messageText) + '<b><a href="javascript:// Don&apos;t worry, you don&apos;t have to talk to anyone." title="Don&apos;t worry, you don&apos;t have to talk to anyone." onclick="top.js._Main_DisableChat(false)" style="color: rgb(0, 0, 204); margin-left:10px;">Enable Gmail Chat</a></b></td></tr></tbody></table>';

	var body = document.getElementsByTagName("body")[0];
	body.innerHTML=msghtml + body.innerHTML;
}