###
 * Federated Wiki : Activity Plugin
 *
 * Licensed under the MIT license.
 * https://github.com/fedwiki/wiki-plugin-activity/blob/master/LICENSE.txt
###



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

parse = (query, text) ->
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

        else throw {message:"don't know '#{op}' command"}
    catch err
      query.errors++
      html = """<span style="background-color:#fdd;width:100%;" title="#{err.message}">#{html}</span>"""
    query.listing.push html


emit = ($item, item) ->

bind = ($item, item) ->



  display = (query, pages) ->
    $item.empty()
    if query.errors
      $item.append query.listing.join('<br>')
      return

    header = ""
    header += "<br/>searching for \"#{escape query.searchTerm}\"" if query.searchTerm
    header += "<br/>since #{(new Date(query.since)).toDateString()}" if query.since
    header += "<br/>more than #{query.twins} twins" if query.twins > 0
    header += "<br/>sorted by page title" if query.sortOrder is "title"
    header += "<br/>excluding neighborhood" if query.includeNeighbors is false

    if header
      $item.append "<p><b>Page Activity #{header}</b></p>"

    now = (new Date).getTime();
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
    for sites in pages
      if (sites.length >= query.twins) || query.twins == 0
        if query.sortOrder == "title"
          smaller = sites[0].page.title.substr(0,1).toUpperCase()
          if smaller != bigger
            $item.append """
              <div style="width:100%; text-align:right;"><b>#{smaller}</b></span><br>
            """
        else
          smaller = sites[0].page.date
          for section in sections
            if section.date > smaller and section.date < bigger
              $item.append """
                <h3> Within #{section.period} </h3>
              """
              break
        bigger = smaller
        for each, i in sites
          joint = if sites[i+1]?.page.date == each.page.date then "" else "&nbsp"
          $item.append """
            <img class="remote"
              title="#{each.site}\n#{wiki.util.formatElapsedTime each.page.date}"
              src="http://#{each.site}/favicon.png"
              data-site="#{each.site}"
              data-slug="#{each.page.slug}">#{joint}
          """
        context = if sites[0].site == location.host then "view" else "view => #{sites[0].site}"
        $item.append """
          <a class="internal"
            href="/#{sites[0].page.slug}"
            data-page-name="#{sites[0].page.slug}"
            title="#{context}">
            #{escape(sites[0].page.title || sites[0].page.slug)}
          </a><br>
        """
      else
        omitted++
    $item.append "<p><i>#{omitted} more titles</i></p>" if omitted > 0

  merge = (query, neighborhood) ->
    pages = {}
    for site, map of neighborhood
      continue if map.sitemapRequestInflight or !(map.sitemap?)
      if query.includeNeighbors or (!query.includeNeighbors and site == location.host)
        for each in map.sitemap
          sites = pages[each.slug]
          pages[each.slug] = sites = [] unless sites?
          sites.push {site: site, page: each}
    for slug, sites of pages
      sites.sort (a, b) ->
        (b.page.date || 0) - (a.page.date || 0)
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
        if e[0].page.date <= query.since
          willInclude = false
          omitted++
      if query.searchTerm && willInclude

        if !(e[0].page in (finds.page for finds in query.searchResults.finds))
          willInclude = false
          omitted++

      return willInclude

  query = {}
  setDefaults query
  parse query, item.text || ''

  omitted = 0
  display query, merge(query, wiki.neighborhood)

  $('body').on 'new-neighbor-done', (e, site) ->
    if query.searchTerm
      query.searchResults = wiki.neighborhoodObject.search(query.searchTerm)
    omitted = 0
    display query, merge(query, wiki.neighborhood)

  $item.dblclick ->
    $('body').off 'new-neighbor-done'
    wiki.textEditor $item, item


window.plugins.activity = {emit, bind} if window?
module.exports = {escape, parse} if module?
