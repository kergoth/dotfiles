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
 * The Original Code is useragent toolbar.
 *
 * The Initial Developer of the Original Code is David Illsley.
 * Portions created by the Initial Developer are Copyright (C) 2001
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *  Andy Edmonds <aedmonds@mindspring.com>
 *  David Illsley <illsleydc@bigfoot.com>
 *  Pavol Vaskovic <pali@pali.sk>
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

//SmoothWheel by Avi Halachmi (avihpit@yahoo.com)
//started: 22-Mar-2003: avih
//2004-04-05: Paradox: added profile install (changelog line and "sw_" vars prefix added by avih)
//2004-07-03: avih: modified for jar file install, modified question text

const SW_INST_TO_PROFILE = "Do you wish to install smoothwheel to your profile?\nThis will mean it does not need reinstalling when you update your browser.\n(Click Cancel if you want smoothwheel installing to the application directory.)";

initInstall("SmoothWheel", "/avih/smoothwheel", "0.0.1");
var sw_instToProfile = confirm(SW_INST_TO_PROFILE);
var sw_chromef = sw_instToProfile ? getFolder("Profile", "chrome") : getFolder("chrome");
var sw_mgDir = getFolder(sw_chromef , "smoothwheel");
setPackageFolder(sw_mgDir);
//var sw_err = addDirectory("smoothwheel");
var sw_err = addDirectory("chrome");  //adds the content of the chrome directory from the installation package to mw_mgDir
if ( sw_err == SUCCESS ) {
	if(sw_instToProfile) registerChrome(CONTENT | PROFILE_CHROME, getFolder(sw_mgDir, "smoothwheel.jar"), "content/");
  	else registerChrome(CONTENT | DELAYED_CHROME, getFolder(sw_mgDir, "smoothwheel.jar"), "content/");
  sw_err = performInstall();
  if ( sw_err == SUCCESS ) {
    alert("SmoothWheel v0.44.8.20051203 has been succesfully installed. \n"
      +"Please restart your browser to continue.");
  }
  else {
    alert("performInstall() failed. \n"
    +"_____________________________\nError code:" + sw_err);
    cancelInstall(sw_err);
  }
}
else {
  alert("Failed to create directory. \n"
    +"You probably don't have appropriate permissions \n"
    +"(write access to mozilla/chrome directory). \n"
    +"_____________________________\nError code:" + sw_err);
    cancelInstall(sw_err);
}
