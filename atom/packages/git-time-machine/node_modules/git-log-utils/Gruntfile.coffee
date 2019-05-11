
###
  This is the minimal bumble-build Gruntfile.   You can tweek what BumbleBuild 
  returns below to customize 
###
_ = require 'underscore'

BumbleBuild = require('bumble-build')

module.exports = (grunt) -> 
  bbConfig = BumbleBuild.gruntConfig(grunt)
  
  shellConfig = grunt.config.get('shell')
  shellConfig.distrib = 
    command: 'coffee -o lib/ src/'

  grunt.config.set('shell', shellConfig)

  # we don't need no stinking webpack
  grunt.registerTask 'distrib', ['shell:distrib']
