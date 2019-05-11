
BStr = require('../src/bumble-strings')

debugger

# test value with extra spaces everywhere and imbedded uppercased word
MY_DOG = "  My dog,  Tommy,  is a    really smart  dog. "
STRONG_HAS = MY_DOG.slice(6, 15)
WEAK_HAS = BStr.trim(MY_DOG.slice(6, 20), all: true)

NON_MATCHING = ["smart cat", "smart unicorn.", "Somthing completely different"]

describe "has() & weaklyHas", ->
  
  it "should has itself", ->    # well, duh
    assert BStr.has(MY_DOG, MY_DOG), "with itself"
    assert BStr.has(MY_DOG, STRONG_HAS), "with a substring of itself"
    
  it "should not has weaker version of itself", ->
    assert !BStr.has(MY_DOG, WEAK_HAS)

  it "should not has any non matching as array or individually", ->
    testArray = NON_MATCHING.slice(0).concat([WEAK_HAS])
    assert !BStr.has(MY_DOG, testArray), "array of nonmatching strings"
    for nonMatch in NON_MATCHING
      assert !BStr.has(MY_DOG, nonMatch), "like not #{nonMatch}"

  it "should has one of an array", ->
    # inject a stong match into the middle of non matching
    testArray = NON_MATCHING.slice(0, 1).concat([STRONG_HAS]).concat(NON_MATCHING.slice(1))
    assert BStr.has(MY_DOG, testArray)
        
  it "should weaklyHas itself", ->    # well, duh
    assert BStr.weaklyHas(MY_DOG, STRONG_HAS)
    
  it "should weaklyHas weaker versions of itself", ->
    assert BStr.weaklyHas(MY_DOG, WEAK_HAS), "first 12 trimmed => #{WEAK_HAS}"
    assert BStr.weaklyHas(MY_DOG, WEAK_HAS.toLowerCase()), "first 12 trimmed and lowercased"
    assert BStr.weaklyHas(MY_DOG, " "), "single space at end"
    
  it "should weaklyHas one of an array", ->
    # inject a stong match into the middle of non matching
    testArray = NON_MATCHING.slice(0, 1).concat([STRONG_HAS]).concat(NON_MATCHING.slice(1))
    assert BStr.weaklyHas(MY_DOG, testArray), "should have found #{STRONG_HAS} in #{JSON.stringify(testArray)}"
    testArray = NON_MATCHING.slice(0).concat([WEAK_HAS])
    assert BStr.weaklyHas(MY_DOG, testArray), "should have found #{WEAK_HAS} in #{JSON.stringify(testArray)}"
    

  