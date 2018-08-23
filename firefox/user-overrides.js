/* 0302a: enable auto update installing for Firefox (after the check in 0301a) */
user_pref("app.update.auto", true);
/* 0302b: enable auto update installing for extensions (after the check in 0301b) */
user_pref("extensions.update.autoUpdateDefault", true);
/* 0707: disable (or setup) DNS-over-HTTPS (DoH) (FF60+)
 * TRR = Trusted Recursive Resolver
 * .mode: 0=off, 1=race, 2=TRR first, 3=TRR only, 4=race for stats, but always use native result
 * [WARNING] DoH bypasses hosts and gives info to yet another party (e.g. Cloudflare)
 * [1] https://www.ghacks.net/2018/04/02/configure-dns-over-https-in-firefox/
 * [2] https://hacks.mozilla.org/2018/05/a-cartoon-intro-to-dns-over-https/ ***/
user_pref("network.trr.mode", 0);
user_pref("network.trr.bootstrapAddress", "");
user_pref("network.trr.uri", "");
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
/* 1020: enable the Session Restore service */
user_pref("browser.startup.page", 3);
user_pref("browser.sessionstore.resume_session", true);
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
user_pref("network.cookie.thirdparty.sessionOnly", false);
user_pref("network.cookie.thirdparty.nonsecureSessionOnly", false); // (FF58+)
/* 2703: set cookie lifetime policy
 * 0=until they expire (default), 2=until you close Firefox, 3=for n days (see next pref) */
user_pref("network.cookie.lifetimePolicy", 3);
/* 2730: enable offline cache ***/
//user_pref("browser.cache.offline.enable", true);
/* 2802: disable Firefox to clear history items on shutdown */
user_pref("privacy.sanitize.sanitizeOnShutdown", false);
/* 4001: disable First Party Isolation (FF51+), as this causes breakage for me */
user_pref("privacy.firstparty.isolate", false);
/* 5003: enable closing browser with last tab ***/
user_pref("browser.tabs.closeWindowWithLastTab", true);
/* 5010: disable ctrl-tab previews, as this also switches to MRU order ***/
user_pref("browser.ctrlTab.previews", false);
/* 5021d: set behavior of pages normally meant to open in a new window (such as target="_blank"
 * or from an external program), but that have instead been loaded in a new tab.
 * true: load the new tab in the background, leaving focus on the current tab
 * false: load the new tab in the foreground, taking the focus from the current tab. ***/
user_pref("browser.tabs.loadDivertedInBackground", true);

// RFP
/* 4501: disable privacy.resistFingerprinting (FF41+), it's not worth forcing my window size */
user_pref("privacy.resistFingerprinting", false); // (hidden pref) (not hidden FF55+)
// FF55+
// 4601: [2514] spoof (or limit?) number of CPU cores (FF48+)
   // [WARNING] *may* affect core chrome/Firefox performance, will affect content.
   // [1] https://bugzilla.mozilla.org/1008453
   // [2] https://trac.torproject.org/projects/tor/ticket/21675
   // [3] https://trac.torproject.org/projects/tor/ticket/22127
   // [4] https://html.spec.whatwg.org/multipage/workers.html#navigator.hardwareconcurrency
   // user_pref("dom.maxHardwareConcurrency", 2);
// * * * /
// FF56+
// 4602: [2411] disable resource/navigation timing
user_pref("dom.enable_resource_timing", false);
// 4603: [2412] disable timing attacks
   // [1] https://wiki.mozilla.org/Security/Reviews/Firefox/NavigationTimingAPI
user_pref("dom.enable_performance", false);
// 4604: [2512] disable device sensor API
   // [WARNING] [SETUP] Optional protection depending on your device
   // [1] https://trac.torproject.org/projects/tor/ticket/15758
   // [2] https://blog.lukaszolejnik.com/stealing-sensitive-browser-data-with-the-w3c-ambient-light-sensor-api/
   // [3] https://bugzilla.mozilla.org/buglist.cgi?bug_id=1357733,1292751
   // user_pref("device.sensors.enabled", false);
// 4605: [2515] disable site specific zoom
   // Zoom levels affect screen res and are highly fingerprintable. This does not stop you using
   // zoom, it will just not use/remember any site specific settings. Zoom levels on new tabs
   // and new windows are reset to default and only the current tab retains the current zoom
user_pref("browser.zoom.siteSpecific", false);
// 4606: [2501] disable gamepad API - USB device ID enumeration
   // [WARNING] [SETUP] Optional protection depending on your connected devices
   // [1] https://trac.torproject.org/projects/tor/ticket/13023
   // user_pref("dom.gamepad.enabled", false);
// 4607: [2503] disable giving away network info (FF31+)
   // e.g. bluetooth, cellular, ethernet, wifi, wimax, other, mixed, unknown, none
   // [1] https://developer.mozilla.org/docs/Web/API/Network_Information_API
   // [2] https://wicg.github.io/netinfo/
   // [3] https://bugzilla.mozilla.org/960426
user_pref("dom.netinfo.enabled", false);
// 4608: [2021] disable the SpeechSynthesis (Text-to-Speech) part of the Web Speech API
   // [1] https://developer.mozilla.org/docs/Web/API/Web_Speech_API
   // [2] https://developer.mozilla.org/docs/Web/API/SpeechSynthesis
   // [3] https://wiki.mozilla.org/HTML5_Speech_API
user_pref("media.webspeech.synth.enabled", false);
// * * * /
// FF57+
// 4610: [2506] disable video statistics - JS performance fingerprinting (FF25+)
   // [1] https://trac.torproject.org/projects/tor/ticket/15757
   // [2] https://bugzilla.mozilla.org/654550
user_pref("media.video_stats.enabled", false);
// 4611: [2509] disable touch events
   // fingerprinting attack vector - leaks screen res & actual screen coordinates
   // 0=disabled, 1=enabled, 2=autodetect
   // [WARNING] [SETUP] Optional protection depending on your device
   // [1] https://developer.mozilla.org/docs/Web/API/Touch_events
   // [2] https://trac.torproject.org/projects/tor/ticket/10286
   // user_pref("dom.w3c_touch_events.enabled", 0);
// * * * /
// FF59+
// 4612: [2511] disable MediaDevices change detection (FF51+)
   // [1] https://developer.mozilla.org/docs/Web/Events/devicechange
   // [2] https://developer.mozilla.org/docs/Web/API/MediaDevices/ondevicechange
user_pref("media.ondevicechange.enabled", false);
// * * * /
// FF60+
// 4613: [2011] disable WebGL debug info being available to websites
   // [1] https://bugzilla.mozilla.org/1171228
   // [2] https://developer.mozilla.org/docs/Web/API/WEBGL_debug_renderer_info
user_pref("webgl.enable-debug-renderer-info", false);
