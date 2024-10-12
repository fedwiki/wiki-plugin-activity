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

    it 'can parse a date', ->
      result = {}
      activity.parse result, 'SINCE Apr 1, 2015'
      expect(result.since).to.be Date.parse('2015, Apr 1')

  describe 'neighborhood', ->

    it 'can parse YES', ->
      result = {}
      activity.parse result, 'NEIGHBORHOOD YES'
      expect(result.includeNeighbors).to.be true

    it 'can parse no', ->
      result = {}
      activity.parse result, 'NEIGHBORHOOD no'
      expect(result.includeNeighbors).to.be false

  describe 'twins', ->

    it 'can parse a number', ->
      result = {}
      activity.parse result, 'TWINS 2'
      expect(result.twins).to.be 2

    it 'ignores text', ->
      result = {}
      activity.parse result, 'TWINS two'
      expect(result.twins).to.be undefined

  describe 'sort', ->

    it 'can parse Title', ->
      result = {}
      activity.parse result, 'SORT Title'
      expect(result.sortOrder).to.be 'title'

    it 'can parse date', ->
      result = {}
      activity.parse result, 'SORT date'
      expect(result.sortOrder).to.be 'date'

  describe 'search', ->

    it 'can parse search', ->
      result = {}
      activity.parse result, 'SEARCH test'
      expect(result.searchTerm).to.be 'test'
      expect(result.searchResults).to.be undefined

  describe 'roster', ->

    it 'excludes neighborhood', ->
      result = {}
      activity.parse result, 'ROSTER test'
      expect(result.includeNeighbors).to.be false

  describe 'mine', ->

    it 'can parse to include mine', ->
      result = {}
      activity.parse result, 'MINE yes'
      expect(result.mine).to.be 'yes'

    it 'can parse to exclude mine', ->
      result = {}
      activity.parse result, 'MINE No'
      expect(result.mine).to.be 'no'

    it 'can parse for mine only', ->
      result = {}
      activity.parse result, 'MINE only'
      expect(result.mine).to.be 'only'

    it 'can parse to exclude mine', ->
      result = {}
      activity.parse result, 'MINE exclude'
      expect(result.mine).to.be 'exclude'

  describe 'conversation', ->

    it 'can parse to add conversation link', ->
      result = {}
      activity.parse result, 'CONVERSATION'
      expect(result.conversation).to.be true

  describe 'narrative', ->

    it 'can parse to add narrative link', ->
      result = {}
      activity.parse result, 'NARRATIVE'
      expect(result.narrative).to.be true
