// Gmail Filter Assistant
// Copyright (c) 2007, Ming Zhang (kfkming@gmail.com)
// Released under the GPL license
// http://www.gnu.org/copyleft/gpl.html
// GUID: {bffc3178-2849-4727-a62c-866b8ec0523d}
// --------------------------------------------------------------------
//
// This is a Greasemonkey user script.
//
// To install, you need Greasemonkey: http://greasemonkey.mozdev.org/
// Then restart Firefox and revisit this script.
// Under Tools, there will be a new menu item to "Install User Script".
// Accept the default configuration and install.
//
// To uninstall, go to Tools/Manage User Scripts,
// select "Gmail Filter Assistant", and click Uninstall.
//
// --------------------------------------------------------------------
// ==UserScript==
// @name          Gmail Filter Assistant
// @description   Help to manage the Gmail filters more efficiently
// @source        http://userscripts.org/scripts/show/7997
// @identifier    http://userscripts.org/scripts/source/7997.user.js
// @author        Ming (Amos) Zhang
// @date          2007-03-17
// @namespace     http://www.amoszhang.com/GmailFilterAssistant
// @include       https://mail.google.com/*
// @include       http://mail.google.com/*
// ==/UserScript==
//

const Version = 0.16;        // the ';' at the end is necessary
const SCRIPT_SHOW_URL	= 'http://userscripts.org/scripts/show/7997';
const NUM_FILTER_ITEMS	= 13;

var DEBUG				= false;
var FILTER_REF_URL		= '?&view=pr&pnl=f';
var FILTER_SET_URL		= '?';

const FILTERASST_STYLES =
	"table._gfa_ {"+
	"  width: 100%;"+
	"  border-width: 3;"+
	"  border-style: solid;" +
	"  border-color:#FAD163;" +
	"  background: #FFF7D7;"+
	"  cellspacing: 0px;"+
	"  cellpadding: 0px;"+
	"}"+
	"td._gfa_label {" +
	"  font-weight: bold;" +
	"  text-align: right;" +
	"  vertical-align: middle;" +
	"  padding-top: 4px;" +
	"  white-space: nowrap;"+
	"  font-family: arial,sans-serif;" +
	"  font-size: 80%;" +
	"}" +
	"span._gfa_navLink {" +
	"  background: #FAD163;"+
	"  border-color: #FAD163;"+
	"  border-width: 3;"+
	"  border-style: solid;" +
	"  font-weight: bold;" +
	"  text-align: middle;" +
	"  vertical-align: bottom;" +
	"  padding-top: 2px;" +
	"  padding-left: 4px;" +
	"  padding-bottom: 2px;" +
	"  padding-right: 4px;" +
	"  font-family: arial,sans-serif;" +
	"  font-size: 80%;" +
	"  white-space: nowrap;"+
	"  cursor: pointer;"+
	"  float: right;"+
	"  -moz-border-radius-topleft: 4px;"+
	"  -moz-border-radius-topright: 4px;"+
	"}" +
	"input._gfa_inputbox {" +
	"  font-weight: normal;" +
	"  text-align: left;" +
	"  vertical-align: middle;" +
	"  padding-top: 4px;" +
	"  width : 100%;"+
	"  font-family: arial,sans-serif;" +
	"  font-size: 80%;" +
	"}" +
	"span.hovereffect:hover{background-color:#d0dbeb;}";

	const RSC_LANG={
	    'en'    :{
				title: "Filter Assistant",
				loading:"Loading...",
				running:'Running...',
				createfilter:"Create Filter",
				newversion:"New version of Gmail Filter Assistant available, install it ",
				here:"here",
				from: "From:",
				to: "To:",
				subject:"Subject:",
				hasword:"Hasword:",
				doesnthave:"Doesn't have:",
				hasattachment:"Has attachment:",
				skipinbox:"Skip the inbox(Archive it)",
				starit:"Star it",
				applylabel:"Apply the label",
				forward:"Forward it to",
				deleteit:"Delete it",
				applytoexistingconvs:"Apply the filter to existing conversations",
				moreactions:"More actions...",
				newlabel:"New label...",
				backup:"Backup filter&label",
				restore:"Restore filter&label",
				consolidate:"Consolidate filters",
				hidenavtag:'Hide the navigation tag',
				popuplabel:'Your filter & label data',
				close:'Close',
				cancel:'Cancel',
				readingfilterlabeldataerror:"Reading filter and label data error, please try again later",
				popuptitlebackup:'Javascript doesn\'t have the capability to write disk file, please copy/paste the content in the textbox to a .txt file, and keep this file in a safe place.',
				popuptitlerestore:'Please copy/paste Filter & Label data from where you saved them to the text box below and click "Close"',
				popuprestorewarning:'WARNING!!\n\Restoring filter data will overwrite existing filters and may take several seconds to several minutes, depending on your connection speed. \n\nAre you sure you want to continue?',
				inputlabeltitle:'Please input the label name (maximal length 100):',
				failtoretrieveresult:'Fail to retrieve the result, the action may not be completed',
				emptycriteriawarning:'Warning: "From", "To", "Subject", "Hasword" and "Doesn\'t have" are all empty, are you sure you want to proceed?',
				selectatleastoneaction:'Please select at least one action',
				selectalabelorcreateone:'Please select a label or create a new one',
				itemintrashwarning:'Warning: Items in the Trash are not displayed in label views or the starred view.\nDo you still wish to create the filter?',
				foundduplicatefilterwarning:'Found a filter having the same criteria, overwrite it?',
				},
	'zh-CN'		:{
				title: "&#36807;&#28388;&#22120;&#21161;&#25163;",
				loading:"&#36733;&#20837;&#20013;...",
				running:"&#27491;&#22312;&#36816;&#34892;...",
				createfilter:"&#21019;&#24314;&#36807;&#28388;&#22120;",
				newversion:"&#21457;&#29616;&#26032;&#29256;&#26412;&#30340; Gmail Filter Assistant, &#23433;&#35013;&#35831;&#28857;",
				here:"&#36825;&#37324;",
				from: "&#26469;&#33258;:",
				to: "&#21457;&#24448;:",
				subject:"&#26631;&#39064;:",
				hasword:"&#21547;&#26377;:",
				doesnthave:"&#27809;&#26377;:",
				hasattachment:"&#24102;&#38468;&#20214;:",
				skipinbox:"&#36339;&#36807;&#25910;&#20214;&#31665;(&#30452;&#25509;&#23384;&#26723;)",
				starit:"&#26631;&#26143;",
				applylabel:"&#26631;&#35760;&#20026;",
				forward:"&#36716;&#21457;&#33267;",
				deleteit:"&#21024;&#38500;",
				applytoexistingconvs:"&#23558;&#26412;&#36807;&#28388;&#22120;&#20316;&#29992;&#20110;&#24050;&#26377;&#23545;&#35805;",
				moreactions:"&#20854;&#20182;&#25805;&#20316;...",
				newlabel:"&#26032;&#24314;&#26631;&#31614;...",
				backup:"&#22791;&#20221;&#36807;&#28388;&#22120;&#21450;&#26631;&#31614;",
				restore:"&#24674;&#22797;&#36807;&#28388;&#22120;&#21450;&#26631;&#31614;",
				consolidate:"&#25972;&#21512;&#36807;&#28388;&#22120;",
				hidenavtag:'&#38544;&#34255;&#23548;&#33322;&#26631;&#31614;',
				popuplabel:'&#24744;&#30340;&#36807;&#28388;&#22120;&#21450;&#26631;&#31614;&#25968;&#25454;',
				close:'&#20851;&#38381;',
				cancel:'&#21462;&#28040;',
				readingfilterlabeldataerror:"&#35835;&#21462;&#36807;&#28388;&#22120;&#21450;&#26631;&#31614;&#25968;&#25454;&#36807;&#31243;&#20013;&#21457;&#29983;&#38169;&#35823;&#65292;&#35831;&#36831;&#20123;&#26102;&#20505;&#20877;&#35797;",
				popuptitlebackup:"Javascript &#26080;&#27861;&#35835;&#20889;&#30913;&#30424;&#25991;&#20214;&#65292;&#35831;&#23558;&#25991;&#26412;&#26694;&#20869;&#30340;&#25968;&#25454;&#25335;&#36125;/&#31896;&#36148;&#33267;&#19968;&#20010;&#25991;&#26412;&#25991;&#20214;&#24182;&#22949;&#21892;&#20445;&#23384;",
				popuptitlerestore:"&#35831;&#23558;&#20445;&#23384;&#30340;&#36807;&#28388;&#22120;&#21450;&#26631;&#31614;&#25968;&#25454;&#25335;&#36125;/&#31896;&#36148;&#33267;&#25991;&#26412;&#26694;&#28982;&#21518;&#28857;&#20987;&#8220;&#20851;&#38381;&#8221;",
				popuprestorewarning:"&#35686;&#21578;&#65281;&#24674;&#22797;&#25805;&#20316;&#23558;&#35206;&#30422;&#24050;&#26377;&#30340;&#36807;&#28388;&#22120;&#21450;&#26631;&#31614;&#25968;&#25454;&#65281;&#32780;&#19988;&#26681;&#25454;&#24744;&#30340;&#32593;&#32476;&#36895;&#24230;&#65292;&#25972;&#20010;&#36807;&#31243;&#21487;&#33021;&#25345;&#32493;&#20960;&#31186;&#38047;&#33267;&#20960;&#20998;&#38047;&#19981;&#31561;&#12290;\n\n&#30830;&#23450;&#35201;&#36827;&#34892;&#24674;&#22797;&#25805;&#20316;&#20040;&#65311;",
				inputlabeltitle:"&#35831;&#36755;&#20837;&#26631;&#31614;&#21517;&#65288;&#26368;&#38271;100&#23383;&#31526;&#65289;:",
				failtoretrieveresult:"&#35835;&#21462;&#32467;&#26524;&#22833;&#36133;&#65292;&#27492;&#39033;&#25805;&#20316;&#21487;&#33021;&#26410;&#39034;&#21033;&#23436;&#25104;",
				emptycriteriawarning:"&#35831;&#22635;&#20889;&#25628;&#32034;&#26465;&#20214;",
				selectatleastoneaction:"&#35831;&#36873;&#25321;&#33267;&#23569;&#19968;&#39033;&#25805;&#20316;",
				selectalabelorcreateone:"&#35831;&#36873;&#25321;&#19968;&#20010;&#26631;&#31614;&#25110;&#21019;&#24314;&#19968;&#20010;&#26032;&#26631;&#31614;",
				itemintrashwarning:"&#35686;&#21578;&#65306;&#26631;&#31614;&#35270;&#22270;&#25110;&#24050;&#21152;&#27880;&#26143;&#26631;&#30340;&#37038;&#20214;&#35270;&#22270;&#20013;&#19981;&#26174;&#31034;&#24050;&#21024;&#38500;&#37038;&#20214;&#20013;&#30340;&#20869;&#23481;&#12290;\n &#26159;&#21542;&#20173;&#35201;&#21019;&#24314;&#36807;&#28388;&#22120;&#65311;",
				foundduplicatefilterwarning:"&#21457;&#29616;&#19968;&#20010;&#24050;&#26377;&#36807;&#28388;&#22120;&#21547;&#26377;&#30456;&#21516;&#30340;&#25628;&#32034;&#26465;&#20214;&#65292;&#26159;&#21542;&#35206;&#30422;&#65311;",
			},
    'de'    :{
				title: "Filter Assistent",
				loading:"Lade...",
				running:'L&#228;uft...',
				createfilter:"Filter erstellen",
				newversion:"Eine neue Version von Gmail Filter Assistant ist verf&#252;gbar, installieren Sie es von",
				here:"hier",
				from: "Von:",
				to: "An:", subject:"Betreff:",
				hasword:"Mit diesen Worten:",
				doesnthave:"Ohne:",
				hasattachment:"Mit Anhang",
				skipinbox:"Posteingang &#252;berspringen (Archivieren)",
				starit:"Markierung hinzuf&#252;gen", applylabel:"Label anwenden",
				forward:"Weiterleiten an",
				deleteit:"L&#246;schen",
				applytoexistingconvs:"Filter auf existierende Konversationen anwenden",
				moreactions:"Weitere Aktionen...",
				newlabel:"Neues Label...",
				backup:"Filter&Label sichern",
				restore:"Filter&Label wiederherstellen",
				consolidate:"Filter konsolidieren",
				hidenavtag:'Navigationslink verstecken',
				popuplabel:'Ihre Filter & Label Daten',
				close:'Schlie&#223;en',
				cancel:'Abbrechen',
				readingfilterlabeldataerror:"Fehler beim lesen der Filter und Label Daten. Bitte sp&#228;ter noch einmal versuchen",
				popuptitlebackup:'Javascript kann nicht auf die Festplatte schreiben. Bitte den Inhalt der Textbox in eine Text-Datei sichern.',
				popuptitlerestore:'Bitte kopieren (kopieren/einf&#252;gen) Sie die Filter & Label Daten aus Ihrer Sicherung in die Textbox unten und klicken Sie "Schlie&#233;en"',
				popuprestorewarning:'WARNUNG!! Wiederherstellen der Filterdaten wird existierende Filter &#252;berschreiben und kann (abh&#228;ngig von Iherer Verbindungsgeschwindigkeit) mehrere Minuten dauern. Sind Sie sicher, dass sie fortfahren wollen?',
				inputlabeltitle:'Bitte den neuen Label-Namen eingeben (maximal 100 Zeichen):',
				failtoretrieveresult:'Fehler das Ergebnis zu empfangen. Die aktion konnte evtl. nicht durchgef&#252;hrt werden',
				emptycriteriawarning:'Warnung: "Von", "An", "Betreff", "Mit diesen Worten" und "Ohne" sind alle leer. Sind Sie sicher, dass sie weitermachen wollen?',
				selectatleastoneaction:'Bitte w&#228;hlen Sie mindestens eine Aktion',
				selectalabelorcreateone:'Bitte w&#228;hlen Sie ein Label oder erstellen Sie ein neues',
				itemintrashwarning:'Warnung: Dinge im Papierkorb, oder markierte Nachrichten werden nicht in der Markiert oder Papierporb-Anschicht angezeigt.\nWollen Sie den Filter immer noch erstellen?',
				foundduplicatefilterwarning:'Ein Filter mit gleichen Kriterien wurde gefunden. Soll er &#252;berschrieben werden?',
			},
		};

//=========================
// Definition of variables
//=========================
var baseURI=document.baseURI;

var LabelData, FilterData;
var titleBoxHeight;
var FilterAsstVisibile=false;
var DataReady=false;
var CurrentLabel="";
var CurrentFilterData=null;
var at, ik;
var rawFilterLabelData='';
var lang='en';    // default language: English
var base_url='';
var isHidingNavTag = false;
var msg_idx=-1;    // the index of the message on which GFA is called, only one GFA instance is allowed at any time
var FloatingMsg='';

//=======================
// Definition of objects
//=======================
function ParamParsingData()
{
    this.curr_pos = 0;
}

function Filter()
{
    this.id='';
    this.name='';

    this.from = '';
    this.to = '';
     this.subject = '';
    this.hasword = '';
    this.doesnthave = '';
    this.hasattachment = false;

    this.skipinbox = false;
    this.starit = false;
    this.applylabel = false;
    this.labeltoapply = '';
    this.forward = false;
    this.forwardto = '';
    this.deleteit = false;
    this.applyonexistingconvs = false;
}

var tmpdiv = newNode('div');

function myUnescape(s)
{
    s=s.replace(/\\u/g, '%u');

    tmpdiv.innerHTML = unescape(s);
    return tmpdiv.innerHTML;
}

function getWord(s)
{
    if (lang && RSC_LANG[lang] && RSC_LANG[lang][s])
        s= RSC_LANG[lang][s];
    else
    {
        debug('[getWord]: retrieve resource fail: RSC_LANG['+lang+']['+s+'] return null');
        s= RSC_LANG['en'][s];
        lang='en';
    }

    return myUnescape(s);
}

autoupdate();

// autoupdate function credit to Bjorn Rosell http://userscripts.org/scripts/show/7715
function autoupdate() {
	// get base URL
    base_url=baseURI.match(/http[s]{0,1}:\/\/mail.google.com\/a\/[^\.].*\.[a-z]{2,}\//);    // google App for Your Domain mailbox

    if (!base_url)    //not found
        base_url=baseURI.match(/http[s]{0,1}:\/\/mail.google.com\/mail\//);    // gmail

    if (base_url)
    {
        FILTER_REF_URL = base_url + FILTER_REF_URL;
        FILTER_SET_URL = base_url + FILTER_SET_URL;
    }
    else
        return;    // not a proper page

    // only check for updates one time a day
    var d = new Date();

    at = getDataItem(document.cookie,'GMAIL_AT=', ';');
    ik = GM_getValue('_gfa_'+base_url+'ik', null);
    lang = GM_getValue('_gfa_'+base_url+'lang', 'en');
    isHidingNavTag = GM_getValue('_gfa_'+base_url+'HideNavTag', false);

    var node=document.getElementsByTagName ('SCRIPT');

    for (var obj in node)
    {
        if (typeof node[obj]=='object' && node[obj].innerHTML.match(/D\(\[/))
        {
            var data=getReturnValue(node[obj].innerHTML, 'D([\"ud\"');

            if (data!=null)
            {
                ik=data[2];

                GM_setValue('_gfa_'+base_url+'ik', ik);

                debug('ik='+ik);

                try
                {
                    var t=getDataItem(myUnescape(data[8]), 'hl=', '&');

                    if (t==null)
                        lang='en';
                    else
                        lang=t;

                    debug('lang='+lang);
                    GM_setValue('_gfa_'+base_url+'lang', lang);
                }
                catch(e){};
            }
        }
    }

    if (getNode('msgs')==null || getNode('tt')==null || getNode('mh_0')==null)    // only add the link on mail content display page
    {
        debug('[autoupdate]: Not the msg display page. Leaving...');

        // the control of the script falls out to a new page, let's set a mark for recheck everything
        GM_setValue('_gfa_recheck',true);

        return 0;
    }

	window.setInterval(function()
		{
			drawFilterAsstBtn();
		}, 1000);

	GM_addStyle(FILTERASST_STYLES);

	if (GM_getValue('_gfa_lastcheck') == d.getDate()) {
        return;
    }

    // check for update
    GM_xmlhttpRequest({
        method:"GET",
        headers:{ 'Accept': 'text/plain'},
        url: SCRIPT_SHOW_URL,
        onload:function(result) {
            var data = result.responseText ;
            var ver = parseFloat(getDataItem(data, 'Gmail Filter Assistant v', ';'));    // get version number

            debug('The latest version=['+ver+'], and current version=['+Version+']');

            if ( ver > Version ) {        // current version is an old one
                FloatingMsg=getWord('newversion')+'<a href="'+SCRIPT_SHOW_URL+'" target="_blank">'+getWord('here')+'</a>'
            }

            // getting new version info successfully, set the lastcheck flag to prevent more than one checking every day.
            var d = new Date();
            GM_setValue('_gfa_lastcheck', d.getDate());
        }
    });
}

function getLabel_n_FilterData(callbackfunc, argument)
{
    if (typeof callbackfunc!='function')
    {
        debug('[getLabel_n_FilterData]: Invalid callback function. Leaving...');
        return;
    }

    if (DataReady)
    {
        callbackfunc(argument);
        debug('[getLabel_n_FilterData]: Data is ready, no need to read again. Leaving...');
        return;
    }

    debug('[getLabel_n_FilterData]: Entering...');

    var navfilter=null;

    if (msg_idx!=-1)
        navfilter=getNode('_gfa_navlink_'+msg_idx+'_text');

    if (navfilter) navfilter.innerHTML='<b>'+getWord('loading')+'</b>';

    GM_xmlhttpRequest({
        method:'GET',
        url: FILTER_REF_URL,
        onload: function(responseDetails) {

            if (navfilter) navfilter.innerHTML=getWord('title');

            debug('[getLabel_n_FilterData]: Reading label data....');

            var data;
            var status;

            status = responseDetails.status;
            data = responseDetails.responseText;

            rawFilterLabelData=data;

            //debug('Response Text='+data);

            if (status!=200)    // not OK
                return;

            LabelData = getReturnValue(data, 'D([\"cta\"');
            LabelData = LabelData[0];

            debug('[getLabel_n_FilterData]: LabelData='+LabelData.toString());

            debug('[getLabel_n_FilterData]: Reading filter data....');

            FilterData = null;
            FilterData = getReturnValue(data, 'D([\"fi\"');

            debug('[getLabel_n_FilterData]: FilterData='+FilterData.toString());

            FilterData = FilterData[0];

            if (!FilterData)
            {
                debug('[getLabel_n_FilterData]: FilterData='+FilterData.toString());
            }

            DataReady=true;


            debug('[getLabel_n_FilterData]: All data ready');

            if (CurrentFilterData!=null)    // recover the status before refreshing
            {
                if (CurrentLabel!="")
                    CurrentFilterData.labeltoapply=CurrentLabel;
            }

            if (CurrentFilterData!=null)    // recover the status before refreshing
            {
                restoreUserChanges(CurrentFilterData);
                CurrentFilterData=null;
            }

            callbackfunc(argument);

            debug('[getLabel_n_FilterData]: Leaving...');
        },
        onerror: function(responseDetails){
            if (navfilter) navfilter.innerHTML=getWord('title');

            debug('[getLabel_n_FilterData]: Leaving...');
        }
    });


}

function drawFilterAsstBtn()
{
    //debug("[drawFilterAssistantBtn]: Entering...");

    var msgs=getNode("msgs");

    var node, ws;
    var j=-1;

	ws = getNode('_gfa_ws');

    for (var i=0;;i++)
    {
        node=getNode('msg_'+i);

        if (!node)
		{
			break;
		}

        //debug('find message['+i+']');

        j=i+1;

        node=getNode('_cbt_'+j+'_l');

        if (!node)
		{
			if (ws && ws.getAttribute('idx')==i)
			{
				ws.parentNode.removeChild(ws);
			}

			continue;
		}

       // debug('find dropdown box for message['+i+']');

		if (getNode('_gfa_navlink_'+i))
		{
			//debug('nav link already exists. skip...');
			continue;
		}

        var link=newNode('TD');
        link.id='_gfa_navlink_'+i;
         link.className="cbum";
        link.setAttribute("style", "padding-top: 5px;visibility: visible !important;");
        link.innerHTML=    '<SPAN class="hovereffect"><SPAN class="cbut">&nbsp;<SPAN id="_gfa_navlink_'+i+'_text">Filter Assistant</SPAN>&nbsp;</SPAN></SPAN>';
        link.addEventListener('click', OnFilterAsstBtnClicked, false);
        link.style.cursor="pointer";

        node.parentNode.insertBefore(link, node.nextSibling);

        debug('insert GFA link');

        var separator=newNode('TD');
        separator.className='cbus';

        node.parentNode.insertBefore(separator, link.nextSibling);

        //debug('insert separator');
    }

	//debug("[drawFilterAssistantBtn]: Leaving...");
}

function OnFilterAsstBtnClicked(e)
{
    debug('[OnFilterAsstBtnClicked]: Entering...');

	var old_msg_idx=msg_idx;

    var s=this.id;

    debug("this.id="+this.id);

    if (!s || !s.match(/^_gfa_navlink_[a-zA-Z]*[0-9]+$/)) return;

    msg_idx= s.substr(13);

	if (old_msg_idx!=msg_idx)
	{
		var node=getNode('_gfa_ws');
		if (node) node.parentNode.removeChild(node);
	}
    getLabel_n_FilterData(drawFilterAsstWorkspace, (getNode('_gfa_ws_div')==null));

    debug('[OnFilterAsstBtnClicked]: Leaving...');
}

//=================================
// Draw Filter Assistant Workspace
//=================================
function createTitlebox()
{
	var titlebox=getNode('_gfa_ws');    // the whole workspace
    var msg=getNode('msg_'+msg_idx);

    if (!titlebox)	// create the titlebox if it's not there.
    {
		titlebox=newNode('table');
		titlebox.id='_gfa_ws';
		titlebox.setAttribute('idx',msg_idx);
		msg.insertBefore(titlebox, msg.firstChild.nextSibling);

		titlebox.setAttribute('cellspacing','0');
		titlebox.setAttribute('cellpadding','0');
		titlebox.setAttribute('style','width: 100%');
	}

	return titlebox;
}

function drawFilterAsstWorkspace(show_boxes)	// show_boxes: show the "criteria" and "action" boxes?
{
    debug('[drawFilterAsstWorkspace]: Entering... show_boxes = '+show_boxes);

	var titlebox=createTitlebox();

	// check if the workspace has already been drawn
	var node=getNode('_gfa_ws_div');

	if (node)	// the workspace is there, hide it.
		node.parentNode.removeChild(node);

	debug('[drawFilterAsstWorkspace]: FloatingMsg = '+FloatingMsg);

    titlebox.innerHTML=
        '<tbody>'
	+ (FloatingMsg!=''?
			 ('<tr id="_gfa_FloatingMsg">'
    +            '<td class="cbln"><div class="mb">'
	+				'<div align=center style="padding-top:5px;padding-bottom:5px;"><span style="background: #FAD163;-moz-border-radius:15px;padding: 3px 10px 3px 10px;"><b>'+myUnescape(FloatingMsg)+'</b></span></div></div>'
	+            '<td class="cbrn">'
	+		 '</tr>'):'')
    +    '</tbody>';

	if (FloatingMsg!='')
	{
		window.setTimeout(function(){
			var node=getNode('_gfa_FloatingMsg');

			if (node)
				node.parentNode.removeChild(node);

		}, 5000);	// delete the msg
	}

	FloatingMsg='';

	if (!show_boxes) return;

	node=newNode('tr');
	titlebox.firstChild.appendChild(node);

	node.innerHTML=
		'<td class="cbln"><div class="mb"><div id="_gfa_ws_div">'
	+	'<td class="cbrn">'

	var div=getNode('_gfa_ws_div');

    if (!div) return;

    var LabelsCombBox    = newNode('select');
    LabelsCombBox.id    = "cbBoxLabels";

    var i;

    var opList;

    for (i=0; i<LabelData.length;i++ )
    {
        opList            = newNode('option');
        opList.innerHTML      = LabelData[i][0];
        opList.addEventListener('click', checkApplyTheLabel, false);
        LabelsCombBox.appendChild (opList);
    }

    opList            = newNode('option');
    opList.id          = "opNewLabel"    // new label option
    opList.innerHTML  = getWord('newlabel');
    opList.addEventListener ('click', addLabel, false);

    if (LabelData.length==1)
        LabelsCombBox.value=opList.value;
    else
        LabelsCombBox.value=CurrentLabel;

    LabelsCombBox.appendChild(opList);

    var subject='', sender='', recver='';

    //
    // !!! FIXME !!!
    //
    // The way to get subject, sender and receiver is very unstable. if multi-emails exist
    // in the conversation, the receiver may not be captured.
    var node = getNode('tt');    // title

    // get subject
//	try
//	{
//		subject=node.firstChild.firstChild.innerHTML;
//	}catch(e)
//	{
//		GM_log('Error occured: Getting sender/recver fail. \n\nDetailed error msg:\n\n['+e.name+']:'+e.message);
//	}

    // get the sender's email:
    node = getNode('mh_'+msg_idx);

    try
    {
        if (node.firstChild.id=='mm')
        {
            // get sender's email
            node=node.firstChild;

            node=node.firstChild.firstChild.nextSibling.firstChild.nextSibling;
            sender = node.firstChild.id.substr(6);

            // get recver's email
            node=node.nextSibling.firstChild.firstChild.firstChild.firstChild.firstChild;

            if (node!=null && node.childNodes!=null)
                for (i=0;i<node.childNodes.length ;i++)
                {
                    var t=node.childNodes[i];

                    if (t.nodeName=='SPAN')
                    {
                        if (t.firstChild!=null && t.firstChild.id!=null && t.firstChild.id.length>6)    // remove _upro_
                            recver += t.firstChild.id.substr(6) + " OR ";
                    }
                }

            if (recver.length>0)
                recver = recver.substr(0, recver.length-4);
        }
    }catch(e)
    {
        GM_log('Error occurred: Getting sender/receiver fail. \n\nDetailed error msg:\n\n['+e.name+']:'+e.message);
    }


    // ======================= add "Characteristic" part =============================
    div.innerHTML=
        '<table class="_gfa_">'
    +        '<tbody>'
    +           '<tr>'
    +                '<td class="_gfa_label">'+getWord('from')
    +                '<td width=40%><input type="text" class="_gfa_inputbox" id="txtBoxFrom" value="'+sender+'">'
    +                '<td class="_gfa_label" width=10%>'
    +                '<td class="_gfa_label">'+getWord('hasword')
    +                '<td width=40%><input class="_gfa_inputbox" type="text" id="txtBoxHasWord">'
    +            '</tr>'
    +            '<tr>'
    +                '<td class="_gfa_label">'+getWord('to')
    +                '<td width=40%><input class="_gfa_inputbox" type="text" id="txtBoxTo" style="width:100%;" value="'+recver+'">'
    +                '<td class="_gfa_label" width=10%>'
    +                '<td class="_gfa_label">'+getWord('doesnthave')
    +                '<td width=40%><input class="_gfa_inputbox" type="text" id="txtBoxDoesntHave">'
    +            '</tr>'
    +            '<tr>'
    +                '<td class="_gfa_label">'+getWord('subject')
    +                '<td width=40%><input class="_gfa_inputbox" type="text" id="txtBoxSubject" value="'+subject+'">'
    +                '<td class="_gfa_label" width=10%>'
    +                '<td>'
    +                '<td class="_gfa_label" style="text-align:left" width=40%><input type="checkbox" id="chkBoxHasAttachment">'+getWord('hasattachment')
    +            '</tr>'
    +        '</tbody>'
    +    '</table>'
    +    '<table class="_gfa_" style="border-top:0px;">'
    +        '<tbody>'
    +            '<tr>'
    +                '<td width=30%>'
    +                '<td class="_gfa_label" style="text-align:left" width=40%><input type="checkbox" id="chkBoxSkipInbox">'+getWord('skipinbox')
    +                '<td class="_gfa_label" width=30% colspan=2>'
    +                '    <select id="selFilterMoreOptions">'
    +                '        <option style="color: #808080;"        >'+getWord('moreactions')+'</option>'
    +                '        <option    style="color: #808080;"        >--------------------</option>'
    +                '        <option id="opBackupFilters"        >'+getWord('backup')+'</option>'
    +                '        <option id="opRestoreFilters"        >'+getWord('restore')+'</option>'
    +                '        <option id="opConsolidateFilters" style="color: #808080;"    >'+getWord('consolidate')+'</option>'
    +                '    </select>'
    +            '</tr>'
    +            '<tr>'
    +                '<td width=30%>'
    +                '<td class="_gfa_label" style="text-align:left" width=40%><input type="checkbox" id="chkBoxStarIt">'+getWord('starit')
    +                '<td width=30%>'
    +            '</tr>'
    +            '<tr>'
    +                '<td width=30%>'
    +                '<td class="_gfa_label" style="text-align:left" width=40%><input type="checkbox" id="chkBoxApplyLabel">'+getWord('applylabel')
    +                '<td width=30%>'
    +            '</tr>'
    +            '<tr>'
    +                '<td width=30%>'
    +                '<td class="_gfa_label" style="text-align:left" width=40%><input type="checkbox" id="chkBoxForwardTo">'+getWord('forward')+'<input type="text" id="txtBoxForwardTo">'
    +                '<td width=30%>'
    +            '</tr>'
    +            '<tr>'
    +                '<td width=30%>'
    +                '<td class="_gfa_label" style="text-align:left" width=40%><input type="checkbox" id="chkBoxDeleteIt">'+getWord('deleteit')
    +                '<td width=30%>'
    +            '</tr>'
    +            '<tr>'
    +                '<td width=30%>'
    +                '<td class="_gfa_label" style="text-align:left" width=40%><input type="checkbox" id="chkBoxApplyToExistingConvs">'+getWord('applytoexistingconvs')
    +                '<td width=15%><span id="_gfa_navlink_lblCancel'+msg_idx+'" class="_gfa_navLink" style="-moz-border-radius:8px;"><b>'+getWord('cancel')+'</b></span>'
    +                '<td width=15%><span id="lblCreateFilter" class="_gfa_navLink" style="-moz-border-radius:8px;"><b>'+getWord('createfilter')+'</b></span>'
    +            '</tr>'
    +        '</tbody>'
    +    '</table>'
    +'</td>';

    getNode('opBackupFilters').addEventListener('click', onBackupFilters, false);
    getNode('opRestoreFilters').addEventListener('click', onRestoreFilters, false);
    getNode('opConsolidateFilters').addEventListener('click', onConsolidateFilters, false);

	node = getNode('lblCreateFilter');
    node.addEventListener('click', onCreateFilter, false);

    node = getNode('_gfa_navlink_lblCancel'+msg_idx);
    node.addEventListener('click', OnFilterAsstBtnClicked, false);

    node = getNode('chkBoxApplyLabel');
    node.parentNode.appendChild(LabelsCombBox);

    debug('[drawFilterAsstWorkspace]: Leaving...');
}

function checkApplyTheLabel()
{
    try{getNode('chkBoxApplyLabel').checked=true;}catch(e){};
}

//=======================
// Draw the popup window
//=======================
function drawPopup(title, callback)
{
    if (callback==null || typeof callback!='function') return;

    var popup = newNode('div');
    popup.id='_gfa_popup';
    popup.setAttribute("style", "z-index:1102;position:fixed;overflow:auto;width:470px;left:20px;top:20px;background-color:#FFF7D7;padding:15px;border:2px solid #FAD163");
    document.body.appendChild(popup);

    if (typeof title!='string' || title==null) title='';

    popup.innerHTML=
        ''+title+'<br><br>'
    +    '<b>'+getWord('popuplabel')+':<b><br>'
    +    '<textarea id="txtBoxFilters" style="width:465px; height:250px;">'
    +    '</textarea><br><br>'
    +    '<button id="btnClosePopup">'+getWord('close')+'</button>';

    getNode('btnClosePopup').addEventListener('click', callback, false);
}

//===========================
// Close popup event handler
//===========================
function onClosePopup()
{
    var node=getNode('_gfa_popup');
    if (node) node.parentNode.removeChild(node);
}

//=============================
// Backup filter event handler
//=============================
function onBackupFilters()
{
    if (rawFilterLabelData=='')
    {
        alert(getWord('readingfilterlabeldataerror'));
        return;
    }

    drawPopup(    getWord('popuptitlebackup'),
                onClosePopup);

    var node=getNode('txtBoxFilters');

    var s='';
    var header = 'D([\"fi\"';

    s=s+header+getRawData(rawFilterLabelData, header)+');';

    s+='\n\n';
    header = 'D([\"cta\"';
    s=s+header+getRawData(rawFilterLabelData, header)+');';

	node.innerHTML=s;
}

//=============================
// Restore filter event handler
//=============================
function onRestoreFilters()
{
    drawPopup(getWord('popuptitlerestore'),
                RestoreFilters );
}

function RestoreFilters()
{
    var node=getNode('txtBoxFilters');
    var s='';

    if (node)
        s = node.value;

    onClosePopup();

    if (s=='')
    {
        return;
    }

    var fd, ld;    //filter data, label data

    f=getReturnValue(s, 'D(["fi"');
    l=getReturnValue(s, 'D(["cta"');

    var node=getNode('_gfa_navlink_'+msg_idx);
    if (node) node.innerHTML=' <b>'+getWord('running')+'</b>';

    if (f)
    {
        if (!confirm(getWord('popuprestorewarning')))
        {
            node.innerHTML=getWord('title');
            return;
        }

        var nHasInvalidData=0;
        var nEdit=0, nAdd=0;

        for (var i=0;i<f.length;i++)
        {
            // check data validity
            if (f[i].length<3 || f[i][2].length!=NUM_FILTER_ITEMS ||
                !isBoolValue(f[i][2][5]) ||    // Has attachment
                !isBoolValue(f[i][2][6]) ||    // Skip Inbox
                !isBoolValue(f[i][2][7]) ||    // Star It
                !isBoolValue(f[i][2][8]) ||    // Apply label
                !isBoolValue(f[i][2][10]) ||    // Forward it
                !isBoolValue(f[i][2][12]) )    // Delete it
            {
                nHasInvalidData++;
                continue;
            }
            else
            {
                // pass the previous test
                if ((f[i][2][8]=='true' && f[i][2][9]=='') ||        // try to apply a label, but given an empty string as label name
                    (f[i][2][10]=='true' && f[i][2][11].match(/^.+@[^\.].*\.[a-z]{2,}$/)==null) )    //try to forward the email but given an invalid email address
                {
                    HasInvalidData++;
                    continue;
                }
            }

            // OK, now we think the data is valid, try to restore the filter data

            // check if the filter is already in the system
            var fd = new Filter();

            fd.id = '';
            fd.name = '';
            fd.from                    = f[i][2][0];
            fd.to                    = f[i][2][1];
            fd.subject                = f[i][2][2];
            fd.hasword                = f[i][2][3];
            fd.doesnthave            = f[i][2][4];
            fd.hasattachment        = f[i][2][5];

            fd.skipinbox            = f[i][2][6];
            fd.starit                = f[i][2][7];
            fd.applylabel            = f[i][2][8];
            fd.labeltoapply            = f[i][2][9];
            fd.forward                = f[i][2][10];
            fd.forwardto            = f[i][2][11];
            fd.deleteit                = f[i][2][12];

            var k=hasFilter(fd);

            if (k>=0)    // found a filter having the same criteria
            {
                // check if actions are same, too
                var same=true;

                for (var j=6;j<13;j++)
                    if (same)
                        same = same && (f[i][2][j]!=FilterData[k][2][j]);
                    else
                        break;

                // the two filters are the same, skip it
                if (same) continue;

                fd.id = FilterData[k][0];    // store the ID
                 fd.name = FilterData[k][1];    // store the name

                var old_fd=clone(fd);

                old_fd.skipinbox    = FilterData[k][2][6];
                old_fd.starit        = FilterData[k][2][7];
                old_fd.applylabel    = FilterData[k][2][8];
                old_fd.labeltoapply    = FilterData[k][2][9];
                old_fd.forward        = FilterData[k][2][10];
                old_fd.forwardto    = FilterData[k][2][11];
                old_fd.deleteit        = FilterData[k][2][12];

                nEdit++;

                editFilter(old_fd, fd, i==(f.length-1));
            }
            else
            {
                nAdd++;
                addFilter(fd,i==(f.length-1));
            }
        }

        //if (nHasInvalidData + nEdit + nAdd > 0)
        //    alert('Restoring filter data'Some filter data is invalid and was ignored in the restoring procedure');
    }


}

function isBoolValue(v)
{
    return (v=='true' || v=='false' || v=='');
}

//==================================
// Consolidate filter event handler
//==================================
function onConsolidateFilters()
{
    // in progress
}

//==================
// Add Label
//==================
function addLabel(refresh)
{
    debug('[addLabel]: Entering...');

    CurrentFilterData = getUserChanges();

    CurrentLabel=prompt(getWord('inputlabeltitle'),'');

    if (CurrentLabel.length<0)
    {
        debug('[addLabel]: Empty label. Leaving...');
        return;
    }
    else if (CurrentLabel.length>100)
        CurrentLabel=CurrentLabel.substr(0,100);

    debug("CurrentLabel="+CurrentLabel);

    var postdata='act=cc_'+encodeURIComponent(CurrentLabel)+'&at='+at;

    var add_lbl_url=base_url+'?&ik=&view=up';
    var referer=base_url+'?&view=pr&pnl=l&ik='+ik+'&zx='+UniqueURL();

    GM_xmlhttpRequest({
        method:'POST',
        url: add_lbl_url,
        headers:{
            'Referer': referer,
            'Content-type' : 'application/x-www-form-urlencoded'
            },
        data : postdata,
        onload: function(responseDetails) {


            debug(responseDetails.responseText);

            if (refresh)
            {
                var ret=getReturnValue( responseDetails.responseText, 'D([\"ar\"');

                if (ret!=null)
                {
                    debug('< D(["ar" > returns : '+ret.toString());
                }

                if(ret && ret[1])
                {
                    FloatingMsg = ret[1];
                    CurrentFilterData.applylabel=true;
                }
                else
                    FloatingMsg = getWord('failtoretrieveresult');

                DataReady=false;

                getLabel_n_FilterData(drawFilterAsstWorkspace, true);
            }

            debug('[addLabel]: Leaving...');

        },
        onerror: function(responseDetails){
            GM_log("ERROR: "+responseDetailsText);
            debug('[addLabel]: Leaving...');
        }
    });
}

//==========================================
// Save user change to the workspace
//==========================================
function getUserChanges()
{
    f=new Filter();

    f.id = '';
    f.name = '';
    f.from = getNode('txtBoxFrom').value;
    f.to=getNode('txtBoxTo').value;
    f.subject=getNode('txtBoxSubject').value;
    f.hasword=getNode('txtBoxHasWord').value;
    f.doesnthave=getNode ('txtBoxDoesntHave').value;
    f.hasattachment=getNode('chkBoxHasAttachment').checked;

    f.skipinbox=getNode('chkBoxSkipInbox').checked;
    f.starit=getNode('chkBoxStarIt').checked;
    f.applylabel=getNode('chkBoxApplyLabel').checked;
    f.labeltoapply=getNode('cbBoxLabels').value;
    f.forward=getNode('chkBoxForwardTo').checked;
    f.forwardto=getNode('txtBoxForwardTo').value;
    f.deleteit=getNode('chkBoxDeleteIt').checked;
    f.applyonexistingconvs=getNode('chkBoxApplyToExistingConvs').checked;

    return f;
}

//==========================================
// Restore the user change to the workspace
//==========================================
function restoreUserChanges(f)
{
    try
    {
        getNode('txtBoxFrom').value=f.from;
        getNode('txtBoxTo').value= f.to;
        getNode('txtBoxSubject').value=f.subject;
        getNode('txtBoxHasWord').value=f.hasword;
        getNode('txtBoxDoesntHave').value=f.doesnthave;
        getNode('chkBoxHasAttachment').checked=f.hasattachment;

        getNode('chkBoxSkipInbox').checked=f.skipinbox;
        getNode('chkBoxStarIt').checked=f.starit;
        getNode('chkBoxApplyLabel').checked= f.applylabel;
        getNode('cbBoxLabels').value=f.labeltoapply;
        getNode('chkBoxForwardTo').checked=f.forward;
        getNode('txtBoxForwardTo').value=f.forwardto;
        getNode('chkBoxDeleteIt').checked= f.deleteit;
        getNode('chkBoxApplyToExistingConvs').checked=f.applyonexistingconvs;
    }catch(e)
    {
        GM_log('Error occured: Setting current filter data failed. \n\nDetailed error msg:\n\n['+e.name+']:'+e.message);
    }
}

function hasFilter(fd)
{
    if (FilterData!=null)    //check existing filters to see if the rule has already been there
    {
        var len=FilterData.length;

        for (var i=0;i<len;i++)
        {
            if (fd.from            !=FilterData[i][2][0] ||
                fd.to            !=FilterData[i][2][1] ||
                fd.subject        !=FilterData[i][2][2] ||
                fd.hasword        !=FilterData[i][2][3] ||
                fd.doesnthave    !=FilterData[i][2][4] ||
                fd.hasattachment.toString()!=FilterData[i][2][5]) continue;

            return i;
        }
    }

    return -1;
}

//=================================
// Create new filter event handler
//=================================
function onCreateFilter()
{
    debug('[onCreateFilter]: Entering...');

    /*
    FilterData Format:

    +---0    ID
        1    Name
        2    Data
            |
            +---0    From
                1    To
                2    Subject
                3    Has word
                4    Doesn't have
                5    Has attachment    (T/F)

                6    Skip Inbox        (T/F)
                7    Star it            (T/F)
                8    Apply label        (T/F)
                9    Label to apply    (the label name)
                10    Forward it        (T/F)
                11    Forward to        (email)
                12    Delete it        (T/F)
    */

    var fd;

    try
    {
        fd=getUserChanges();
    }catch(e)
    {
        GM_log('Error occured: Getting necessary values failed. \n\nDetailed error msg:\n\n['+e.name+']:'+e.message);
        return;
    }

    if (fd.from == "" && fd.to == "" && fd.subject == "" && fd.hasword == "" && fd.doesnthave == "")
    {
        alert(getWord('emptycriteriawarning'));

        debug('[onCreateFilter]: Creating filter canceled. Leaving...');
        return;
    }

    if (!( fd.skipinbox||fd.starit||fd.applylabel||fd.forward||fd.deleteit))    // no action
    {
        alert(getWord('selectatleastoneaction'));

        debug('[onCreateFilter]: No action selected. Leaving...');

        return;
    }

    if (fd.applylabel && (fd.labeltoapply=="" || fd.labeltoapply==getWord('newlabel')) )
    {
        alert(getWord('selectalabelorcreateone'));

        debug('[onCreateFilter]: No label selected. Leaving...');

        return;
    }

    if (fd.deleteit)
    {
        if (fd.starit || fd.applylabel)
        {
            if (!confirm(getWord('itemintrashwarning')))
            {
                debug('[onCreateFilter]: Creating filter canceled. Leaving...');
                return;
            }
        }
    }

    debug("[onCreateFilter]: FilterData="+FilterData.toString());

    var i=hasFilter(fd);

    if (i>=0)    // found a filter having the same criteria
    {
        if (!confirm(getWord('foundduplicatefilterwarning')))
        {
            debug('[onCreateFilter]: Overwriting filter canceled. Leaving...');
            return;
        }

        fd.id = FilterData[i][0];    // store the ID
        fd.name = FilterData[i][1];    // store the name

        var old_fd=clone(fd);

        old_fd.skipinbox    = FilterData[i][2][6];
        old_fd.starit        = FilterData[i][2][7];
        old_fd.applylabel    = FilterData[i][2][8];
        old_fd.labeltoapply    = FilterData[i][2][9];
        old_fd.forward        = FilterData[i][2][10];
        old_fd.forwardto    = FilterData[i][2][11];
        old_fd.deleteit        = FilterData[i][2][12];

        editFilter(old_fd, fd, true);

        /* Future work:

            1. Combine the two filters with same criteria (edit/overwrite);
            2. group/consolidate filters that target to the same label.
        */

    }
    else
        addFilter(fd, true);
}

//==================
// Add Filter
//==================
function addFilter(fd, refresh)
{
    // ==== add the filter ====
    // The following code is based on :
    //        Gmail Agent API
    //        Copyright (C) 2005 Johnvey Hwang, Eric Larson
    //         http://sourceforge.net/projects/gmail-api/

    // Generate the URL
    var add_flt_url = FILTER_SET_URL
        + 'ik=' + ik
        + '&view=pr'
        + '&pnl=f'
        + '&at='+ at
        + '&act=cf'  // action = create filter
        + '&search=cf'
        + '&cf_t=cf'
        + '&cf1_from=' + encodeURIComponent( fd.from)
        + '&cf1_to=' + encodeURIComponent(fd.to)
        + '&cf1_subj=' + encodeURIComponent(fd.subject)
        + '&cf1_has=' + encodeURIComponent( fd.hasword)
        + '&cf1_hasnot=' + encodeURIComponent(fd.doesnthave)
        + '&cf1_attach=' + encodeURIComponent(fd.hasattachment)
        + '&cf2_ar=' + encodeURIComponent( fd.skipinbox)
        + '&cf2_st=' + encodeURIComponent(fd.starit)
        + '&cf2_cat=' + encodeURIComponent(fd.applylabel)
        + '&cf2_sel=' + encodeURIComponent(fd.labeltoapply )
        + '&cf2_emc=' + encodeURIComponent(fd.forward)
        + '&cf2_email=' + encodeURIComponent(fd.forwardto)
        + '&cf2_tr=' + encodeURIComponent(fd.deleteit)
        + '&irf='  + encodeURIComponent( fd.applyonexistingconvs)    //whether to apply the filter to all existing mails
        + '&zx=' + UniqueURL();

    // Generate referrer
    var referer = FILTER_SET_URL
        + 'ik=' + ik
        + '&search=cf'
        + '&view=tl'
        + '&start=0'
        + '&cf_f=cf1'
        + '&cf_t=cf2'
        + '&cf1_from=' + encodeURIComponent( fd.from)
        + '&cf1_to=' + encodeURIComponent(fd.to)
        + '&cf1_subj=' + encodeURIComponent(fd.subject)
        + '&cf1_has=' + encodeURIComponent( fd.hasword)
        + '&cf1_hasnot=' + encodeURIComponent(fd.doesnthave)
        + '&cf1_attach=' + encodeURIComponent(fd.hasattachment)
        + '&zx=' + UniqueURL();

    var node=getNode('lblCreateFilter');
    if (refresh)
    {
        node.innerHTML = '<b>'+getWord('running')+'</b>';
        node.removeEventListener('click', onCreateFilter, false);
    }

    GM_xmlhttpRequest({
        method:'GET',
        url: add_flt_url,
        headers:{'Referer': referer},
        onload: function(responseDetails) {

            debug( responseDetails.responseText);

            if (refresh)
            {
                var ret=getReturnValue(responseDetails.responseText, 'D([\"ar\"');

                if (ret!=null)
                {
                    debug('< D(["ar" > returns : '+ret.toString());
                }

                if(ret && ret[1])
                    FloatingMsg = ret[1];
                else
                    FloatingMsg = getWord('failtoretrieveresult');

				DataReady=false;
                getLabel_n_FilterData(drawFilterAsstWorkspace, false);

                node.innerHTML = '<b>'+getWord('createfilter')+'</b>';
            }

            debug('[addFilter]: Leaving...');

        },
        onerror: function(responseDetails){
            GM_log("ERROR: \nstatus="+responseDetails.status+"\nHeaders="+responseDetails.responseHeaders+"\nFeed data="+ responseDetails.responseText);
            debug('[addFilter]: Leaving...');
        }
    });
}

//==================
// Edit Filter
//==================
function editFilter(old_fd, new_fd, refresh)
{
    debug('[editFilter]: Entering...');

    // ==== add the filter ====
    // The following code is based on :
    //        Gmail Agent API
    //        Copyright (C) 2005 Johnvey Hwang, Eric Larson
    //        http://sourceforge.net/projects/gmail-api/

    // Generate the URL
    var add_flt_url = FILTER_SET_URL
        + 'ik=' + ik
        + '&view=pr'
        + '&pnl=f'
        + '&at='+ at
        + '&act=rf'  // action = refine filter
        + '&search=cf'
        + '&cf_t=rf'
        + '&cf1_from=' + encodeURIComponent(new_fd.from)
        + '&cf1_to=' + encodeURIComponent(new_fd.to)
        + '&cf1_subj=' + encodeURIComponent(new_fd.subject)
        + '&cf1_has=' + encodeURIComponent(new_fd.hasword)
        + '&cf1_hasnot=' + encodeURIComponent(new_fd.doesnthave)
        + '&cf1_attach=' + encodeURIComponent(new_fd.hasattachment)
        + '&cf2_ar=' + encodeURIComponent(new_fd.skipinbox)
        + '&cf2_st=' + encodeURIComponent(new_fd.starit)
        + '&cf2_cat=' + encodeURIComponent(new_fd.applylabel)
        + '&cf2_sel=' + encodeURIComponent(new_fd.labeltoapply)
        + '&cf2_emc=' + encodeURIComponent(new_fd.forward)
        + '&cf2_email=' + encodeURIComponent(new_fd.forwardto)
        + '&cf2_tr=' + encodeURIComponent(new_fd.deleteit)
        + '&ofid=' + encodeURIComponent(new_fd.id)
        + '&irf='  + encodeURIComponent(new_fd.applyonexistingconvs)    //whether to apply the filter to all existing mails
        + '&zx=' + UniqueURL();

    // Generate referrer
    var referer = FILTER_SET_URL
        + 'ik=' + ik
        + '&search=cf'
        + '&view=tl'
        + '&start=0'
        + '&cf_f=cf1'
        + '&cf_t=cf2'
        + '&cf1_from=' + encodeURIComponent(old_fd.from)
        + '&cf1_to=' + encodeURIComponent(old_fd.to)
        + '&cf1_subj=' + encodeURIComponent(old_fd.subject)
        + '&cf1_has=' + encodeURIComponent(old_fd.hasword)
        + '&cf1_hasnot=' + encodeURIComponent(old_fd.doesnthave)
        + '&cf1_attach=' + encodeURIComponent(old_fd.hasattachment)
        + '&cf2_ar=' + encodeURIComponent(old_fd.skipinbox)
        + '&cf2_st=' + encodeURIComponent(old_fd.starit)
        + '&cf2_cat=' + encodeURIComponent(old_fd.applylabel)
        + '&cf2_sel=' + encodeURIComponent(old_fd.labeltoapply)
        + '&cf2_emc=' + encodeURIComponent(old_fd.forward)
        + '&cf2_email=' + encodeURIComponent(old_fd.forwardto)
        + '&cf2_tr=' + encodeURIComponent(old_fd.deleteit)
        + '&ofid=' + encodeURIComponent(old_fd.id)
        + '&zx=' + UniqueURL();

    var node=getNode('lblCreateFilter');
    if (refresh)
    {
        node.innerHTML = '<b>'+getWord('running')+'</b>';
        node.removeEventListener('click', onCreateFilter, false);
    }

    GM_xmlhttpRequest({
        method:'GET',
        url: add_flt_url,
        headers:{'Referer': referer},
        onload: function(responseDetails) {

            debug(responseDetails.responseText );

            if (refresh)
            {
                var ret=getReturnValue(responseDetails.responseText, 'D([\"ar\"');

                if (ret!=null)
                {
                    debug('< D(["ar" > returns : '+ret.toString());
                }

                if(ret && ret[1])
                    FloatingMsg = ret[1];
                else
                    FloatingMsg = getWord('failtoretrieveresult');

				DataReady=false;
                getLabel_n_FilterData(drawFilterAsstWorkspace, false);

                node.innerHTML = '<b>'+getWord('createfilter')+'</b>';
            }
            debug('[editFilter]: Leaving...');
        },
        onerror: function(responseDetails){
            GM_log("ERROR: \nstatus="+responseDetails.status+"\nHeaders="+responseDetails.responseHeaders+"\nFeed data="+ responseDetails.responseText);
            debug('[editFilter]: Leaving...');
        }
    });
}

//======================================
// Get data item value given the header
//======================================
function getReturnValue(data, header)
{
    //debug('[getReturnValue]: Entering...');

    data = data.replace(/[\r\n\t\v\f\b\0]/g,"");    // remove some escaped characters which doesn't affect the result
    data = data.replace(/\\\\/g, "\\");                    // replace \\ with \

    // header is the data header like < D(["ar" >
    var s;
    var param;
    var ret=null;

    param=new ParamParsingData();

    param.curr_pos=0;

    s=getRawData(data, header);

   // debug('[getReturnValue]: getRawData() returns <'+s+'>');

    if (s!='')
        ret = parseData(s, 0, s.length-1, param);        // parse the block data, data is the data string,
    else
        ret = null;

    //debug('[getReturnValue]: Leaving...');

    return ret;
}

function getRawData(data, header)
{
    // header is the data header like < D(["ar" >
    var sp = data.indexOf(header), ep;

    if (sp!=-1)    // the labels found
    {
        sp = sp + header.length + 1;                // the starting point of this data block
        ep = data.indexOf(');', sp);                // the ending point of this data block

        return data.substring(sp, ep-1);
    }

    return '';
}

//=================================
// Parse raw data read from google
//=================================
function parseData(data, sp, ep, param)
{
    var i;
    var quoted=false;
    var s="";
    var arr = new Array();

    //GM_log(data.substring(sp,ep));

    i = sp;    // skip the starting '['

    while (i<=ep)
    {
        switch (data[i])
        {
            case '[':    // found an inner block
            {
                if (!quoted)
                {
                    arr.push(parseData(data, i+1, ep, param));
                    i = param.curr_pos;
                }
                else
                    s=s+data[i];

                break;
            }
            case '"':                // find an element
            {
                if (!quoted)            // left quote in a pair is found
                {
                    quoted=true;
                    s="";
                }
                else                // right quote in a pair is found
                {
                    arr.push(myUnescape(s));    // push the current element into array
                    s="";
                    quoted = false;
                }
                break;
            }
            case '\\':                // take care of the escaped character
            {
                switch (data[i+1])    // check the next character
                {
                    case '"':        // \"
                    case '\'':
                    case '\<':
                    case '\>':
                    {
                        s=s+data[i+1];
                        i++;
                        break;
                    }
                    default:        // error, I don't do anything here, assuming Google doesn't make mistake in the data :)
                    {
                        s=s+data[i];
                        break;
                    }
                }
                break;
            }
            case ',':                // delimiter
            {
                if (!quoted)        // not quoted
                {
                    if (data[i-1]!='"' && data[i-1]!=']')
                        arr.push(s);

                    s = "";            // clear the current element
                }
                else
                    s = s + ',';

                break;
            }
            case ']':                // finish processing current array
            {
                if (!quoted)
                {
                    if (s!="")
                         arr.push(myUnescape(s));

                    s = "";

                    param.curr_pos = i;

                    return arr;        // I assume the brackets are well paired
                }
                else
                    s = s + ']';

                break;
            }
            default:
                s = s + data[i];
        }

        param.curr_pos = ++i;
    }

    return arr;

}

var charset='abcdefghijklmnopqrstuvwxyz0123456789';
//====================
// Make a unique URL
//====================
function UniqueURL()
{
    var s='';

    for (i=0;i<12;i++)
    {
        s=s+charset[Math.floor(Math.random()*36)];
    }

    return s;
}

//====================
// show debug message
//====================
function debug(msg)
{
    if (DEBUG) GM_log(msg);
}

//============================
// trim space around a string
//============================
function trim(s)
{
    var i, len=s.length, sp=0, ep=len-1;

    for (i=0;i<len;i++)
        if (s[i]==' ') sp++;
        else break;

    for (i=len-1;i>=sp;i--)
        if (s[i]==' ') ep--;
        else break;

    return s.subString(sp, ep+1);
}

// Following function credited to RoBorg, http://javascript.geniusbug.com/
function clone(obj)
{
    if(typeof(obj) != 'object') return obj;
    if(obj == null) return obj;

    var newobj = new Object();

    for(var i in obj)
        newobj[i] = clone(obj[i]);

    return newobj;
}

// Following functions credited to Mihai @ http://persistent.info/
function newNode(type) {
    return unsafeWindow.document.createElement(type);
}

function getNode(id) {
    return unsafeWindow.document.getElementById (id);
}

function getDataItem(data, header, endchar) {
    var re = new RegExp(header + "([^"+endchar+"]+)");
    var value = re.exec(data);
    return (value != null) ? myUnescape(value[1]) : null;
}
