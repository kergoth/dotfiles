
Fs = require 'fs'
Path = require 'path'

GitLogUtils = require('../src/git-log-utils')

expectedCommitsForFile = require './data/expectedCommitsForFile'
expectedCommitsForDir = require './data/expectedCommitsForDir'

debugger

describe "GitUtils", ->

  describe "when loading file history for known file in git", ->

    beforeEach ->
      testFileName = Path.join __dirname, 'lib', 'fiveCommits.txt'
      @testdata = GitLogUtils.getCommitHistory testFileName

    it "should have 5 commits", ->
      @testdata.length.should.equal(5)

    it "first 5 commits should match last known good", ->
      expect(@testdata).toHaveKnownValues(expectedCommitsForFile)
      
  describe "when loading history for a directory", ->
    beforeEach ->
      testFileName = Path.join __dirname, '..'
      @testdata = GitLogUtils.getCommitHistory testFileName

    it "should have more then 5 commits", ->
      expect(@testdata.length).to.be.above(5)

    it "the 5 commits to test file should be in the commit data", ->
      expect(@testdata).toHaveKnownValues(expectedCommitsForDir)
      