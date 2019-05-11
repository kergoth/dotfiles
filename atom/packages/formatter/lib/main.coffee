{Disposable, CompositeDisposable} = require 'atom'
{Selector} = require 'selector-kit'
{specificity} = require 'clear-cut'
ProviderMetadata = require './provider-metadata'
stableSort = require 'stable'

class Module

  activate: ->
    @providerManager = new ProviderManager
    @disposible = new CompositeDisposable
    @registerCommands()
    return

  deactivate: ->
    @disposible.dispose()
    return

  registerCommands: () ->
    @disposible.add atom.commands.add('atom-text-editor', 'formatter:format-code', @formatCode)

  formatCode: =>
    editor = atom.workspace.getActiveTextEditor()
    cursor = editor.getLastCursor()
    return unless cursor?

    selection = editor.getSelectedBufferRange()
    if !selection.isEmpty()
      selection =
        start:
          line: selection.start.row
          col: selection.start.column
        end:
          line: selection.end.row
          col: selection.end.column
    else
      selection = null

    ## resolve provider by scope descriptor
    scopeDescriptor = cursor.getScopeDescriptor()
    providers = @providerManager.providersForScopeDescriptor(scopeDescriptor)
    return unless providers.length > 0

    # We only support the highest prirority provider for now:
    provider = providers[0]
    if provider.getCodeEdits
      edits = Promise.resolve(provider.getCodeEdits({editor,selection}))
      edits.then (edits) ->
        applyEdits(editor, edits)
    else if provider.getNewText
      text = editor.getSelectedText()
      if !text
        selected = false
        text = editor.getText();
      return if !text
      newText = Promise.resolve(provider.getNewText(text))
      newText.then (newText) ->
        if (selected)
          editor.replaceSelectedText(newText)
        else
          editor.setText(newText)
  ###
  Section: Services API
  ###
  consumeFormatter: (providers) ->
    providers = [providers] if providers? and not Array.isArray(providers)
    return unless providers?.length > 0
    registrations = new CompositeDisposable
    for provider in providers
      registrations.add @providerManager.registerProvider(provider)
    registrations




# Utility function to apply the edits
applyEdits = (editor,edits) ->
  editor.transact ->
    for edit in edits
      editor.setTextInBufferRange([[edit.start.line, edit.start.col], [edit.end.line, edit.end.col]], edit.newText);


# Manages scope resolution
## inspiration : https://github.com/atom-community/autocomplete-plus/blob/master/lib/provider-manager.coffee
class ProviderManager
  constructor: ->
    @providers = []

  registerProvider: (provider) ->
    return unless provider?
    providerMetadata = new ProviderMetadata(provider)
    @providers.push(providerMetadata)
    return providerMetadata

  providersForScopeDescriptor: (scopeDescriptor) =>
    scopeChain = scopeChainForScopeDescriptor(scopeDescriptor)
    return [] unless scopeChain

    matchingProviders = []
    lowestIncludedPriority = 0

    for providerMetadata in @providers
      {provider} = providerMetadata
      if providerMetadata.matchesScopeChain(scopeChain)
        matchingProviders.push(provider)
        if provider.excludeLowerPriority?
          lowestIncludedPriority = Math.max(lowestIncludedPriority, provider.inclusionPriority ? 0)

    matchingProviders = (provider for provider in matchingProviders when (provider.inclusionPriority ? 0) >= lowestIncludedPriority)
    stableSort matchingProviders, (providerA, providerB) =>
      specificityA = @metadataForProvider(providerA).getSpecificity(scopeChain)
      specificityB = @metadataForProvider(providerB).getSpecificity(scopeChain)
      difference = specificityB - specificityA
      difference = (providerB.suggestionPriority ? 1) - (providerA.suggestionPriority ? 1) if difference is 0
      difference


# TODO: most of this is temp code to understand autocomplete-plus #308
# Taken from autocomplete-plus
scopeChainForScopeDescriptor = (scopeDescriptor) ->
  type = typeof scopeDescriptor
  if type is 'string'
    scopeDescriptor
  else if type is 'object' and scopeDescriptor?.getScopeChain?
    scopeChain = scopeDescriptor.getScopeChain()
    if scopeChain? and not scopeChain.replace?
      json = JSON.stringify(scopeDescriptor)
      console.log scopeDescriptor, json
      throw new Error("01: ScopeChain is not correct type: #{type}; #{json}")
    scopeChain
  else
    json = JSON.stringify(scopeDescriptor)
    console.log scopeDescriptor, json
    throw new Error("02: ScopeChain is not correct type: #{type}; #{json}")


module.exports = new Module
