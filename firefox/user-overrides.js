/* 0302a: enable auto update installing for Firefox (after the check in 0301a) */
user_pref("app.update.auto", true);
/* 0302b: enable auto update installing for extensions (after the check in 0301b) */
user_pref("extensions.update.autoUpdateDefault", true);
/* 0510: enable Pocket (FF39+)
 * Pocket is a third party (now owned by Mozilla) "save for later" cloud service
 * [1] https://en.wikipedia.org/wiki/Pocket_(application)
 * [2] https://www.gnu.gl/blog/Posts/multiple-vulnerabilities-in-pocket/ ***/
user_pref("extensions.pocket.enabled", true);
/* 0801: enable location bar using search */
user_pref("keyword.enabled", true);
/* 0850a: enable location bar autocomplete and suggestion types */
user_pref("browser.urlbar.autocomplete.enabled", true);
user_pref("browser.urlbar.suggest.history", true);
user_pref("browser.urlbar.suggest.bookmark", true);
user_pref("browser.urlbar.suggest.openpage", true);
/* 0850d: enable location bar autofill */
user_pref("browser.urlbar.autoFill", true);
user_pref("browser.urlbar.autoFill.typed", true);
/* 0850e: disable location bar one-off searches (FF51+), I hate the icons
 * [1] https://www.ghacks.net/2016/08/09/firefox-one-off-searches-address-bar/ ***/
user_pref("browser.urlbar.oneOffSearches", false);
/* 0850f: enable location bar suggesting local search history (FF57+)
 * [1] https://bugzilla.mozilla.org/show_bug.cgi?id=1181644 ***/
user_pref("browser.urlbar.maxHistoricalSearchSuggestions", 10); // max. number of search suggestions
/* 0901: disable saving passwords */
user_pref("signon.rememberSignons", false);
/* 1020: enable the Session Restore service completely */
user_pref("browser.sessionstore.max_tabs_undo", 10);
user_pref("browser.sessionstore.max_windows_undo", 10);
/* 1021: enable storing extra session data on unencrypted sites */
user_pref("browser.sessionstore.privacy_level", 1);
/* 1022: enable resuming session from crash */
user_pref("browser.sessionstore.resume_from_crash", true);
/* 1202: drop the min from 1.2 to 1.0, as bugzilla.yoctoproject.org sucks */
user_pref("security.tls.version.min", 1);
/* 1401: enable websites choosing fonts (0=block, 1=allow)
 * If you disallow fonts, this drastically limits/reduces font
 * enumeration (by JS) which is a high entropy fingerprinting vector.
 * [SETTING-56+] Options>General>Language and Appearance>Advanced>Allow pages to choose...
 * [SETTING-ESR] Options>Content>Font & Colors>Advanced>Allow pages to choose...
 * [SETUP] Disabling fonts can uglify the web a fair bit. ***/
user_pref("browser.display.use_document_fonts", 1);
/* 1701: enable Container Tabs setting in preferences (see 1702) (FF50+)
 * [1] https://bugzilla.mozilla.org/show_bug.cgi?id=1279029 ***/
user_pref("privacy.userContext.ui.enabled", true);
/* 1702: enable Container Tabs (FF50+)
 * [SETTING-56+] Options>Privacy & Security>Tabs>Enable Container Tabs
 * [SETTING-ESR] Options>Privacy>Container Tabs>Enable Container Tabs ***/
user_pref("privacy.userContext.enabled", true);
/* 1703: enable a private container for thumbnail loads (FF51+) ***/
user_pref("privacy.usercontext.about_newtab_segregation.enabled", true);
/* 1704: set long press behaviour on "+ Tab" button to display container menu (FF53+)
 * 0=disables long press, 1=when clicked, the menu is shown
 * 2=the menu is shown after X milliseconds
 * [NOTE] The menu does not contain a non-container tab option
 * [1] https://bugzilla.mozilla.org/show_bug.cgi?id=1328756 ***/
user_pref("privacy.userContext.longPressBehavior", 2);
/* 2301: enable workers */
user_pref("dom.workers.enabled", true);
/* 2302: enable service workers */
user_pref("dom.serviceWorkers.enabled", false);
/* 2508: enable hardware acceleration for performance reasons */
user_pref("layers.acceleration.disabled", false);
/* 2701: disable cookies for 3rd party */
user_pref("network.cookie.cookieBehavior", 1);
/* 2730: enable offline cache ***/
//user_pref("browser.cache.offline.enable", true);
/* 2802: disable Firefox to clear history items on shutdown */
user_pref("privacy.sanitize.sanitizeOnShutdown", false);
/* 4001: disable First Party Isolation (FF51+), as this causes breakage for me */
user_pref("privacy.firstparty.isolate", false);
/* 4501: disable privacy.resistFingerprinting (FF41+), it's not worth forcing my window size */
user_pref("privacy.resistFingerprinting", false); // (hidden pref) (not hidden FF55+)
/* 5003: enable closing browser with last tab ***/
user_pref("browser.tabs.closeWindowWithLastTab", true);
/* 5010: disable ctrl-tab previews, as this also switches to MRU order ***/
user_pref("browser.ctrlTab.previews", false);
/* 5021d: set behavior of pages normally meant to open in a new window (such as target="_blank"
 * or from an external program), but that have instead been loaded in a new tab.
 * true: load the new tab in the background, leaving focus on the current tab
 * false: load the new tab in the foreground, taking the focus from the current tab. ***/
user_pref("browser.tabs.loadDivertedInBackground", true);
