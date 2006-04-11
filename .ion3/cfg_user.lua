dopath("look_asm-xft")
-- dopath("look_brownsteel-xft")
-- dopath("look_cleanviolet")

defbindings("WMPlex", {
    bdoc("Run a terminal emulator."),
    kpress(ALTMETA.."F2", "ioncore.exec_on(_, 'urxvtc')"),
})

dopath("mod_statusbar")
-- dopath("mod_dock")
