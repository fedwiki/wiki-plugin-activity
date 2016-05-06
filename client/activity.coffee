###
 * Federated Wiki : Activity Plugin
 *
 * Licensed under the MIT license.
 * https://github.com/fedwiki/wiki-plugin-activity/blob/master/LICENSE.txt
###

h = require 'virtual-dom/h'
diff = require 'virtual-dom/diff'
patch = require 'virtual-dom/patch'
createElement = require 'virtual-dom/create-element'
_ = require 'lodash'

escape = (line) ->
  line
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')

setDefaults = (query) ->
  query.since = 0
  query.listing = []
  query.errors = 0
  query.includeNeighbors = true
  query.twins = 0
  query.sortOrder = "date"
  query.searchTerm = ''
  query.searchResults = ''
  query.rosterResults = {}
  query.mine = "yes"
  query.conversation = false
  query.narrative = false

open_conversation = (this_page, uri) ->
  tuples = uri.split '/'
  tuples.shift()
  while tuples.length
    site = tuples.shift()
    slug = tuples.shift()
    wiki.doInternalLink slug, this_page, site
    this_page = null

parse = (query, text, $item, item) ->
  query.listing = []
  query.errors = 0
  for line in text.split /\r?\n/
    continue unless words = line.match /\S+/g
    # switch words[0]
    #   when 'SINCE' then since = +(words[1] || 1)
    html = escape line
    today = new Date
    todayStart = today.setHours(0,0,0,0)
    try
      [match, op, arg] = line.match(/^\s*(\w*)\s*(.*)$/)
      switch op
        when '' then
        when 'SINCE'
          if match = arg.match /^(\d+) hours?$/i
            query.since = Date.now() - ((+match[1])*1000*60*60)
          else if match = arg.match /^(\d+) days?$/i
            query.since = Date.now() - ((+match[1])*1000*60*60*24)
          else if match = arg.match /^(\d+) weeks?$/i
            query.since = Date.now() - ((+match[1])*1000*60*60*24*7)
          else if match = arg.match /^(sun|mon|tue|wed|thu|fri|sat)[a-z]*$/i
            days = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
            query.since = todayStart - ((((new Date).getDay() + 7 - (days.indexOf(match[1].toLowerCase())))%7) * 1000*60*60*24)
          else if !(isNaN(Date.parse(arg)))
            query.since = Date.parse(arg)
          else
            throw {message:"don't know SINCE '#{arg}' argument"}

        when 'NEIGHBORHOOD'
          if arg.match /^yes/i
            query.includeNeighbors = true
          else if arg.match /^no/i
            query.includeNeighbors = false
          else
            throw {message:"don't know NEIGHBORHOOD '#{arg}' argument"}

        when 'TWINS'
          if match = arg.match /^(\d+)/
            query.twins = +match[1]
          else
            throw {message:"don't know TWINS '#{arg}' argument"}

        when 'SORT'
          if arg.match /^titles?$/i
            query.sortOrder = "title"
          else if arg.match /^date/i
            query.sortOrder = "date"
          else
            throw {message: "don't know SORT '#{arg}' argument"}

        when 'SEARCH'
          query.searchTerm = arg
          query.searchResults = wiki.neighborhoodObject.search(query.searchTerm)

        when 'ROSTER'
          query.includeNeighbors = false
          items = $(".item:lt(#{$('.item').index($item)})")
          sources = items.filter ".roster-source"
          sources.each (i,source) ->
            # console.log 'source', source
            roster = source.getRoster()
            for key, value of roster
              if key.toLowerCase().indexOf(arg.toLowerCase()) >= 0
                query.rosterResults[site] = true for site in value
          unless query.rosterResults[location.host]
            query.mine = "no"
          # load the sitemaps for the sites in the roster
          for site of query.rosterResults
            wiki.neighborhoodObject.registerNeighbor site


        when 'MINE'
          if arg.match /^yes/i
            query.mine = "yes"
          else if arg.match /^no/i
            query.mine = "no"
          else if arg.match /^only/i
            query.mine = "only"
          else if arg.match /^exclude/i
            query.mine = "exclude"
          else
            throw {message: "don't know MINE '#{arg}' argument"}

        when 'CONVERSATION'
          query.conversation = true

        when 'NARRATIVE'
          query.narrative = true

        else throw {message:"don't know '#{op}' command"}
    catch err
      query.errors++
      html = """<span style="background-color:#fdd;width:100%;" title="#{err.message}">#{html}</span>"""
    query.listing.push html


emit = ($item, item) ->

bind = ($item, item) ->

  tree = h 'div'
  rootNode = createElement tree
  $item.append rootNode

  unfilteredPages = {}
  pages = {}

  display = (query, pages) ->

    # Catch query errors
    if query.errors
      newTree = h 'div', h 'p', query.listing.join('<br>')
      patches = diff tree, newTree
      rootNode = patch rootNode, patches
      return

    # create content for the plugin's title

    header = []

    subHeadStyle = { style: { marginTop: '0px', marginBottom: '0px', marginLeft: '25px', }}

    header.push h 'p', {style: {marginBottom: '0px'}}, "Page Activity"
    header.push h 'p', subHeadStyle, "searching for \"#{query.searchTerm}\"" if query.searchTerm
    header.push h 'p', subHeadStyle, "since #{(new Date(query.since)).toDateString()}" if query.since
    header.push h 'p', subHeadStyle, "more than #{query.twins} twins" if query.twins > 0
    header.push h 'p', subHeadStyle, "sorted by page title" if query.sortOrder is "title"
    header.push h 'p', subHeadStyle, "excluding neighborhood" if query.includeNeighbors is false
    header.push h 'p', subHeadStyle, "excluding my pages" if query.mine is 'no'
    header.push h 'p', subHeadStyle, "including only pages I have a twin of" if query.mine is 'only'
    header.push h 'p', subHeadStyle, "including only pages I don't have a twin of" if query.mine is 'exclude'

    activityTitle = h 'div', {style: {fontWeight: 'bold', marginTop: '14px', marginBottom: '14px'}}, header

    now = (new Date).getTime()
    sections = [
      {date: now-1000*60*60*24*365, period: 'Years'}
      {date: now-1000*60*60*24*91, period: 'a Year'}
      {date: now-1000*60*60*24*31, period: 'a Season'}
      {date: now-1000*60*60*24*7, period: 'a Month'}
      {date: now-1000*60*60*24, period: 'a Week'}
      {date: now-1000*60*60, period: 'a Day'}
      {date: now-1000*60, period: 'an Hour'}
      {date: now-1000, period: 'a Minute'}
      {date: now, period: 'Seconds'}
    ]

    if query.sortOrder == "title"
      bigger = ''
    else
      bigger = now

    activityBody = []

    for sites in pages

      if ((sites.length >= query.twins) or query.twins == 0) and (query.mine is 'only' and (location.host in (twin.site for twin in sites)) or !(query.mine is 'only')) and (query.mine is 'exclude' and !(location.host in (twin.site for twin in sites)) or !(query.mine is 'exclude'))
        if query.sortOrder == "title"
          smaller = sites[0].page.title.substr(0,1).toUpperCase()
          if smaller != bigger
            activityBody.push h('h3', {style: {width: '100%', textAlign: "right"}}, smaller)
        else
          smaller = sites[0].page.date
          for section in sections
            if section.date > smaller and section.date < bigger
              activityBody.push h 'h3', "Within #{section.period}"
              break
        bigger = smaller

        context = if sites[0].site == location.host then "view" else "view => #{sites[0].site}"

        pageLink = h 'a.internal', {href: "/#{sites[0].page.slug}", title: context, key: sites[0].page.slug ,attributes: {"data-page-name": sites[0].page.slug}}, "#{sites[0].page.title || sites[0].page.slug}"

        links = []

        if query.narrative
          narrativeLink = sites[0].page.slug
          for each, i in sites
            narrativeLink += "@#{each.site}"
          links.push h 'a', {href: "http://paul90.github.io/wiki-narrative-chart/\##{narrativeLink}", title: "Narrative Chart", target: "narrative"}, "※"

        if query.conversation
          conversationLink = ''
          for each, i in sites.slice().reverse()
            conversationLink += "/#{each.site}/#{each.page.slug}"
          #links.push "" if query.narrative # separate with a narrow space
          links.push h 'a.conversation', {href: conversationLink, title: "Conversation", target: "conversation"}, "»"

        flags = []

        for each, i in sites
          joint = if sites[i-1]?.page.date == each.page.date then "" else " "
          flags.unshift joint
          flags.unshift h('img.remote', { title: "#{each.site}\n#{wiki.util.formatElapsedTime each.page.date}", src: "http://#{each.site}/favicon.png", attributes:  {"data-site": each.site, "data-slug": each.page.slug}})


        activityBody.push h 'div', {style: {clear: 'both'}, id: sites[0].page.slug}, [ h('div', {style: {float: 'left'}}, pageLink), h('div', {style: {textAlign: 'right'}}, [flags, h('div', {style: {float: 'right', marginRight: '-1.1em'}}, links)])]

      else
        omitted++
    activityBody.push h 'p', h 'i', "#{omitted} more titles" if omitted > 0

    newTree = h 'div', [activityTitle, activityBody]
    patches = diff tree, newTree
    rootNode = patch rootNode, patches
    tree = newTree

    $item.find('.conversation').click (e) ->
      e.stopPropagation()
      e.preventDefault()
      this_page = $item.parents('.page') unless e.shiftKey
      open_conversation this_page, $(this).attr('href')

  merge = (query, neighborhoodSites) ->

    for site in neighborhoodSites

      map = wiki.neighborhood[site]
      continue if map.sitemapRequestInflight or !(map.sitemap?)
      if query.includeNeighbors or (!query.includeNeighbors and site is location.host) or site == location.host or query.rosterResults[site]
        if !(query.mine is "no" and site is location.host)
          for each in map.sitemap
            sites = unfilteredPages[each.slug]
            unfilteredPages[each.slug] = sites = [] unless sites?
            if _.findIndex(sites, ['site', site]) is -1
              sites.push {site: site, page: {slug: each.slug, title: each.title, date: each.date}}
            else
              sites[_.findIndex(sites, ['site', site])] = {site: site, page: {slug: each.slug, title: each.title, date: each.date}}
    for slug, sites of pages
      sites.sort (a, b) ->
        (b.page.date || 0) - (a.page.date || 0)
    pages = unfilteredPages
    pages = (sites for slug, sites of pages)
    pages.sort (a, b) ->
      if query.sortOrder == "title"
        a[0].page.title.localeCompare(b[0].page.title,{sensitivity: "accent"})
      else
        (b[0].page.date || 0) - (a[0].page.date || 0)

    omitted = 0
    pages.filter (e) ->

      willInclude = true
      if query.since
        # console.log "Date: ", e[0].page.date
        if e[0].page.date <= query.since or e[0].page.date is undefined
          willInclude = false
          omitted++
      if query.searchTerm && willInclude

        if !(e[0].page in (finds.page for finds in query.searchResults.finds))
          willInclude = false
          omitted++

      return willInclude

  query = {}
  setDefaults query
  parse query, item.text || '', $item, item

  omitted = 0
  display query, merge(query, Object.keys(wiki.neighborhood))

  $('body').on 'new-neighbor-done', (e, site) ->
    console.log "Pages: ", pages
    if query.searchTerm
      searchResults = wiki.neighborhoodObject.search(query.searchTerm)
    omitted = 0
    display query, merge(query, [site])

  $item.dblclick ->
    $('body').off 'new-neighbor-done'
    wiki.textEditor $item, item


window.plugins.activity = {emit, bind} if window?
module.exports = {escape, parse} if module?
