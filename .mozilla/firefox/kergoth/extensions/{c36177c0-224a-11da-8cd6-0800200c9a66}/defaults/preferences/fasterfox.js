/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Fasterfox.
 *
 * The Initial Developer of the Original Code is
 * Tony Gentilcore.
 * Portions created by the Initial Developer are Copyright (C) 2005
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *  See readme.txt
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

// Fasterfox Prefs
pref("extensions.fasterfox.enhancedPrefetching", false);
pref("extensions.fasterfox.pageLoadTimer", true);
pref("extensions.fasterfox.preset", 3);
pref("extensions.fasterfox.lastTab", 0);
pref("extensions.fasterfox.whitelist", "");

// Cache Prefs
pref("browser.cache.memory.capacity", 65536);
pref("browser.cache.disk.capacity", 76800);
//pref("config.trim_on_minimize", false);
pref("network.dnsCacheExpiration", 3600);
pref("network.dnsCacheEntries", 512);

// HTTP Connection Prefs
pref("network.http.max-connections", 48);
pref("network.http.max-connections-per-server", 24);
pref("network.http.max-persistent-connections-per-server", 8);
pref("network.http.max-persistent-connections-per-proxy", 16);
//pref("network.ftp.idleConnectionTimeout", 60);
//pref("network.http.keep-alive.timeout", 30);

// HTTP Pipelining Prefs
pref("network.http.pipelining", true);
pref("network.http.pipelining.firstrequest", true);
pref("network.http.proxy.pipelining", true);
pref("network.http.pipelining.maxrequests", 8);

// Rendering Prefs
pref("browser.sessionhistory.max_viewers", 5);
pref("nglayout.initialpaint.delay", 0);
pref("ui.submenuDelay", 50);
//pref("content.notify.ontimer", true);
//pref("content.interrupt.parsing", true);
//pref("content.notify.interval", 100);
//pref("content.notify.threshold", 100000);
//pref("content.notify.backoffcount", 200);
//pref("content.max.tokenizing.time", 3000000); 
//pref("content.maxtextrun", 8191);
//pref("content.notify.interval", 100000);
//pref("content.notify.backoffcount", 10);
//pref("content.switch.threshold", 100000);

// Popups
pref("privacy.popups.disable_from_plugins", 2);

// Description
pref("extensions.{c36177c0-224a-11da-8cd6-0800200c9a66}.description", "chrome://fasterfox/locale/fasterfox.properties");
