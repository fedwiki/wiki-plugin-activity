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

emit = ($item, item) ->

bind = ($item, item) ->

  since = 0
  listing = []
  errors = 0

  parse = (text) ->
    listing = []
    errors = 0
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
              since = Date.now() - ((+match[1])*1000*60*60)
            else if match = arg.match /^(\d+) days?$/i
              since = Date.now() - ((+match[1])*1000*60*60*24)
            else if match = arg.match /^(\d+) weeks?$/i
              since = Date.now() - ((+match[1])*1000*60*60*24*7)
            else if match = arg.match /^(sun|mon|tue|wed|thu|fri|sat)[a-z]*$/i
              days = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
              since = todayStart - ((((new Date).getDay() + 7 - (days.indexOf(match[1].toLowerCase())))%7) * 1000*60*60*24)
            else if !(isNaN(Date.parse(arg)))
              since = Date.parse(arg)
            else
              throw {message:"don't know SINCE '#{arg}' argument"}
          else throw {message:"don't know '#{op}' command"}
      catch err
        errors++
        html = """<span style="background-color:#fdd;width:100%;" title="#{err.message}">#{html}</span>"""
      listing.push html

  display = (pages) ->
    $item.empty()
    if errors
      $item.append listing
      return
    $item.append "<h2>Activity Since #{(new Date(since)).toDateString()}</h2>" if since
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
    bigger = now
    for sites in pages
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
    $item.append "<p><i>#{omitted} more older titles</i></p>" if omitted > 0

  parse item.text || ''

  omitted = 0

  merge = (neighborhood) ->
    pages = {}
    for site, map of neighborhood
      continue if map.sitemapRequestInflight or !(map.sitemap?)
      for each in map.sitemap
        sites = pages[each.slug]
        pages[each.slug] = sites = [] unless sites?
        sites.push {site: site, page: each}
    for slug, sites of pages
      sites.sort (a, b) ->
        (b.page.date || 0) - (a.page.date || 0)
    pages = (sites for slug, sites of pages)
    pages.sort (a, b) ->
        (b[0].page.date || 0) - (a[0].page.date || 0)

    omitted = 0
    pages.filter (e) ->
      omitted += 1 if e[0].page.date <= since
      e[0].page.date > since


  display merge wiki.neighborhood

  $('body').on 'new-neighbor-done', (e, site) ->
    display merge wiki.neighborhood

  $item.dblclick -> wiki.textEditor $item, item


window.plugins.activity = {emit, bind} if window?
module.exports = {} if module?
