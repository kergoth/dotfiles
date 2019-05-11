

BStr = require('../src/bumble-strings')

debugger

MY_DOG = "  My dog,  Tommy,  is a    really smart  dog. "
MY_DOG_TRIM = "My dog,  Tommy,  is a    really smart  dog."
MY_DOG_TRIM_ALL = "My dog, Tommy, is a really smart dog."


describe "trim()", ->

  it "should not remove inner spaces unless asked", ->
    BStr.trim(MY_DOG).should.equal MY_DOG_TRIM

  it "should remove inner spaces if asked nicely", ->
    BStr.trim(MY_DOG, all: true).should.equal MY_DOG_TRIM_ALL
