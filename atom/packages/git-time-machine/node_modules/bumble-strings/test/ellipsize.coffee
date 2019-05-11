

BStr = require('../src/bumble-strings')

debugger

#                 1        10       20        30        40        50        60    66    
TEST_STRING =    "Fluffy his royal cuteness and purveyor of purrs, playing and love"
TEST_STRING_35 = "Fluffy his royal cuteness and pu..."

describe "elipsize()", ->

  it "should elipsize at arbitrary length", ->  
    BStr.elipsize(TEST_STRING, 35).should.equal TEST_STRING_35
  
  it "should not elipsize at end of string", ->
    BStr.elipsize(TEST_STRING, 66).should.equal TEST_STRING
  
  it "should not elipsize near end of string", ->
    BStr.elipsize(TEST_STRING, 65).should.equal TEST_STRING
  
  