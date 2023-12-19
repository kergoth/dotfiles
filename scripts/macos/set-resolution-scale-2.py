#!/usr/bin/env python3

import display_manager_lib as dm

display = dm.getMainDisplay()
if display.isHidpi:
    mode = display.currentMode
    modes = sorted((m for m in display.allModes if m.hidpi), reverse=True)[:5]
    selected = modes[2]
    if selected != mode:
        display.setMode(selected)
