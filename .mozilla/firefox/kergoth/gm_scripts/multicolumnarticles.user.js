// Multi-Column Articles Script
// Version 0.1.8
// Copyright (c) 2007, Raking Leaves
// Released under the GPL license
// http://www.gnu.org/copyleft/gpl.html
//
// Changelog
// ---------
// 0.1.8:
//   - Support for Foreign Affairs.
//   - Small fix for Mac.
// 0.1.7:
//   - Support for Wall Street Journal.
// 0.1.6.1:
//   - Small fix for Washington Post.
// 0.1.6:
//   - Support for Wired, contributed by Liam
// 0.1.5:
//   - Support for Slate
//   - Support for Seattle Times
// 0.1.4:
//   - Support for San Jose Mercury News, contributed
//     by Tracy Logan.
// 0.1.3:
//   - Improved aesthetics, contributed by Dave.
// 0.1.2:
//   - Added support for New York Magazine.
// 0.1.1: 
//   - Made text justified, which looks better
//     to me for narrow columns.  I may change 
//     this back if anyone complains.
// 0.1:
//   - Initial release
//
// ==UserScript==
// @name          Multi-column articles
// @namespace     http://diveintomark.org/projects/greasemonkey/
// @description   Multi-column articles for several publications
// @include       *nytimes.com*/*pagewanted=print*
// @include       http://*.nybooks.com/articles/*
// @include       http://*.newyorker.com/*printable=true*
// @include       http://*.washingtonpost.com/*pf.html
// @include       http://*.latimes.com/*,print.*
// @include       http://*.boston.com/*mode=PF*
// @include       http://*bostonreview.net/BR*
// @include       http://*theatlantic.com/doc/print*
// @include       http://*.printthis.clickability.com/pt/*nymag.com*
// @include       http://*.mercurynews.com/portlet/article/html/fragments/print_article.jsp?*
// @include       http://*.slate.com/*action=print*
// @include       http://seattletimes.nwsource.com/*PrintStory.pl*
// @include	  http://*.wired.com/*print*
// @include       http://*.wsj.com/article_print*
// @include       http://*.foreignaffairs.org/*mode=print*
// ==/UserScript==


// utility function, taken from web
function getElementsByClass(searchClass,node,tag) {
	var classElements = new Array();
	if ( node == null )
		node = document;
	if ( tag == null )
		tag = '*';
	var els = node.getElementsByTagName(tag);
	var elsLen = els.length;
	var pattern = new RegExp("(^|\\s)"+searchClass+"(\\s|$)");
	for (i = 0, j = 0; i < elsLen; i++) {
		if ( pattern.test(els[i].className) ) {
			classElements[j] = els[i];
			j++;
		}
	}
	return classElements;
}

// takes all the child nodes of parentNode and
// makes them children of a new div, which itself
// is made a child of parentNode
// @return the new div
function addChildrenToNewDiv(parentNode) {
    var dummyDiv = document.createElement('div');
    parentNode.appendChild(dummyDiv);
    for (var i = 0; i < parentNode.childNodes.length; i++) {
        if (parentNode.childNodes[i] != dummyDiv) {
            dummyDiv.appendChild(parentNode.childNodes[i].cloneNode(true));
        }
    }
    var kids = parentNode.childNodes;
    for (var j = kids.length - 1; j >= 0; j--) {
        if (kids[j] != dummyDiv) {
            parentNode.removeChild(kids[j]);
        }
    }
    return dummyDiv;
}

// removes a node from the DOM if it
// is not null
function removeIfNotNull(n) {
    if (n != null) {
        n.parentNode.removeChild(n);
    }
}

// remove all nodes in array from DOM
function removeAll(theNodes) {
    for (var i = theNodes.length - 1; i >= 0; i--) {
        removeIfNotNull(theNodes[i]);
    }
}

var currentlyScrolling = false;
var scrolledThusFar;
var totalScroll;
var scrollIncr;
var innerFrameID = 'articletext';
var pageNumDivID = 'pageNum';

function update_page_num() {
    document.getElementById(pageNumDivID).innerHTML = "Page " + curPageNum + " / " + numPages;
}

// scroll left or right by one increment
function do_scroll(right) {
    if (scrolledThusFar < totalScroll) {
        var amountToScroll = Math.min(scrollIncr, totalScroll - scrolledThusFar);
        if (right) {
            document.getElementById(innerFrameID).scrollLeft += amountToScroll;
        } else {
            document.getElementById(innerFrameID).scrollLeft -= amountToScroll;
        }            
        scrolledThusFar += amountToScroll;
        window.setTimeout(function() { do_scroll(right); }, 30);
    } else {
        window.clearTimeout();
        currentlyScrolling = false;
    }
}

// scroll to the next page
function scroll_next() {
    if (!currentlyScrolling && curPageNum < numPages) {
        currentlyScrolling = true;
        curPageNum++;
        update_page_num();
        scrolledThusFar = 0;
        do_scroll(true);
    }

}

// scroll to the previous page
function scroll_prev() {
    if (!currentlyScrolling && curPageNum > 1) {
        currentlyScrolling = true;
        curPageNum--;
        update_page_num();
        scrolledThusFar = 0;
        do_scroll(false);
    }
}

// calls a function specific to each site to
// get a div holding the article text
function getArticleText() {
    var theURL = document.URL;
    if (theURL.match(/nytimes\.com/)) {
        return getTextNYTimes();
    } else if (theURL.match(/nybooks\.com/)) {
        return getTextNYBooks();
    } else if (theURL.match(/newyorker\.com/)) {
        return getTextNewYorker();
    } else if (theURL.match(/washingtonpost\.com/)) {
        return getTextWashPost();
    } else if (theURL.match(/latimes\.com/)) {
        return getTextLATimes();
    } else if (theURL.match(/boston\.com/)) {
        return getTextBosGlobe();
    } else if (theURL.match(/bostonreview\.net/)) {
        return getTextBosReview();
    } else if (theURL.match(/theatlantic\.com/)) {
        return getTextAtlantic();
    } else if (theURL.match(/nymag\.com/)) {
        return getTextNYMag();
    } else if (theURL.match(/mercurynews\.com/)) {
        return getTextMercuryNews();
    } else if (theURL.match(/slate\.com/)) {
        return getTextSlate();
    } else if (theURL.match(/seattletimes\.nwsource\.com/)) {
        return getTextSeattleTimes();
    } else if (theURL.match(/wired\.com/)) {
	return getTextWired();
    } else if (theURL.match(/wsj\.com/)) {
        return getTextWSJ();
    } else if (theURL.match(/foreignaffairs\.org/)) {
        return getTextForeignAffairs();
    }
}


// the getText*() functions should
// (1) return a div D containing the article text, such that
// D is a child of the document.body node, and
// (2) reformat the page as needed to make the scrolling
// view work properly

function getTextForeignAffairs() {
    removeAll(document.body.getElementsByTagName('HR'));
    return addChildrenToNewDiv(document.body);
}
function getTextWSJ() {
    var theText = getElementsByClass('articleTitle', null, null)[0].parentNode;
    removeIfNotNull(theText.childNodes[1]);
    removeAll(theText.getElementsByTagName('IMG'));
    removeAll(theText.getElementsByTagName('TABLE'));
    removeIfNotNull(document.getElementById('inset'));
    return addChildrenToNewDiv(theText);
}

function getTextWired() {
    removeIfNotNull(document.getElementById('pic'));
    document.body.setAttribute("style", "width:auto;");
    var theText = document.getElementById('article_text');
    return addChildrenToNewDiv(theText);
}

function getTextSeattleTimes() {
    removeIfNotNull(getElementsByClass('photos', null, null)[0]);
    return addChildrenToNewDiv(document.body);
}

function getTextSlate() {
    return addChildrenToNewDiv(document.body);
}

function getTextMercuryNews() {
    var theText = getElementsByClass('articleBody', null, 'td')[0];
    return addChildrenToNewDiv(theText);
}

function getTextNYMag() {
    var mainDiv = document.getElementById('main');
    removeAll(mainDiv.getElementsByTagName('TABLE'));
    return mainDiv;
}
function getTextAtlantic() {
    // remove forms
    removeAll(document.body.getElementsByTagName('FORM'));
    return addChildrenToNewDiv(document.body);
}

function getTextBosReview() {
    var tableTags = document.body.getElementsByTagName('TABLE');
    var theText = null;
    for (var i = 0; i < tableTags.length; i++) {
        var curTable = tableTags[i];
        //alert(curTable.getAttribute("width"));
        if (curTable.getAttribute('cellspacing') == 14) {
            theText = curTable.getElementsByTagName('TD')[0];
        } 
        curTable.setAttribute('width', "100%");
    }
    var tdTags = document.body.getElementsByTagName('TD');
    for (var i = 0; i < tdTags.length; i++) {
        var curTD = tdTags[i];
        if (curTD.getAttribute('width') == 567) {
            // hack; should set width to fit window
            // eventually
            curTD.setAttribute('width', 1000);
        }
    }
    return addChildrenToNewDiv(theText);
}

function getTextBosGlobe() {
    var possibleDivs = getElementsByClass('story', null, 'div');
    if (possibleDivs.length != 1) {
        alert("weird");
    }
    var theText = possibleDivs[0];
    return theText;
}
function getTextLATimes() {
    var theText = document.body.childNodes[5];
    theText.setAttribute("style", "");
    removeIfNotNull(theText.getElementsByTagName("A")[0]);
    // no idea why, but these HR elements mess things up
    removeAll(document.body.getElementsByTagName("HR"));
    return theText;
}


function getTextWashPost() {
    var theText = document.body.childNodes[19];
    removeIfNotNull(theText.getElementsByTagName("FORM")[0]);
    var comments = document.getElementById('ArticleCommentsWrapper');
    if (comments) {
        // removing causes Javascript errors; doh!
        //theText.removeChild(comments);
    }
    removeIfNotNull(document.getElementById('articleCopyright'));
    return theText;
}

function getTextNYTimes() {
    var theText = document.getElementById('articleBody');
    theText.id = null;
    removeIfNotNull(document.getElementById('articleInline'));
    return theText;
}

function getTextNYBooks() {
    var theText = document.getElementById('center-content');
    theText.id = null;
    var spans = theText.getElementsByTagName("SPAN");
    for (var i = 0; i < spans.length; i++) {
        if (spans[i].className == 'ad') {
            theText.removeChild(spans[i]);
        }
    }
    removeIfNotNull(document.getElementById('right-content'));
    return theText;
}

function getTextNewYorker() {
    var theText = document.getElementById('printbody');
    removeIfNotNull(document.getElementById('articleRail'));
    document.body.setAttribute("style", "width:auto;");
    return theText;
}

// replace the original text with our multicolumn view div
function replaceOrigText(theText, artAndButtons) {
    theText.parentNode.replaceChild(artAndButtons,theText);
}

// handle keyboard shortcuts
function pressedKey(e) {
    if (e.altKey) return;
    // this should handle command key on mac
    if (e.metaKey) return;
    var code = e.keyCode;
    if (code == 37) { // left arrow
        scroll_prev();
    } else if (code == 39) { // right arrow
        scroll_next();
    }
}

var columnWidthEm = 20;
var columnHeightEm = 40;
var frameHeightEm = 45;
var columnGapEm = 2;

// calculate the number of columns that fit
// in the given width (in pixels)
function columnsInWidth(width, theFontSize) {
    // lame!  re-do this as a closed form
    // calculation
    var tmp = 1;
    while (true) {
        if (tmp*columnWidthEm*theFontSize + (tmp-1)*columnGapEm*theFontSize > width) {
            break;
        }
        tmp = tmp + 1;
    }
    var numColumns = tmp - 1;
    return numColumns;
}

// compute the fraction of the screen taken by
// a single column
function columnRatio(pageWidth, theFontSize) {
    var numColumns = columnsInWidth(pageWidth, theFontSize);
    return ((pageWidth - (numColumns-1)*columnGapEm*theFontSize) / numColumns) / pageWidth;
}

// compute the number of extra columns needed to
// make the article fit in an exact number of pages
function numColumnsToPad(pageWidth, theFontSize, leftoverRatio) {
    //alert("leftover ratio " + leftoverRatio);
    var columnsPerPage = columnsInWidth(pageWidth, theFontSize);
    var extraColumns = columnsPerPage - columnsInWidth(leftoverRatio * pageWidth, theFontSize);
    //alert(extraColumns + " column of padding needed");
    return extraColumns;
}

var curPageNum = 1;
var numPages;
var theText;
theText = getArticleText();

if (theText) {
    // create the iframe for the article
    var articleTextDiv = document.createElement("div");
    articleTextDiv.setAttribute("id", innerFrameID);
    articleTextDiv.setAttribute("name", innerFrameID);
    var overallWidth = "100%;";
    articleTextDiv.setAttribute("style", "overflow:hidden;width:" + overallWidth + "height:" + frameHeightEm + "em; margin:0 auto;");

    // create navigation bar: prev / next button and page count
    var prevButton = document.createElement('input');
    prevButton.type = "button";
    prevButton.addEventListener('click', scroll_prev, true);
    prevButton.value = "Prev page";
    var prevButtonDiv = document.createElement('div');
    prevButtonDiv.setAttribute("style", "float:left; margin-left:10px;");
    prevButtonDiv.appendChild(prevButton);
    var nextButton = document.createElement('input');
    nextButton.type = "button";
    nextButton.addEventListener('click', scroll_next, true);
    nextButton.value = "Next page";
    var nextButtonDiv = document.createElement('div');
    nextButtonDiv.setAttribute("style", "float:right; margin-right:10px;");
    nextButtonDiv.appendChild(nextButton);
    var pageNum = document.createElement('div');
    pageNum.setAttribute("id", pageNumDivID);
    pageNum.setAttribute("style", "width:auto;margin:0 auto;text-align:center;");
    var navigationDiv = document.createElement("div");
    navigationDiv.setAttribute("id", "navigationbuttons");
    navigationDiv.setAttribute("style", "width:" + overallWidth);    
    navigationDiv.appendChild(prevButtonDiv);
    navigationDiv.appendChild(nextButtonDiv);
    navigationDiv.appendChild(pageNum);

    // put together iframe and navigation buttons
    var artAndButtons = document.createElement("div");
    artAndButtons.setAttribute("id", "articleandnav");
    artAndButtons.appendChild(articleTextDiv);
    artAndButtons.appendChild(navigationDiv);
    replaceOrigText(theText, artAndButtons);

    // the font size is the size of 1em
    var theFontSize = document.defaultView.getComputedStyle(articleTextDiv, "").getPropertyValue("font-size").replace(/px/, "");
    frameHeightEm = parseInt((0.75*window.innerHeight) / theFontSize);
    columnHeightEm = frameHeightEm - 2;
    articleTextDiv.style.height = frameHeightEm + "em";
    
    // for some reason, things don't work if the styling
    // for this div just gets moved out to articleTextDiv
    var columnStyleDiv = document.createElement("div");
    columnStyleDiv.setAttribute("id", "columnstyling");
    columnStyleDiv.setAttribute("style", "-moz-column-width: " + columnWidthEm + "em; -moz-column-gap: " + columnGapEm + "em; -moz-column-rule: medium solid; height:" + columnHeightEm + "em; text-align:justify; ");
    columnStyleDiv.appendChild(theText);
    articleTextDiv.appendChild(columnStyleDiv);
    var scrollMax = articleTextDiv.scrollWidth;
    //alert("window width: " + ifrm.clientWidth + ", overall width: " + scrollMax);
    //var columnGap = 3 * 1.3333 * ifrm.getComputedStyle().fontSize;
    columnGap = Math.round(theFontSize*columnGapEm);
    //alert("column gap " + columnGap);
    totalScroll = articleTextDiv.clientWidth + columnGap;
    // TODO make a constant for number of scrolls
    scrollIncr = parseInt(totalScroll / 10);
    var theColumnRatio = columnRatio(articleTextDiv.clientWidth, theFontSize);
    var ratio = scrollMax / totalScroll;
    numPages = parseInt(ratio);
    //alert("column ratio " + theColumnRatio + ", diff " + (ratio - numPages));    
    // extra with fudge factor...
    var extra = ratio - numPages + 0.03;
    if (extra >= theColumnRatio) {
        numPages++;
        var columnsToPad = numColumnsToPad(articleTextDiv.clientWidth, theFontSize, extra);
        // pad out the columns
        // TODO use a StringBuffer?
        var lineBreakString = "";
        for (var i = 0; i < columnsToPad; i++) {
            for (var j = 0; j < columnHeightEm; j++) {
                lineBreakString += "<br/>";
            }
        }
        var paddingDiv = document.createElement("div");
        paddingDiv.setAttribute('id', 'brpadding');
        paddingDiv.innerHTML = lineBreakString;
        columnStyleDiv.appendChild(paddingDiv);
    }
    update_page_num();
    window.addEventListener('keypress', pressedKey, true);
    // just re-load the whole page on a resize for now
    window.addEventListener('resize', function(e) { window.location.href = window.location.href; }, true);
    //alert(numColumnsPerPage(ifrm.clientWidth, theFontSize) + " columns");
    //alert(columnGap);
}     

// bunch of old code, might be useful
// for debugging in the future
    //    var serializer = new XMLSerializer();
    //    var markup = serializer.serializeToString(theDiv);
    //alert(markup);
    //   ifrm.style.visibility = "visible";
    //alert(ifrm.contentWindow.scrollMaxX);
    //    if (Math.round((scrollMax / ifrm.contentWindow.innerWidth) + 0.5) != Math.round(scrollMax / ifrm.contentWindow.innerWidth)) {
    //        //       alert('single column');
    //        var spacerDiv = document.createElement('div');
    //        spacerDiv.setAttribute('style', 'width:500px;float:right;');
    //        spacerDiv.innerHTML = "<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>";
    //        theDiv.appendChild(spacerDiv);
    //        scrollMax = ifrm.contentWindow.scrollMaxX - 100;
    //    }
    //alert(widthAndFudge);
    //document.getElementById('scr1').contentWindow.scrollTo(ifrm.contentWindow.scrollMaxX, 0);
    //document.getElementById('scr1').contentWindow.scrollTo(0, ifrm.contentWindow.scrollMaxY);
    //   document.getElementById('scr1').contentWindow.scrollByPages(1);
    //   navigationDiv.innerHTML = "<br/><input type=\"button\" onClick=\"window.scroll_prev444()\" value=\"Prev Page\"><input type=\"button\" onClick=\"window.scroll_next333()\" value=\"Next Page\">";
