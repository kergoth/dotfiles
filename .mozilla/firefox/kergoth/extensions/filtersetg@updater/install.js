// install.js
// XpiInstaller
// By Pike (Heavily inspired by code from Henrik Gemal and Stephen Clavering)

var XpiInstaller = {
	// --- Editable items begin ---
	extFullName: 'Filterset.G Updater', // The name displayed to the user (don't include the version)
	extShortName: 'fgupdater', // The leafname of the JAR file (without the .jar part)
	extVersion: '0.3.1.0',
	extAuthor: 'Michael McDonald and Reid Rankin',
	extLocaleNames: ['en-US', 'ar', 'be-BY', 'bg-BG', 'ca-AD', 'cs-CZ', 'da-DK', 'de-DE', 'es-AR', 'es-CL', 'es-ES', 'et-EE', 'fa-IR', 'fi-FI', 'fr-FR', 'hr-HR', 'hu-HU', 'it-IT', 'ja-JP', 'ko-KR', 'nb-NO', 'nl-NL', 'pl-PL', 'pt-BR', 'pt-PT', 'ro-RO', 'ru-RU', 'sk-SK', 'sl-SI', 'sv-SE', 'tr-TR', 'zh-CN', 'zh-TW'], // e.g. ['en-US', 'en-GB']
	extSkinNames: ['classic'], // e.g. ['classic', 'modern']
	extPostInstallMessage: null, // Set to null for no post-install message
	// --- Editable items end ---
	
	profileInstall: true,
	silentInstall: false,
	updating: false,
	
	install: function()
	{
		var jarName = this.extShortName + '.jar';
		var profileDir = Install.getFolder('Profile', 'chrome');
		
		// Parse HTTP arguments
		this.parseArguments();
		
		// Check if extension is already installed in profile
		if (File.exists(Install.getFolder(profileDir, jarName)))
		{
			this.updating = true;
			
			if (!this.silentInstall)
			{
				Install.alert('Updating existing Profile install of' + ' ' + this.extFullName + ' ' + 'to version' + ' ' + this.extVersion + '.');
			}
			this.profileInstall = true;
		}
		else if (!this.silentInstall)
		{
			// Ask user for install location, profile or browser dir?
			this.profileInstall = Install.confirm('Install' + ' ' + this.extFullName + ' ' + this.extVersion + ' ' + 'to your Profile directory (OK) or your Browser directory (Cancel)?');
		}
		
		// Init install
		var dispName = this.extFullName + ' ' + this.extVersion;
		var regName = '/' + this.extAuthor + '/' + this.extShortName;
		Install.initInstall(dispName, regName, this.extVersion);
		
		// Find directory to install into
		var installPath;
		if (this.profileInstall) installPath = profileDir;
		else installPath = Install.getFolder('chrome');
		
		// Add JAR file
		Install.addFile(null, 'chrome/' + jarName, installPath, null);
		Install.addFile(null, "chrome/extuninstallapi.jar", installPath, null);
		
		// Add prefs file
		var prefDir = (this.profileInstall) ? getFolder(getFolder('Profile'),'pref') : getFolder(getFolder(getFolder('Program'),'defaults'),'pref');
		if (!File.exists(prefDir)) File.dirCreate(prefDir);
		Install.addFile(null, 'defaults/preferences/' + this.extShortName + '.js', prefDir, null);
		
		// Register chrome
		var jarPath = Install.getFolder(installPath, jarName);
		var installType = this.profileInstall ? Install.PROFILE_CHROME : Install.DELAYED_CHROME;
		
		// Register content
		Install.registerChrome(Install.CONTENT | installType, jarPath, 'content/');
		Install.registerChrome(Install.CONTENT | installType, Install.getFolder(installPath, "extuninstallapi.jar"), "content/");
		
		// Register locales
		for (var locale in this.extLocaleNames)
		{
			var regPath = ((this.extLocaleNames[locale] == 'en-US') ? 'content/' : 'locale/') + this.extLocaleNames[locale] + '/';
			Install.registerChrome(Install.LOCALE | installType, jarPath, regPath);
		}
		
		// Register skins
		for (var skin in this.extSkinNames)
		{
			var regPath = 'skin/' + this.extSkinNames[skin] + '/';
			Install.registerChrome(Install.SKIN | installType, jarPath, regPath);
		}
		
		// Perform install
		var err = Install.performInstall();
		if (err == Install.SUCCESS || err == Install.REBOOT_NEEDED)
		{
			if (!this.silentInstall && this.extPostInstallMessage)
			{
				Install.alert(this.extPostInstallMessage);
			}
		}
		else
		{
			this.handleError(err);
			return;
		}
	},
	
	parseArguments: function()
	{
		// Can't use string handling in install, so use if statement instead
		var args = Install.arguments;
		if (args == 'p=0')
		{
			this.profileInstall = false;
			this.silentInstall = true;
		}
		else if (args == 'p=1')
		{
			this.profileInstall = true;
			this.silentInstall = true;
		}
	},
	
	handleError: function(err)
	{
		if (!this.silentInstall)
		{
			var message = 'Error: Could not install' + ' ' + this.extFullName + ' ' + this.extVersion + ' (' + 'Error code:' + ' ' + err + ').';
			if (this.updating) message += '\nTry uninstalling first.';
			Install.alert(message);
		}
		Install.cancelInstall(err);
	}
};

XpiInstaller.install();
