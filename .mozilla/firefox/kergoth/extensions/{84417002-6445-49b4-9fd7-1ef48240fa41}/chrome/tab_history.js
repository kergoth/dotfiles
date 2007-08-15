// I should probably just intercept link events, but don't know how
// without iterating over all the <a> elements.
var TabHistory =
{
	// copies history from one tab to another, via tab.browser.sessionHistory
	copyHistory : function(fromTab, newTab)
	{
		var fromHistory = getBrowser().getBrowserForTab(fromTab).sessionHistory;
		var toHistory = getBrowser().getBrowserForTab(newTab).sessionHistory;
		// needed to use addEntry
		toHistory.QueryInterface(Components.interfaces.nsISHistoryInternal);

		// copy oldHistory entries to newHistory, simulating a continued session
		for(var i = 0; i < (fromHistory.index + 1); ++i)
		{
			toHistory.addEntry(fromHistory.getEntryAtIndex(i, false), true);
		}
	},

	init : function()
	{
		// when left-click opens new windows in tabs (TabMix doesn't need this)
		// Note: this calls addTab, but with a blank tab, which is kind of a pain in the ass.
		eval('nsBrowserAccess.prototype.openURI = ' +
			nsBrowserAccess.prototype.openURI.toString().replace(
				/(var newTab.*;)/, '$1\nTabHistory.copyHistory(' +
					'gBrowser.selectedTab, newTab);'));

		// rewrite addTab to add history
		// Note: the (0 == sessionHistory.count) is to not execute copyHistory if the
		// previous eval statement was called, because it's already been executed.
		var tabbrowser = document.getElementById("content");
		eval('tabbrowser.addTab = ' +
			tabbrowser.addTab.toString().replace(/(t.linkedBrowser = b;)/, "$1\n" +
			"if((0 == b.sessionHistory.count) && aReferrerURI && aReferrerURI.scheme != 'chrome') " +
			"TabHistory.copyHistory(this.selectedTab, t);\n"));
	}
};

window.addEventListener("load", function() { TabHistory.init(); }, false);
