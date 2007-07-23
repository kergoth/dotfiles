           -< Fasterfox License >-

Version: MPL 1.1/GPL 2.0/LGPL 2.1

The contents of this file are subject to the Mozilla Public License Version
1.1 (the "License"); you may not use this file except in compliance with
the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
for the specific language governing rights and limitations under the
License.

The Original Code is Fasterfox.

The Initial Developer of the Original Code is
 * Tony Gentilcore (gentilac@slu.edu).
Portions created by the Initial Developer are Copyright (C) 2005
the Initial Developer. All Rights Reserved.

Contributor(s):
 * Czech (cs-CZ) - funTomas
 * German (de-DE) - ReinekeFux, geframuc, Team erweiterungen.de
 * Spanish (Argentina) (es-AR) - MorZilla
 * Spanish (Spain) (es-ES) - urko
 * Finnish (fi-FI) - herrahuu
 * French (fr-FR) - Calimo
 * Frisian (fy-NL) - moZes
 * Hebrew (he-IL) - asfaltboy
 * Hungarian (hu-HU) - kami, LocaLiceR
 * Italian (it-IT) - eagleman
 * Japanese (ja-JP) - Norah
 * Korean (ko-KR) - heygom
 * Lithuanian (lt-LT) - garas
 * Dutch (nl-NL) - Fopper, Liesbeth
 * Polish (pl-PL) - teo
 * Portuguese (Brazilian) (pt-BR) - Ghelman
 * Portuguese (Portugal) (pt-PT) - zefranc
 * Russian (ru-RU) - Modex
 * Slovak (sk-SK) - Rony, SlovakSoft
 * Slovenian (sl-SI) - miles
 * Swedish (sv-SE) - lagerstedt, jameka, StiffeL
 * Turkish (tr-TR) - ErkanKaplan, batuhancetin, Fatih
 * Ukrainian (uk-UA) - Sergey Khoruzhin
 * Chinese (Simplified) (zh-CN) - Pudgy, rickcart
 * Chinese (Traditional) (zh-TW) - micwang

Special thanks to:
 * Nicholas Dower for support, ideas, testing, bug fixing, and of course 
the very wonderful Fasterfox logo!

Alternatively, the contents of this file may be used under the terms of
either the GNU General Public License Version 2 or later (the "GPL"), or
the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
in which case the provisions of the GPL or the LGPL are applicable instead
of those above. If you wish to allow use of your version of this file only
under the terms of either the GPL or the LGPL, and not to allow others to
use your version of this file under the terms of the MPL, indicate your
decision by deleting the provisions above and replace them with the notice
and other provisions required by the GPL or the LGPL. If you do not delete
the provisions above, a recipient may use your version of this file under
the terms of any one of the MPL, the GPL or the LGPL.

The name "Fasterfox", the tagline "Performance and network tweaks for
Firefox.", and the Fasterfox logo are Copyright (C) 2005 Tony Gentilcore.
All rights reserved.


         -< Fasterfox Release Notes >-

~~~ 2.0.0 ~~~~~~~~~~~~~~~~~~~~~~~~~~~ 10/30/06 ~~~

* Added support for Firefox 2.0.
* Added the following 11 locales:
  - Spanish (Argentina) (es-AR)
  - Spanish (Spain) (es-ES)
  - Frisian (fy-NL)
  - Hungarian (hu-HU)
  - Lithuanian (lt-LT)
  - Portuguese (Brazilian) (pt-BR)
  - Portuguese (Portugal) (pt-PT)
  - Russian (ru-RU)
  - Swedish (sv-SE)
  - Ukrainian (uk-UA)
  - Chinese (Traditional) (zh-TW)
* Fixed bug which caused OK and Cancel buttons to
  not display properly in some locales and themes.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 1.0.3 ~~~~~~~~~~~~~~~~~~~~~~~~~~~ 1/14/06 ~~~

* Max version is now 1.5.0.* so that minor 
security versions will automatically be 
supported.
* Fixed problem with prefetching case sensitive
links.
* Added Chinese (Simplified) locale, special 
thanks to Pudgy and rickcart.
* Added Hebrew locale, special thanks to Pavel 
Savchenko.
* Updated Türkisch locale.
* Updated Finnish locale.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 1.0.2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~ 12/11/05 ~~~

* Added updated German locale.
* Added Slovenian locale, special thanks to miles.
* Added Korean locale, special thanks to heygom.
* Added Finnish locale, special thanks to Lauri 
Lahnasalo.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 1.0.1 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 12/8/05 ~~~

* Now checks robots.txt before prefetching.
* Options window now properly resizes for larger
font themes.  Special thanks to Teo for the XUL 
help.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 1.0.0 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 12/5/05 ~~~

* Added "whitelist" feature to specify sites which
should never have their pages prefetched.
* Added FastBack rendering setting. 
* Moved Fasterfox options to within the designated
options in the extension manager.
* Added link to Fasterfox Options to the page load
timer context menu.
* Page load timer and enhanced prefetching are now
separate from the presets.
* Added cs-CZ locale, special thanks to funTomas.
* Added sk-SK locale, special thanks to Rony, 
SlovakSoft.
* Now limits links prefetched per page to 100.
* Included extra error check for poorly formatted
links.
* Enhanced prefetching is now disabled by default.
* en-US locale updates:
  - Added whitelist.label
  - Added fastback.label
  - Added fastback.pagesInMem
  - Added fastback.desc
  - Added button.ok
  - Added button.cancel
  - Added pageload.options
  - Added pageload.neverPrefetch (for future use)
  - Added options.title
  - Changed main.tab
  - Changed main.captionLabel
  - Changed enablePrefetching.desc1
  - Changed enablePrefetching.desc2

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.8.2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~ 11/20/05 ~~~

* Corrected typo in page load timer preferences.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.8.1 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 11/9/05 ~~~

* Users of locales which are not yet supported
will now see English instead of German as the
default locale.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.8.0 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 11/4/05 ~~~

* Prefetching URL comparisons are no longer case
sensitive.  This fixes several known bugs.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.7.9 ~~~~~~~~~~~~~~~~~~~~~~~~~~~ 10/26/05 ~~~

* Added Deutsch (de-DE) localization. Special 
thanks to Gerald Frankl and Oliver Roth.
* Added Castellano (es-ES) localization. Special 
thanks to Raul Gonzalez Duque.
* Updated Português-Brasil (pt-BR) localization.
Special thanks to Marcelo Ghelman.
* Increased max version to 1.5.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.7.8 ~~~~~~~~~~~~~~~~~~~~~~~~~~~ 10/19/05 ~~~

* Added Português-Brasil (pt-BR) localization. 
Special thanks to R. Nicolás López (aka MorZilla).
* Fixed bug which could cause user to get stuck
on a preferences tab in rare cases.  Special 
thanks to Bryan Burke for this bug fix.
* Updated several strings in the Italian locale.
* Tweaked row alignment in the preferences dialog.
* Added .jpeg, .text, and .xml to the list of 
extensions which are safe to prefetch.  Thanks to
Johnny Weare for this suggestion.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.7.7 ~~~~~~~~~~~~~~~~~~~~~~~~~~~ 10/16/05 ~~~

* Added Castellano-Argentina (es-AR) localization.  
Special thanks to R. Nicolás López (aka MorZilla).
* Added Français (fr-FR) localization.  Special
thanks to Xavier Robin.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.7.6 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 10/9/05 ~~~

* Added Japanese (ja-JP) localization.  Special
thanks to Norah.
* Fixed bug which caused the disable popups 
checkbox not to be populated when reopening the 
preferences if the last tab used was the popups 
tab.
* Added new strings into pl-PL locale.
* Localized the "Close" button in the about 
dialog.
* Corrected typo in HTTP connection prefs.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.7.5 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 10/9/05 ~~~

* Added Nederlands (nl-NL) localization.  Special
thanks to Liesbeth.
* Licensed Fasterfox under the MPL 1.1.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.7.4 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 10/7/05 ~~~

* Added Italiano (it-IT) localization.  Special
thanks to Giacomo Margarito.
* Fixed bug with pl-PL locale in Firefox 1.0.x.
Note, this bug was my mistake, the locale created 
by Leszek(teo)Zyczkowski was good.
* Localized extension description.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.7.3 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 10/6/05 ~~~

* Added support for Firefox 1.5 Beta 2.
* Fixed bug which caused some Firefox 1.0.x
users to get stuck on a tab after pressing the 
cancel button.  Special thanks to Karl for this
bug fix.
* Localized Page Load Timer.
* Added Polski (pl-PL) localization. Special
thanks to Leszek(teo)Zyczkowski.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.7.2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 10/4/05 ~~~

* Added Türkisch (tr-TR) localization.  Special 
thanks to Erkan Kaplan.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.7.1 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 10/4/05 ~~~

* Resolved compatibility conflict with the
"Forecastfox" extension.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.7.0 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 10/3/05 ~~~

* Added Fasterfox Page Load Timer to status bar.
* Fixed bug which caused settings to not be saved 
in Firefox 1.0.x if the OK button was pressed on a
preference pane other than Fasterfox.
* Now automatically opens to most recently used 
tab in Fasterfox preferences.
* Fixed bug which, in very rare cases, still 
causes logout page to be prefetched.  Special 
thanks to Kai Risku for this fix.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.6.5 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 9/26/05 ~~~

* Fixed bug which causes preferences to sometimes
not be saved properly in Firefox 1.5 Beta.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.6.4 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 9/26/05 ~~~

* Fixed bug which causes Fasterfox to log out the
user from certain websites.
* Now only prefetches static content with the 
extension htm, html, txt, pdf, gif, jpg, or png.
* As another measure to stop enhanced prefetching 
from following "logout" links, links which contain
the word "logout" or "logoff" are now ignored.
* All UI text has been extracted into DTDs and
an en-US localization has been created. Now seeking
translators for additional locales.
* Reorganized layout of cache tab.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.6.3 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 9/23/05 ~~~

* Fixed bug which caused advanced tabs to always 
be displayed in Firefox 1.5 Beta 1.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.6.2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 9/23/05 ~~~

* Fixed bug which sometimes caused advanced tabs 
to not be displayed when the "Custom" preset is
selected in Firefox 1.5 Beta 1.
* Added option to remove submenu delay.
* Resolved possible conflict with other extensions
which overlay the Firefox 1.5 Beta 1 Preferences.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.6.1 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 9/22/05 ~~~

* Added support for Firefox 1.5 Beta 1 (Deer 
Park).
* Now hides tabs for advanced options if "Custom" 
preset is not selected.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~~~ 0.5.8 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 9/21/05 ~~~

* Initial published release.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
