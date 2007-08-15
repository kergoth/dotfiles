// ==UserScript==
// @name           WoWHead Link Changer
// @namespace      WHLC
// @description    WoWHead Link Changer
// @include        *
// ==/UserScript==

var links = document.getElementsByTagName("a");
var reg = new Array();
reg[0] = new RegExp("http://www.thottbot.com/i=");
reg[1] = new RegExp("http://www.thottbot.com/i");
for (var i = 0; i < links.length; i++) {
  for (var j = 0; j < reg.length; j++) {
    links[i].href = links[i].href.replace(reg[j], "http://www.wowhead.com/?item=");
  }
}
