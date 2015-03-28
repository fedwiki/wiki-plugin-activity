# build time tests for activity plugin
# see http://mochajs.org/

activity = require '../client/activity'
expect = require 'expect.js'

describe 'activity plugin', ->

  describe 'escape', ->

    it 'can escape html markup characters', ->
      result = activity.escape 'try < & >'
      expect(result).to.be 'try &lt; &amp; &gt;'

  describe 'since', ->
    hours = (epoch) ->
      Math.round (epoch - Date.now()) / (60*60*1000)

    it 'can parse days', ->
      result = {}
      activity.parse result, 'SINCE 15 days'
      expect(hours result.since).to.be -15*24

    it 'can parse day', ->
      result = {}
      activity.parse result, 'SINCE 1 day'
      expect(hours result.since).to.be -24

    it 'can parse DAYS', ->
      result = {}
      activity.parse result, 'SINCE 90 DAYS'
      expect(hours result.since).to.be -90*24

    it 'can parse hours', ->
      result = {}
      activity.parse result, 'SINCE 100 hours'
      expect(hours result.since).to.be -100

    it 'can parse weeks', ->
      result = {}
      activity.parse result, 'SINCE 2 weeks'
      expect(hours result.since).to.be -14*24
