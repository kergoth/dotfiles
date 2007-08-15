// ==UserScript==
// @name           Google Docs Download
// @namespace      gdd
// @description    Create a download list of your google documents.
// @include        http://docs.google.com/*
// @include        https://docs.google.com/*
// @exclude        http://docs.google.com/Doc?id=*
// @exclude        https://docs.google.com/Doc?id=*
// ==/UserScript==

var SCRIPT = {
	name: "Google Docs Download",
	namespace: "http://www.1st-soft.net/",
	description: 'Create a download list of your google documents.',
	source: "http://www.1st-soft.net/gdd/googledocdownload.user.js",
	identifier: "http://www.1st-soft.net/gdd/googledocdownload.user.js",
	version: "0.3",								// version
	date: (new Date(2007, 5, 23))		// update date
			.valueOf()
};

/*
   Identifies any excess white space or single quotes from pieces of javascript.
*/
function isWhiteSpace(char){
	switch(char){
		case" ":
		case"\n":
		case"\r":
		case"\t":
		case"\'":
			return true;
			break;
	}
	return false;
}

/*
   Removes any excess white space or single quotes from pieces of javascript.
*/
function trim(mystr){
	var i = 0;
	while(isWhiteSpace(mystr.substr(0,1)) && i < mystr.length){
		mystr = mystr.substr(1);
		i++;
	}
	i = 0;
	while(isWhiteSpace(mystr.substr(mystr.length-1,1)) && i < mystr.length){
		mystr = mystr.substr(0,mystr.length-1);
		i++;
	}
	return mystr;
}



var links = new Array();	// Spreadsheet download links.
var ids = new Array();		// A list of document IDs and keys.
var actioncounter = 0;		// The action number of the spreadsheet link.
var formats = new Array();	// A list of download format labels and their document/spreadsheet identifier.
formats[formats.length] = new Array("ms","doc","4");
formats[formats.length] = new Array("csv","rtf","5&gid=0");
formats[formats.length] = new Array("oo","oo","13");
formats[formats.length] = new Array("pdf","pdf","12");
formats[formats.length] = new Array("text","rtf","23&gid=0");

/*
   Finds the identifiers for a format label.
*/
function findFormat(label){
	for(var i = 0; i < formats.length; i++){
		if(formats[i][0] == label){
			return formats[i];
		}
	}
	return false;
}

/*
   Encode commas that are inside single quotes
*/
function titleEncode(line){
	var inApos = false;
	for(var i = 0; i < line.length; i++){
		if(line.charAt(i)=="\'"){
			inApos = !inApos;
		}
		if(line.charAt(i)=="," && inApos){
			line = line.slice(0,i)+"&#44;"+line.slice(i+1,line.length);
		}
	}
	return line;
}

/*
   Extracts document data from the javascript in the google documents page.
*/
function docData(){
	var query = "//script[contains(text(),'initRowDb()')]";	// initRowDb is a function called by the script block we are looking for.
											// xPath is used to get the script block.
	var result = document.evaluate(query, document,null,XPathResult.ANY_TYPE,null);
	var item = result.iterateNext().innerHTML;			// Extract the javascript code from the script block.
	var tokens = item.split("\n");					// Split it up by each line.
	var token;
	for(var i = 0; i < tokens.length; i++){				// Look at each line of javascript in the block.
		token = trim(tokens[i]);					// Trim the white space from the current line.
		token = token.replace(/\\\'/g,'&apos;');
		token = titleEncode(token);
		if(token.substr(0,9) == "newAction"){			// If the line invokes the newAction command...
			token = token.split("','");				  // Break up the line by it's arguments.
			token = token[1].split("'");				  // Trim off the tail of the command.
			var url = token[0];
			links[actioncounter] = url;				  // Add the url to the links list.
			actioncounter++;	
		}else if(token.substr(0,15) == "listData.newRow"){	// If the line invokes the newRow command...
			token = token.split("(");
			token.shift();
			token = token.join("(");
			token = token.split(")");
			token.pop();
			token = token.join(")");
			token = token.split(",");	// Grab the arguments of the command.
			var idData = new Array();					// Create a new array to store the data in the command.
			idData[0] = trim(token[0]);					// Store the document name.
			idData[1] = trim(token[1]);					// Store the document ID/key.
			idData[2] = trim(token[4].split('&#44;')[0]);		// Store the id of the download link.
			if(trim(token[4]).length > 0){
				idData[3] = "https://docs.google.com/images/arrow_ss.gif";
			}else{
				idData[3] = "https://docs.google.com/images/arrow_doc.gif";
			}
			ids[ids.length] = idData;					// Add the array to the ID list.
		}
	}
}

/*
   Google represents the '=' character as \u003d in the download urls.  This function converts them to be functional.
*/
function makeUsable(url){
	var symbol = "\\u003d";
	return url.split(symbol).join("=");
}

/*
   Finds the url to the download with the given document ID/key and sets the format you wish to download.
*/
function getUrl(id,format){
	for(var i = 0; i < ids.length; i++){	// Cycle through doc list and stop when you find a document with a matching ID.
		if(ids[i][0] == id){
			break;
		}
	}
	if(i == ids.length){				// If all documents are cycled through then there is no download URL.
		return "";
	}
	if(ids[i][2].length > 0){			// Otherwise check to see if it has a download link ID.  If so then the doc is a spreadsheet.
		var sslink = makeUsable(links[ids[i][2]]);	// Convert the symbols in the URL.
		sslink = sslink.split("=");				// Remove the current format variable.
		sslink.pop();
		sslink = sslink.join("=")+"="+findFormat(format)[2];	// Replace it with the user defined format.
		return sslink;
	}else{
		return "MiscCommands?command=saveasdoc&docID="+id+"&exportFormat="+findFormat(format)[1];	// Otherwise the document is a word document.
	}
}

/*
   Gets the user defined format from the url.
*/
function getFormat(){
	var search = document.location.search;
	var format = "";
	var thischar = "";
	for(var i = search.indexOf("gddformat=")+"gddformat".length+1; i < search.length; i++){
		if(search.indexOf("gddformat=")==-1){break;}
		thischar = search.substr(i,1);
		if(thischar=="&"){break;}
		format += thischar;
	}
	if(format==""){format="ms";}
	return format;
}

/*
   This is the primary routine invoked after the page loads.
*/
if(document.location.href.indexOf("gdd=true") != -1){ 	// Check to see if the user wants to download the documents.
	docData();								// If so, then extract the data from the javascript in the page.
	var content = "";
	var format = getFormat();					// Find the user defined format.
	var url = "";
	for(var i = 0; i < ids.length; i++){			// Get an html list of downloads.
		url = getUrl(ids[i][0],format);
		if(url != ""){
			content += "<li style=\"list-style-type:none;margin-bottom:8px;\"><img src=\""+ids[i][3]+"\" style=\"vertical-align:top;\" /> <a href=\""+url+"\" style=\"font-weight: bold;\" onClick=\"this.style.fontWeight='normal';\">"+ids[i][1]+"</a></li>";
		}else{
			content += "<li style=\"list-style-type:none;margin-bottom:8px;\"><img src=\""+ids[i][3]+"\" style=\"vertical-align:top;\" /> "+ids[i][1]+"*</li>";	// If there is no format supported for a particular document then no link is printed.
		}
	}
	// The rest of this is user interface.
	var header = "<h2 style=\"margin-top:5px;\">Google Doc Download</h2><p>Tip: Have a lot of documents?  Use <a href=\"javascript: void(window.open('http://www.downthemall.net/'));\">DownThemAll</a> to get them fast and easy.</p>";
	var footer = "<p>Script written by Peter Shafer April '07.  Let me know if you find any bugs (gdd at 1st-soft.net) amd check for updates at <a href=\"javascript: void(window.open('http://www.1st-soft.net/gdd/'));\">http://www.1st-soft.net/gdd/</a>.</p>";
	// The page is then replaced with the newly generated html.
	document.getElementsByTagName("body")[0].innerHTML=header+"<ul>"+content+"</ul><p><a href=\"javascript: window.history.back();\">Back to Google Docs</a>.</p>"+footer;
}else{									// If the user has not clicked the download link, add it to the page.
	var search;
	if(document.location.href.indexOf("?") != -1){		// Check to see if other parameters have been set by google docs.
		search="&";							// If yes, then add an ampersand to the url.
	}else{
		search="?";							// Otherwise add a question mark to begin the parameter list.
	}
	// xPath is used to locate the google doc link list "New Document New Spreadsheet Upload"
	var query = "//html/body[@id='DocsterHomePage']/div/table/tbody/tr/td[@class='app']/table/tbody/tr/td[@class='app']";
	var result = document.evaluate(query, document,null,XPathResult.ANY_TYPE,null);
	var item = result.iterateNext();
	// Now the download link and the format selector are added to the page.
	var menucontent = "&nbsp;&nbsp;&nbsp;<b><a href=\""+document.location.href+""+search+"gdd=true\" class=\"app\" id=\"gddlink\">Download</a></b> ";
	menucontent += "<select style=\"font-size:10px;\" id=\"gddformat\" onChange=\"document.getElementById('gddlink').href='"+document.location.href+""+search+"gdd=true&gddformat='+this.value;\">";
	menucontent += "<option value=\"ms\">MS Office</option><option value=\"oo\">Open Office</option><option value=\"pdf\">PDF</option><option value=\"text\">Text</option><option value=\"csv\">CSV</option>";
	menucontent += "</select>";
	item.innerHTML+=menucontent;
}



// This software is licensed under the CC-GNU GPL.
// http://creativecommons.org/licenses/GPL/2.0/
// Google Doc Download was written by Peter Shafer, student developer, in April 2007.