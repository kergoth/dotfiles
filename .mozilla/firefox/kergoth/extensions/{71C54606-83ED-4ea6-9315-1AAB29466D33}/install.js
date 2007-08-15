/* install.js, for Cute Menus 
 * borrowed from the Tabbrowser Preferences extension
 */

var author      = "Varun Sharma"
var displayname = "CuteMenus 2";
var version     = "2.0";
var packagename = "cutemenus";
var packagefile = packagename + ".jar";

var themedir    = "CuteMenus Themes";
var destDir     = getFolder( "Profile" );

var cflag       = CONTENT | PROFILE_CHROME;
var lflag	= LOCALE | PROFILE_CHROME;
var error       = null;
var installdir  = getFolder("Profile", "chrome");
var location    = getFolder(installdir, packagefile);
var folder      = null;

var msg = displayname + " " + version + " only installs into the profile directory. (OK) to continue or (Cancel) to abort the installation?";
if(!confirm(msg))
	{
	cancelInstall();
	}
else
{

// Begin the installation
initInstall(displayname + " " + version, "/" + author + "/" + displayname, version);

//if (File.exists(location)) {
//   alert("Sorry, " + displayname + " is already installed in the location you have chosen.");
//   cancelInstall();
//}

// Configure the JAR file
setPackageFolder(installdir);
error = addFile(packagename, version, "chrome/" + packagefile, installdir, null);

// Configure the theme directory
if (error == SUCCESS) 
	{
	var themeDir = getFolder(installdir, themedir);
	var jarDir = "chrome/" + themedir;
	destDir = getFolder( getFolder( destDir, "extensions"), "{71C54606-83ED-4ea6-9315-1AAB29466D33}" );
	destDir = getFolder( getFolder( destDir, "chrome"), themedir );
	//error = addDirectory(packagename, version, themedir, themeDir, null);
	error = addDirectory(packagename, version, jarDir, destDir, null, true);
	if (error != SUCCESS) 
		{
		//alert("Sorry, but " + displayname + " could not create the " + themedir + " directory.");
		alert("Sorry, but " + displayname + " could not create the " + destDir + " directory.\n" +
		"Source: " + jarDir + "\n error: " + error);
		cancelInstall();
		}
	}

if (error == SUCCESS) 
	{
  	folder = getFolder(installdir, packagefile);
  	// Register the chrome content and locale data
	error = registerChrome(cflag, folder, "content/");
	registerChrome(lflag, folder, 'locale/en-US/');
  	registerChrome(lflag, folder, 'locale/it-IT/');
	registerChrome(lflag, folder, 'locale/de-DE/');
	registerChrome(lflag, folder, 'locale/fr-FR/');
	registerChrome(lflag, folder, 'locale/ru-RU/');
	registerChrome(lflag, folder, 'locale/ro-RO/');
	registerChrome(lflag, folder, 'locale/pl-PL/');
  	// Install the extension
	if (error == SUCCESS)
		{
		error = performInstall();
		if (error==999) 
			{
			//alert("An error occured during installation !\nErrorcode: " + error);
			//alert("Please restart Mozilla to update the changes.");
			}
  		}
  	else
  		{
    		alert("An error occurred, installation will be cancelled.\nErrorcode: " + error);
    		cancelInstall(error);
  		}
	}
}