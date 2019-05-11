'use babel'

import tag from '../'
import escape from 'escape-html'

describe('tagged-template-literals', function() {
  function proxy(strings, ...values) {
    return tag(strings, values)
  }
  function escapingProxy(strings, ...values) {
    return tag(strings, values, escape)
  }

  it('merges strings and values properly', function() {
    expect(proxy`Hello ${'Dolly'}`).toBe('Hello Dolly')
  })
  it('works well even on all value stuff', function() {
    expect(proxy`${'Hello'}`).toBe('Hello')
  })
  it('works well even on all string stuff', function() {
    expect(proxy`Hello Dolly`).toBe('Hello Dolly')
  })
  it('works well with filtering callbacks', function() {
    expect(escapingProxy`Hello ${'<div />'}`).toBe('Hello &lt;div /&gt;')
  })
  it('works with random stuff', function() {
    expect(proxy`Hello ${'Dolly'} This ${'is'} Steel`).toBe('Hello Dolly This is Steel')
  })
})
