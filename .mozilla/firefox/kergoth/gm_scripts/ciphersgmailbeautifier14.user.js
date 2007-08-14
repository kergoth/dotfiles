// ==UserScript==
// @name          Cipher's Gmail Beautifier 1.4
// @description   Hides/Shows ads in Gmail, widens email body, removes beta from Gmail logo (disabled by default), & gives buttons a better look.
// @author        Cipher
// @version       1.4
// @include       http://mail.google.com/*
// @include       https://mail.google.com/*
// ==/UserScript==



//////////////// fixing buttons looks

var headTag = document.getElementsByTagName("head")[0];         
var cssNode = document.createElement('style');
cssNode.type = 'text/css';

styleCode="button {border-style:solid; border-width:1px; border-color:#336699; background-color:#FFFFFF; color:#003399; cursor:pointer; height:18px }";
styleCode+="button:hover {border-style:outset;}";
styleCode+="button:active {border-style:inset;}";
//for show/hide ads pane button
styleCode+=".showHideButton {color:#003399; font-family:Arial, Helvetica, sans-serif; font-weight:bold; font-size:18px; cursor:pointer}";

cssNode.innerHTML=styleCode;

headTag.appendChild(cssNode);




//////////////// removing ads & making email body wider


// parsing the showHideAdsPane() function into the head of the page
var scriptNode = document.createElement('script');
scriptNode.type = 'text/javascript';

scriptCode="function showHideAdsPane(){";
scriptCode+="if(document.getElementById('showHideAdsPaneButton').title=='Hide Ads Pane'){";
scriptCode+="document.getElementById('showHideAdsPaneButton').title='Show Ads Pane';";
scriptCode+="document.getElementById('showHideAdsPaneButton').innerHTML='&lt;&lt;';";
scriptCode+="if(document.getElementById('rh')!=null) document.getElementById('rh').style.display='none';";
scriptCode+="if(document.getElementById('ra')!=null) document.getElementById('ra').style.display='none';";
scriptCode+="if(document.getElementById('rb')!=null) document.getElementById('rb').style.display='none';";
scriptCode+="if(document.getElementById('fic')!=null) document.getElementById('fic').style.width='100%';";
scriptCode+="}";
scriptCode+="else{";
scriptCode+="document.getElementById('showHideAdsPaneButton').title='Hide Ads Pane';";
scriptCode+="document.getElementById('showHideAdsPaneButton').innerHTML='&gt;&gt;';";
scriptCode+="if(document.getElementById('rh')!=null) document.getElementById('rh').style.display='block';";
scriptCode+="if(document.getElementById('ra')!=null) document.getElementById('ra').style.display='block';";
scriptCode+="if(document.getElementById('rb')!=null) document.getElementById('rb').style.display='block';";
scriptCode+="if(document.getElementById('fic')!=null) document.getElementById('fic').style.width='';";
scriptCode+="}";
scriptCode+="}";

scriptNode.innerHTML=scriptCode;
headTag.appendChild(scriptNode);


//removing ads pane by default
if(document.getElementById("rh")!=null)
	document.getElementById("rh").style.display="none";

if(document.getElementById("ra")!=null)
	document.getElementById("ra").style.display="none";
	
if(document.getElementById("rb")!=null)
	document.getElementById("rb").style.display="none";
	
if(document.getElementById("fic")!=null)	
	document.getElementById("fic").style.width="100%";


// creating the show/hide ads pane button
if(document.getElementById("tt")!=null)
{
	var content=document.createElement("table");

	content.width="100%";
	row=content.insertRow(0);
	oldData=row.insertCell(0);
	oldData.align="left";
	oldData.innerHTML=document.getElementById("tt").innerHTML;
	
	cell=row.insertCell(1);
	cell.align="right";
	cell.innerHTML="<span id='showHideAdsPaneButton' class='showHideButton' title='Show Ads Pane' onclick='showHideAdsPane()' onmouseover='this.style.color=\"#FF6600\"' onmouseout='this.style.color=\"#003399\"'>&lt;&lt;</span>";

	document.getElementById("tt").innerHTML="";
	document.getElementById("tt").appendChild(content);
}

	

//////////////// replacing the beta logo with a normal one.
//////////////// the code is commented by default, remove the comment characters to enable it.

/*
var gLogos=document.getElementsByTagName("img");

for(i=0;i<gLogos.length;i++)
{
	if(gLogos[i].src=="https://mail.google.com/mail/help/images/logo1.gif" || gLogos[i].src=="http://mail.google.com/mail/help/images/logo1.gif" || gLogos[i].src=="https://mail.google.com/mail/help/images/logo.gif" || gLogos[i].src=="http://mail.google.com/mail/help/images/logo.gif")
		gLogos[i].src="http://i58.photobucket.com/albums/g254/illiterate_retard/logo1.gif";
}
*/