/* install.js, for Cute Menus 
 * borrowed from the Tabbrowser Preferences extension
 */

var author      = "Shivanand Sharma AKA Varun"
var displayname = "Colorful Tabs";
var version     = "1.8";
var packagename = "clrtabs";
var packagefile = packagename + ".jar";

var destDir     = getFolder( "Profile" );
var cflag       = CONTENT | PROFILE_CHROME;
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
	alert("Please restart for the changes to take effect.");
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