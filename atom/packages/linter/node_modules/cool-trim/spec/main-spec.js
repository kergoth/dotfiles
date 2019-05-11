'use babel'

import trim from '../'

describe('Trim', function() {
  it('removes leading and ending newlines', function() {
    expect(trim(`
      Hey

      `)).toBe('Hey')
  })
  it('removes extra whitespaces properly', function() {
    expect(trim(`
      Hey
      Man
    `)).toBe('Hey\nMan')
  })
  it('acts as we expect it to', function() {
    expect(trim(`
      Hey
        Man
      `)).toBe('Hey\n  Man')
  })
  it('is smart', function() {
    expect(trim('Hey\nMan')).toBe('Hey\nMan')
    expect(trim('Hey\n  Man')).toBe('Hey\n  Man')
    expect(trim('  Hey\nMan')).toBe('  Hey\nMan')
    expect(trim('Main')).toBe('Main')
  })
  it('adds indention on request', function() {
    expect(trim(`
      Everything is
        awesome
      `, 2)).toBe('  Everything is\n    awesome')
  })
  it('works well with tagged templates', function() {
    expect(trim`
      Everything is
        awesome
    `).toBe('Everything is\n  awesome')
    expect(trim`
      Come on
      ${'Dolly'}
        Come on
    `).toBe('Come on\nDolly\n  Come on')
  })
  it('it works with tab characters', function() {
    expect(trim`
		Everything is
		awesome
	`).toBe('Everything is\nawesome')
    expect(trim`
		Everything is
			awesome
		`).toBe('Everything is\n\tawesome')
    expect(trim`
	  Everything is
		awesome
	 `).toBe(' Everything is\nawesome')
  })
})
