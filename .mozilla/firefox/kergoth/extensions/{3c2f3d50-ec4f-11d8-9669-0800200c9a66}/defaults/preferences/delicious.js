// The extension needs to be reinstalled for changes in these to take effect.

// Display internal shortcut
pref("extensions.delicious.keyconf.devmode", false);

// Reverse the order in which submenu names are used, defaults are:
// Thunderbird       "Menu > Menuitem"
// Others            "Menuitem [Menu]"
pref("extensions.delicious.keyconf.nicenames.reverse_order", false);

// Use another keyconfig profile, can be used to temporary disable all keys
pref("extensions.delicious.keyconf.profile", "main");

// Disables the warning if you close the window
pref("extensions.delicious.keyconf.warnOnClose", false);

// Disables the warning if an already used key was entered
pref("extensions.delicious.keyconf.warnOnDuplicate", true);
