
BStr = require('../src/bumble-strings')

debugger

# test value with extra spaces everywhere and imbedded uppercased word
MY_DOG = "  My dog,  Tommy,  is a    really smart  dog. "


describe "weaklyEqual()", ->
  it "should weakly equal itself", ->  
    assert BStr.weaklyEqual(MY_DOG, MY_DOG)
  
  it "should weakly equal itself lower cased", ->  
    assert BStr.weaklyEqual(MY_DOG, MY_DOG.toLowerCase())
  
  it "should weakly equal itself trimmed", ->  
    assert BStr.weaklyEqual(MY_DOG, BStr.trim(MY_DOG)), "trimmed"
    assert BStr.weaklyEqual(MY_DOG, BStr.trim(MY_DOG).toLowerCase()), "trimmed and lowercased"
    assert BStr.weaklyEqual(MY_DOG, MY_DOG.slice(1)), "itself with 1 leading space removed"
    assert BStr.weaklyEqual(MY_DOG, MY_DOG.slice(0, -1)), "itself with 1 trailing space removed"
  
  it "should not weakly equal part of itself", -> 
    assert !BStr.weaklyEqual(MY_DOG, BStr.trim(MY_DOG).slice(0, -1)), "trimmed and length -1"
    assert !BStr.weaklyEqual(MY_DOG, BStr.trim(MY_DOG).slice(0, -2)), "trimmed and length -2"
    assert !BStr.weaklyEqual(MY_DOG, BStr.trim(MY_DOG).slice(1)), "trimmed and start + 1"
    assert !BStr.weaklyEqual(MY_DOG, BStr.trim(MY_DOG).slice(2)), "trimmed and start + 2"
    
  it "should not weakly equal something completely different", ->
    assert !BStr.weaklyEqual(MY_DOG, "SOMEthing completely different!")
    
    
  it "should not weakly equal any of array without matches", ->
    assert !BStr.weaklyEqual(MY_DOG, ["gibberish", "garbage", "SOMEthing completely different!"])
    
    
  it "should weakly equal if any of array with a single match", ->
    assert BStr.weaklyEqual(MY_DOG, ["gibberish", "garbage", MY_DOG.toLowerCase(), 
      "SOMEthing completely different!"])
    
    
    
    
