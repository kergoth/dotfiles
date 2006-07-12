dopath("look_asm-xft")
-- dopath("look_brownsteel-xft")
-- dopath("look_cleanviolet")


defbindings("WMPlex", {
    bdoc("Run a terminal emulator."),
    kpress(ALTMETA.."F2", "ioncore.exec_on(_, 'urxvtc')"),
})
dopath("vim_bindings")

dopath("mod_statusbar")
-- dopath("mod_dock")

defwinprop{
    class = "Gaim",
    target = "Floating",
}

defwinprop{
    class = "Firefox-bin",
    target = "Floating",
}

defwinprop{
    name = "Last.fm Player",
    target = "Floating",
}

defwinprop{
    class = "Gimp",
    target = "Floating",
}

-- dopath("histcompl")
dopath("detach")
detach.setup_hooks()

dopath("cfg_menu")
