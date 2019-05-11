{SelectListView} = require 'atom-space-pen-views'

class Base16SelectListView extends SelectListView

  initialize: (@base16) ->
    super
    @list.addClass 'mark-active'
    @setItems @getThemes()

  viewForItem: (theme) ->
    element = document.createElement 'li'
    if @base16.isConfigTheme theme.scheme, theme.style
      element.classList.add 'active'
    element.textContent = theme.name
    element

  getFilterKey: ->
    'name'

  selectItemView: (view) ->
    super
    theme = @getSelectedItem()
    @base16.isPreview = true
    @base16.enableTheme theme.scheme, theme.style if @attached

  confirmed: (theme) ->
    @confirming = true
    @base16.isPreview = false
    @base16.isPreviewConfirmed = true
    @base16.setThemeConfig theme.scheme, theme.style
    @cancel()
    @confirming = false

  cancel: ->
    super
    @base16.enableConfigTheme() unless @confirming
    @base16.isPreview = false
    @base16.isPreviewConfirmed = false

  cancelled: ->
    @panel?.destroy()

  attach: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @selectItemView @list.find 'li:last'
    @selectItemView @list.find '.active'
    @focusFilterEditor()
    @attached = true

  getThemes: ->
    schemes = atom.config.getSchema("#{@base16.packageName}.scheme").enum
    if atom.config.get "#{@base16.packageName}.matchUserInterfaceTheme"
      styles = [atom.config.defaultSettings["#{@base16.packageName}"].style]
    else
      styles = atom.config.getSchema("#{@base16.packageName}.style").enum
    themes = []
    schemes.forEach (scheme) -> styles.forEach (style) ->
      themes.push scheme: scheme, style: style, name: "#{scheme} (#{style})"
    themes

module.exports = Base16SelectListView
