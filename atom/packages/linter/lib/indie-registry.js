/* @flow */

import { Emitter, CompositeDisposable } from 'atom'
import type { Disposable } from 'atom'

import IndieDelegate from './indie-delegate'
import { indie as validateIndie } from './validate'
import type { Indie } from './types'

class IndieRegistry {
  emitter: Emitter;
  delegates: Set<IndieDelegate>;
  subscriptions: CompositeDisposable;

  constructor() {
    this.emitter = new Emitter()
    this.delegates = new Set()
    this.subscriptions = new CompositeDisposable()

    this.subscriptions.add(this.emitter)
  }
  // Public method
  register(config: Indie, version: 1 | 2): IndieDelegate {
    if (!validateIndie(config)) {
      throw new Error('Error registering Indie Linter')
    }
    const indieLinter = new IndieDelegate(config, version)
    this.delegates.add(indieLinter)
    indieLinter.onDidDestroy(() => {
      this.delegates.delete(indieLinter)
    })
    indieLinter.onDidUpdate((messages) => {
      this.emitter.emit('did-update', { linter: indieLinter, messages })
    })
    this.emitter.emit('observe', indieLinter)

    return indieLinter
  }
  getProviders() {
    return Array.from(this.delegates)
  }
  observe(callback: Function): Disposable {
    this.delegates.forEach(callback)
    return this.emitter.on('observe', callback)
  }
  onDidUpdate(callback: Function): Disposable {
    return this.emitter.on('did-update', callback)
  }
  dispose() {
    for (const entry of this.delegates) {
      entry.dispose()
    }
    this.subscriptions.dispose()
  }
}

module.exports = IndieRegistry
