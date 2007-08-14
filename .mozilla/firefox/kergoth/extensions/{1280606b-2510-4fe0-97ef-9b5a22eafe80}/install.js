var XpiInstaller = {
	extFullName: "Console²",
	extShortName: "console2",
	extVersion: "0.3.7",
	extAuthor: "zeniko",
	extLocaleNames: ["en-US", "bg-BG", "cs-CZ", "de-CH", "de-DE", "es-ES",
	                 "fr-FR", "it-IT", "ja-JP", "lt-LT", "nl-NL", "pl-PL",
	                 "pt-BR", "ru-RU", "sk-SK", "en-GB"],
	extSkinNames: ["classic"],
	extComponents: ["console2-clhandler.js"],
	extPostInstallMessage: null,
	
	profileInstall: true,
	silentInstall: false,

	install: function()
	{
		if (Install.arguments && (Install.arguments == "p=0" || Install.arguments == "p=1"))
		{
			this.profileInstall = (Install.arguments == "p=1");
			this.silentInstall = true;
		}
		
		var jarName = this.extShortName + ".jar";
		var profileDir = Install.getFolder("Profile", "chrome");
		
		if (File.exists(Install.getFolder(profileDir, jarName)))
		{
			if (!this.silentInstall)
			{
				Install.alert("Updating existing Profile install of " + this.extFullName + " to version " + this.extVersion + ".");
			}
			this.profileInstall = true;
		}
		else if (!this.silentInstall)
		{
			this.profileInstall = Install.confirm("Install " + this.extFullName + " " + this.extVersion + " to your Profile directory (OK) or your Browser directory (Cancel)?");
		}
		
		var dispName = this.extFullName + " " + this.extVersion;
		var regName = "/" + this.extAuthor + "/" + this.extShortName;
		Install.initInstall(dispName, regName, this.extVersion);
		
		var installPath = (this.profileInstall)?profileDir:Install.getFolder("chrome");
		
		Install.addFile(null, "chrome/" + jarName, installPath, null);
		
		var jarPath = Install.getFolder(installPath, jarName);
		var installType = (this.profileInstall)?Install.PROFILE_CHROME:Install.DELAYED_CHROME;
		
		Install.registerChrome(Install.CONTENT | installType, jarPath, "content/" + this.extShortName + "/");
		
		for (var locale in this.extLocaleNames)
		{
			var regPath = "locale/" + this.extLocaleNames[locale] + "/" + this.extShortName + "/";
			Install.registerChrome(Install.LOCALE | installType, jarPath, regPath);
		}
		for (var skin in this.extSkinNames)
		{
			var regPath = "skin/" + this.extSkinNames[skin] + "/" + this.extShortName + "/";
			Install.registerChrome(Install.SKIN | installType, jarPath, regPath);
		}
		
		if (!this.profileInstall)
		{
			installPath = Install.getFolder("Components");
			for (var comp in this.extComponents)
			{
				Install.addFile(null, "components/" + this.extComponents[comp], installPath, null);
			}
		}

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
			if (!this.silentInstall)
			{
				Install.alert("Error: Could not install " + this.extFullName + " " + this.extVersion + " (Error code: " + err + ")");
			}
			Install.cancelInstall(err);
		}
	}
};

XpiInstaller.install();
