
BStr = require('../src/bumble-strings')

debugger

# test value with extra spaces everywhere and imbedded uppercased word
MY_DOG = "  My dog,  Tommy,  is a    really smart  dog. "
STRONG_ENDING = MY_DOG.slice(-12)
WEAK_ENDING = BStr.trim(MY_DOG).slice(-12)


NON_MATCHING = ["smart cat", "smart unicorn.", "Somthing completely different"]


describe "endsWith() & weaklyEndsWith", ->
  
  it "should endsWith itself", ->    # well, duh
    assert BStr.endsWith(MY_DOG, MY_DOG), "with itself"
    assert BStr.endsWith(MY_DOG, STRONG_ENDING), "with it's own ending"
    assert BStr.endsWith(MY_DOG, " "),  "single space at end"
    
  it "should not endsWith weaker version of itself", ->
    assert !BStr.endsWith(MY_DOG, WEAK_ENDING)

  it "should not endsWith any non matching as array or individually", ->
    testArray = NON_MATCHING.slice(0).concat([WEAK_ENDING])
    assert !BStr.endsWith(MY_DOG, testArray), "array of nonmatching strings"
    for nonMatch in NON_MATCHING
      assert !BStr.endsWith(MY_DOG, nonMatch), "like not #{nonMatch}"

  it "should endsWith one of an array", ->
    # inject a stong match into the middle of non matching
    testArray = NON_MATCHING.slice(0, 1).concat([STRONG_ENDING]).concat(NON_MATCHING.slice(1))
    assert BStr.endsWith(MY_DOG, testArray)
        
  it "should weaklyEndsWith itself", ->    # well, duh
    assert BStr.weaklyEndsWith(MY_DOG, STRONG_ENDING)
    
  it "should weaklyEndsWith weaker versions of itself", ->
    assert BStr.weaklyEndsWith(MY_DOG, WEAK_ENDING), "first 12 trimmed => #{WEAK_ENDING}"
    assert BStr.weaklyEndsWith(MY_DOG, WEAK_ENDING.toLowerCase()), "first 12 trimmed and lowercased"
    assert BStr.weaklyEndsWith(MY_DOG, " "), "single space at end"
    
  it "should weaklyEndsWith one of an array", ->
    # inject a stong match into the middle of non matching
    testArray = NON_MATCHING.slice(0, 1).concat([STRONG_ENDING]).concat(NON_MATCHING.slice(1))
    assert BStr.weaklyEndsWith(MY_DOG, testArray), "should have found #{STRONG_ENDING} in #{JSON.stringify(testArray)}"
    testArray = NON_MATCHING.slice(0).concat([WEAK_ENDING])
    assert BStr.weaklyEndsWith(MY_DOG, testArray), "should have found #{WEAK_ENDING} in #{JSON.stringify(testArray)}"
    

  