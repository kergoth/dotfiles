settings =
  config:
    scheme:
      type: 'string'
      default: 'Default'
      enum: [
        "3024"
        "Apathy"
        "Ashes"
        "Atelier Cave"
        "Atelier Dune"
        "Atelier Estuary"
        "Atelier Forest"
        "Atelier Heath"
        "Atelier Lakeside"
        "Atelier Plateau"
        "Atelier Savanna"
        "Atelier Seaside"
        "Atelier Sulphurpool"
        "Bespin"
        "Brewer"
        "Bright"
        "Chalk"
        "Codeschool"
        "Colors"
        "Darktooth"
        "Default"
        "Eighties"
        "Embers"
        "Flat"
        "GitHub"
        "Google"
        "Grayscale"
        "Greenscreen"
        "Harmonic"
        "Hopscotch"
        "Irblack"
        "Isotope"
        "Macintosh"
        "Marrakesh"
        "Materia"
        "Mocha"
        "Monokai"
        "Ocean"
        "OceanicNext"
        "OneDark"
        "Paraiso"
        "PhD"
        "Pico"
        "Pop"
        "Railscasts"
        "Seti"
        "Shapeshifter"
        "Solarflare"
        "Solarized"
        "Spacemacs"
        "Summerfruit"
        "Tomorrow"
        "Tube"
        "Twilight"
        "Unikitty"
        "Yesterday Bright"
        "Yesterday Night"
        "Yesterday"
      ]
    style:
      type: 'string'
      default: 'Dark'
      enum: ["Dark", "Light"]
    matchUserInterfaceTheme:
      type: 'boolean'
      default: true
      description: "When enabled the style will be matched to the current UI theme by default."

module.exports = settings
