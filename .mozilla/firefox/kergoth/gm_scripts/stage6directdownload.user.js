window.addEventListener("load", function(e) {
		//var vidID = "1217009";
		var vidURL = document.location + ' ';
		var vidURLarray = vidURL.split("/");
		if (vidURLarray[3] == "user") {
			var vidID = vidURLarray[6];
		}else{
			var vidID = vidURLarray[5];
		}
		var ddLink = '<li><a href="http://video.stage6.com/' + vidID + '/.divx">Direct Download</a></li>';
		var codeSnip = document.getElementById("share").innerHTML;
		codeSnip += ddLink;
		document.getElementById("share").innerHTML = codeSnip;
}, false);

// Script by defrex
// email: defrex0@gmail.com
// web: http://defrex.com/stage6-direct-downloader/

// ==UserScript==
// @name          Stage6 Direct Download
// @namespace     http://defrex.com
// @description   A script to add a direct download link to dtage6.fivx.com
// @include       http://stage6.divx.com/*
// ==/UserScript==
