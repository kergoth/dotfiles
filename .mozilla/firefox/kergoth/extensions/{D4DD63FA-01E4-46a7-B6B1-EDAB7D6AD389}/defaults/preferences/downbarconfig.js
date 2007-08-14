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
 * The Original Code is Download Statusbar.
 *
 * The Initial Developer of the Original Code is
 * Devon Jensen.
 * Portions created by the Initial Developer are Copyright (C) 2003
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s): Devon Jensen <velcrospud@hotmail.com>
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

pref("downbar.display.percent", false);
pref("downbar.display.speed", true);
pref("downbar.display.size", false);
pref("downbar.display.time", true);
pref("downbar.function.clearOnClose", false);
pref("downbar.function.clearFiletypes", "jpg, jpeg, png, gif");
pref("downbar.function.ignoreFiletypes", "");
pref("downbar.function.timeToClear", 5);
pref("downbar.function.askOnDelete", true);
pref("downbar.function.removeOnOpen", true);
pref("downbar.function.removeOnShow", true);
pref("downbar.function.trimHistory", false);
pref("downbar.function.numToTrim", 50);
pref("downbar.function.virusScan", false);
pref("downbar.function.virusExclude", "jpg, jpeg, gif, png" );
pref("downbar.function.virusLoc", "C:/Program Files/myAnti-VirusProgram.exe");
pref("downbar.function.virusArgs", "%1");
pref("downbar.function.launchOnClose", false);
pref("downbar.function.queueMode", false);
pref("downbar.function.queueNum", 3);
pref("downbar.style.default", true);
pref("downbar.style.db_downbar", ";margin:0px;padding-right:15px;overflow:hidden;");
pref("downbar.style.db_downbarPopup", "");
pref("downbar.style.db_progressStack", "max-width:135px;max-height:20px;min-height:20px;border:1px solid threeDShadow;-moz-border-radius:2px;margin-top:1px;margin-bottom:1px;margin-left:2px;margin-right:1px;padding:0px;");
pref("downbar.style.db_finishedHbox", "background-color:#89AFDB;max-width:135px;max-height:20px;min-height:20px;background-image:url(chrome://downbar/skin/whiteToTransGrad.png);-moz-border-radius:2px;border:1px solid threeDShadow;margin-top:1px;margin-bottom:1px;margin-left:2px;margin-right:1px;padding-top:0px;padding-bottom:0px;padding-left:3px;padding-right:0px;");
pref("downbar.style.db_notdoneHbox", "background-color:#A3A3A3;max-width:135px;max-height:20px;min-height:20px;background-image:url(chrome://downbar/skin/whiteToTransGrad.png);-moz-border-radius:2px;border:1px solid threeDShadow;margin-top:1px;margin-bottom:1px;margin-left:2px;margin-right:1px;padding-top:0px;padding-bottom:0px;padding-left:3px;padding-right:0px;");
pref("downbar.style.db_pausedHbox", "border-color:red;max-width:135px;max-height:20px;min-height:20px;border-style:solid;border-width:1px;-moz-border-radius:2px;margin-top:1px;margin-bottom:1px;margin-left:2px;margin-right:1px;padding:0px;");
pref("downbar.style.db_progressbar", "background-color:#89AFDB;background-image:url(chrome://downbar/skin/whiteToTransGrad.png);border-right:0px solid transparent;");
pref("downbar.style.db_progressremainder", "background-color:white;");
pref("downbar.style.db_filenameLabel", ";font-size:9pt;text-align:left;");
pref("downbar.style.db_progressIndicator", ";font-size:5pt;text-align:right;margin:0px 3px 0px 0px;padding:0px;min-width:10px;font-weight:bold;");
pref("downbar.function.firstRun", true);
pref("downbar.style.speedColorsEnabled", false);
pref("downbar.style.speedColor0", "0;#708FB5");
pref("downbar.style.speedColor1", "50;#81A5CE");
pref("downbar.style.speedColor2", "200;#8FB9E8");
pref("downbar.style.speedColor3", "400;#9AC5F7");
pref("downbar.function.miniMode", false);
pref("downbar.style.useGradients", true);
pref("downbar.function.useAnimation", true);
pref("downbar.function.hideKey", "z");
pref("downbar.function.donateTextHideDays", 60);
pref("downbar.toUninstall", false);
pref("extensions.{D4DD63FA-01E4-46a7-B6B1-EDAB7D6AD389}.description", "chrome://downbar/locale/downbar.properties");
pref("downbar.function.soundOnComplete", 0);
pref("downbar.function.soundCustomComplete", "");
pref("downbar.function.soundCompleteIgnore", "");
pref("downbar.display.mainButton", true);
pref("downbar.display.clearButton", true);
pref("downbar.display.toMiniButton", false);
pref("downbar.function.keepHistory", true);