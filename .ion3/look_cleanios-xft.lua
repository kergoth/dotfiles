-- look_cleanios.lua drawing engine configuration file for Ion.

if not gr.select_engine("de") then return end

de.reset()

mainfont = "xft: Bitstream Vera Sans Mono-10"
boldfont = "xft: Bitstream Vera Sans Mono-10:weight=bold"
bigfont = "xft: Bitstream Vera Sans Mono-14"
bigboldfont = "xft: Bitstream Vera Sans Mono-14:weight=bold"

de.defstyle("*", {
    shadow_colour = "#ffffff",
    highlight_colour = "#ffffff",
    background_colour = "#d8d8d8",
    foreground_colour = "#000000",
    padding_colour = "#d8d8d8",
    padding_pixels = 0,
    highlight_pixels = 2,
    shadow_pixels = 2,
    spacing = 0,
    border_style = "elevated",
    font = mainfont,
    text_align = "center",
})

de.defstyle("frame", {
    based_on = "*",
    background_colour = "#e0e0e0",
    transparent_background = false,
})


de.defstyle("frame-tiled", {
    based_on = "frame",
    shadow_pixels = 0,
    highlight_pixels = 0,
    padding_pixels = 0,
    spacing = 1,
})

de.defstyle("tab", {
    based_on = "*",
    font = boldfont,
    de.substyle("active-selected", {
        shadow_colour = "#faff69",
        highlight_colour = "#faff69",
        background_colour = "#faff69",
        foreground_colour = "#000000",
--	foreground_colour = "#061644",
    }),
    de.substyle("active-unselected", {
        shadow_colour = "#f0f0f0",
        highlight_colour = "#f0f0f0",
        background_colour = "#f0f0f0", -- #d8d8d8",
        foreground_colour = "#000000",
    }),
    de.substyle("inactive-selected", {
        shadow_colour = "#eef196",
        highlight_colour = "#eef196",
        background_colour = "#eef196", -- #eaeca6",
        foreground_colour = "#000000",
    }),
    de.substyle("inactive-unselected", {
        shadow_colour = "#d8d8d8",
        highlight_colour = "#d8d8d8",
        background_colour = "#d8d8d8",
        foreground_colour = "#000000",
    }),
    text_align = "center",
})

de.defstyle("tab-frame", {
    based_on = "tab",
    de.substyle("*-*-*-*-activity", {
        shadow_colour = "#e0c0c0",
        highlight_colour = "#e0c0c0",
        background_colour = "#990000",
        foreground_colour = "#eeeeee",
    }),
--    de.substyle("active-selected", {
--        background_colour = "#ff0000",
--    }),
})

de.defstyle("tab-frame-tiled", {
    based_on = "tab-frame",
    spacing = 1,
})

de.defstyle("tab-menuentry", {
    based_on = "tab",
    text_align = "left",
    spacing = 1,
    font = boldfont,
})

de.defstyle("tab-menuentry-big", {
    based_on = "tab-menuentry",
    font = bigfont,
    padding_pixels = 0,
})

de.defstyle("input-edln", {
    based_on = "*",
    de.substyle("*-cursor", {
        background_colour = "#000000",
        foreground_colour = "#d8d8d8",
    }),
    de.substyle("*-selection", {
        background_colour = "#ffffff",
        foreground_colour = "#000000",
    }),
})

-- Settings common to some styles.

de.defstyle("stdisp", {
    based_on = "*",
    shadow_pixels = 0,
    highlight_pixels = 0,
    text_align = "left",
    background_colour = "#000000",
    foreground_colour = "grey",
    font=basefont,
    
  
    de.substyle("important", {
        foreground_colour = "green",
    }),

    de.substyle("critical", {
        foreground_colour = "red",
    }),
})

de.defstyle("actnotify", {
    based_on = "*",
    shadow_colour = "#e0c0c0",
    highlight_colour = "#e0c0c0",
    background_colour = "#990000",
    foreground_colour = "#eeeeee",
})

gr.refresh()

