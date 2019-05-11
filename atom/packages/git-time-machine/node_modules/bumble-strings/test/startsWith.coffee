
BStr = require('../src/bumble-strings')

debugger

# test value with extra spaces everywhere and imbedded uppercased word
MY_DOG = "  My dog,  Tommy,  is a    really smart  dog. "
STRONG_START = MY_DOG.slice(0, 12)
WEAK_START = BStr.trim(MY_DOG).slice(0, 12)

NON_MATCHING = ["MY cat", "my unicorn", "Somthing completely different"]


describe "startsWith() & weaklyStartsWith", ->
  
  it "should startsWith itself", ->    # well, duh
    assert BStr.startsWith(MY_DOG, MY_DOG)
    assert BStr.startsWith(MY_DOG, STRONG_START)
    assert BStr.startsWith(MY_DOG, "  "),  "two spaces"
    
  it "should not startsWith weaker version of itself", ->
    assert !BStr.startsWith(MY_DOG, WEAK_START)

  it "should not startsWith any non matching as array or individually", ->
    testArray = NON_MATCHING.slice(0).push(WEAK_START)
    assert !BStr.startsWith(MY_DOG, testArray), "array of nonmatching strings"
    for nonMatch in NON_MATCHING
      assert !BStr.startsWith(MY_DOG, nonMatch), "like not #{nonMatch}"

  it "should startsWith one of an array", ->
    # inject a stong match into the middle of non matching
    testArray = NON_MATCHING.slice(0, 1).concat([STRONG_START]).concat(NON_MATCHING.slice(1))
    assert BStr.startsWith(MY_DOG, testArray)
        
  it "should weaklyStartsWith itself", ->    # well, duh
    assert BStr.weaklyStartsWith(MY_DOG, STRONG_START)
    
  it "should weaklyStartsWith weaker versions of itself", ->
    assert BStr.weaklyStartsWith(MY_DOG, WEAK_START), "first 12 trimmed => #{WEAK_START}"
    assert BStr.weaklyStartsWith(MY_DOG, WEAK_START.toLowerCase()), "first 12 trimmed and lowercased"
    assert BStr.weaklyStartsWith(MY_DOG, "  "), "two spaces"
    
  it "should weaklyStartsWith one of an array", ->
    # inject a stong match into the middle of non matching
    testArray = NON_MATCHING.slice(0, 1).concat([STRONG_START]).concat(NON_MATCHING.slice(1))
    assert BStr.weaklyStartsWith(MY_DOG, testArray), "should have found #{STRONG_START} in #{JSON.stringify(testArray)}"
    testArray = NON_MATCHING.slice(0).concat([WEAK_START])
    assert BStr.weaklyStartsWith(MY_DOG, testArray), "should have found #{WEAK_START} in #{JSON.stringify(testArray)}"
    

  