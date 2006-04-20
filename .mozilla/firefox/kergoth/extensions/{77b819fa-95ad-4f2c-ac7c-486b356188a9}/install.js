const APP_NAME = "ietab";
const APP_PACKAGE = "ietab.mozdev.org";
const APP_DISPLAY_NAME = "IE Tab";
const APP_JAR_FILE = "ietab.jar";
const APP_PREF_FILE = "ietab.js"

const APP_VERSION = "1.0.9";
const APP_LOCALES = ["en-US", "ca-AD", "cs-CZ", "da-DK", "de-DE", "es-ES", "fi-FI", "fr-FR", "he-IL", "it-IT", "ja-JP", "ko-KR", "nl-NL", "pl-PL", "pt-BR", "ru-RU", "sk-SK", "sl-SI", "sv-SE", "tr-TR", "zh-CN", "zh-TW"];

const APP_SUCCESS_MESSAGE = "After you restart Mozilla ...\n"
   + "Tip1. You can use View->Hide/Show to add an IE Tab toolbar button.\n"
   + "Tip2. IE Tab should be available on the page/link's Context Menu.";

initInstall(APP_NAME, APP_PACKAGE, APP_VERSION);

var err = addDirectory(APP_PACKAGE, APP_VERSION, "plugins", getFolder("plugins"), null);

if (err == SUCCESS)
{
   err = addDirectory(APP_PACKAGE, APP_VERSION, "components", getFolder("components"), null);
}

if (err == SUCCESS)
{
   err = addFile(APP_PACKAGE, APP_VERSION, "chrome/" + APP_JAR_FILE, getFolder("chrome"), null);
}

if (err == SUCCESS)
{
   err = addFile(APP_PACKAGE, APP_VERSION, "defaults/preferences/" + APP_PREF_FILE, getFolder(getFolder(getFolder("Program"),"defaults"),"pref"), null);
}

if (err == SUCCESS)
{
   const chromeFlag = DELAYED_CHROME;
   var jar = getFolder(getFolder("chrome"), APP_JAR_FILE);

   registerChrome(CONTENT | chromeFlag, jar, "content/");
   registerChrome(SKIN | chromeFlag, jar, "skin/");

   for (var i=0 ; i<APP_LOCALES.length ; i++)
   {
      registerChrome(LOCALE | chromeFlag, jar, "locale/" + APP_LOCALES[i] + "/" + APP_NAME + "/");
   }

   err = performInstall();

   if (err == SUCCESS || err == 999)
   {
      alert(APP_DISPLAY_NAME + " " + APP_VERSION + " has been succesfully installed.\n"
          + APP_SUCCESS_MESSAGE);
   }
   else
   {
      alert("Install failed! Error code: " + err);
      cancelInstall(err);
   }
}
else
{
   alert("Failed to install " + APP_DISPLAY_NAME + " " + APP_VERSION + "\n"
       + "You probably don't have appropriate permissions \n"
       + "(write access to phoenix/chrome directory).\n");
   cancelInstall(err);
}
