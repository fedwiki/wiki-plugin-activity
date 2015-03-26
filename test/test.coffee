# build time tests for activity plugin
# see http://mochajs.org/

activity = require '../client/activity'
expect = require 'expect.js'

describe 'activity plugin', ->

  describe 'escape', ->

    it 'can escape html markup characters', ->
      result = activity.escape 'try < & >'
      expect(result).to.be 'try &lt; &amp; &gt;'