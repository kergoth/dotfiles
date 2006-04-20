// ==UserScript==
// @name           Collapsible Amazon
// @namespace      http://brh.numbera.com/software/greasemonkeyscripts
// @description    Collapse any section of the Amazon website by clicking on the orange section header.
// @include        http://*.amazon.*
// ==/UserScript==

String.prototype.trim = function() { return this.replace(/^\s+|\s+$/g, ""); };

function findContentDiv(header) {
	var content = header.nextSibling;
	
	while(content && !(content.tagName == "DIV" && content.className == "content")) {
		content = content.nextSibling;
	}
	
	return content;
}

function headerClickHandler(header, content, key) {
	return function () {
		var opened = GM_getValue(key, true);
		
		if(opened == true) {
			opened = false;
			content.style.display = "none";
			header.className = header.className.replace("brhgmopened", "brhgmclosed");
		}
		else {
			opened = true;
			content.style.display = "";
			header.className = header.className.replace("brhgmclosed", "brhgmopened");
		}

		GM_setValue(key, opened);
	};
}

function setupHandlers() {
	GM_addStyle("b.brhgmopened { cursor:pointer; }\n" +
				"b.brhgmclosed { cursor:pointer; }\n" +
				"b.brhgmopened:before { content:\"-\"; color: black; font-weight: bold; border: 1px solid black; padding:0 3px; font-size:10px; margin-right: 4px;}\n" +
				"b.brhgmclosed:before { content:\"+\"; color: black; font-weight: bold; border: 1px solid black; padding:0 3px; font-size:10px; margin-right: 4px;}");

	var allHeaders = document.evaluate('//b[@class="h1"]', document, null, XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);

	for(var i = 0; i < allHeaders.snapshotLength; i++) {
		var header = allHeaders.snapshotItem(i);
		
		var content = findContentDiv(header);
		
		GM_log(content);
		
		if(content) {
			
			var key = header.innerHTML.trim();
			
			var opened = GM_getValue(key, true);
			
			header.addEventListener("click", headerClickHandler(header, content, key), false);
			
			if(opened == false) {
				content.style.display = "none";
				header.className += " brhgmclosed";
			}
			else {
				header.className += " brhgmopened";
			}
		}
	}
	
}

setupHandlers();
