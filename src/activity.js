/*
 * Federated Wiki : Activity Plugin
 *
 * Licensed under the MIT license.
 * https://github.com/fedwiki/wiki-plugin-activity/blob/master/LICENSE.txt
 */

import { h } from 'virtual-dom'
import diff from 'virtual-dom/diff.js'
import patch from 'virtual-dom/patch.js'
import createElement from 'virtual-dom/create-element.js'

const escape = (line) => {
  return line.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

const setDefaults = (query) => {
  query.since = 0
  query.listing = []
  query.errors = 0
  query.includeNeighbors = true
  query.twins = 0
  query.sortOrder = 'date'
  query.searchTerm = ''
  query.searchResults = ''
  query.rosterResults = {}
  query.mine = 'yes'
  query.conversation = false
  query.narrative = false
}

const open_conversation = (this_page, uri) => {
  const tuples = uri.split('/')
  tuples.shift()
  while (tuples.length) {
    const site = tuples.shift()
    const slug = tuples.shift()
    wiki.doInternalLink(slug, this_page, site)
    this_page = null
  }
}

const parse = (query, text, $item) => {
  query.listing = []
  query.errors = 0
  const lines = text.split(/\r?\n/)
  for (const line of lines) {
    const words = line.match(/\S+/g)
    if (!words) continue

    let html = escape(line)
    const today = new Date()
    const todayStart = today.setHours(0, 0, 0, 0)

    try {
      let [match, op, arg] = line.match(/^\s*(\w*)\s*(.*)$/)
      switch (op) {
        case '':
          break
        case 'SINCE':
          if ((match = arg.match(/^(\d+) hours?$/i))) {
            query.since = Date.now() - +match[1] * 1000 * 60 * 60
          } else if ((match = arg.match(/^(\d+) days?$/i))) {
            query.since = Date.now() - +match[1] * 1000 * 60 * 60 * 24
          } else if ((match = arg.match(/^(\d+) weeks?$/i))) {
            query.since = Date.now() - +match[1] * 1000 * 60 * 60 * 24 * 7
          } else if ((match = arg.match(/^(sun|mon|tue|wed|thu|fri|sat)[a-z]*$/i))) {
            const days = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat']
            query.since =
              todayStart - ((new Date().getDay() + 7 - days.indexOf(match[1].toLowerCase())) % 7) * 1000 * 60 * 60 * 24
          } else if (!isNaN(Date.parse(arg))) {
            query.since = Date.parse(arg)
          } else {
            throw new Error(`don't know SINCE '${arg}' argument`)
          }
          break
        case 'NEIGHBORHOOD':
          if (arg.match(/^yes/i)) {
            query.includeNeighbors = true
          } else if (arg.match(/^no/i)) {
            query.includeNeighbors = false
          } else {
            throw new Error(`don't know NEIGHBORHOOD '${arg}' argument`)
          }
          break
        case 'TWINS':
          if ((match = arg.match(/^(\d+)/))) {
            query.twins = +match[1]
          } else {
            throw new Error(`don't know TWINS '${arg}' argument`)
          }
          break
        case 'SORT':
          if (arg.match(/^titles?$/i)) {
            query.sortOrder = 'title'
          } else if (arg.match(/^date/i)) {
            query.sortOrder = 'date'
          } else {
            throw new Error(`don't know SORT '${arg}' argument`)
          }
          break
        case 'SEARCH':
          query.searchTerm = arg
          query.searchResults = wiki.neighborhoodObject.search(query.searchTerm)
          break
        case 'ROSTER':
          query.includeNeighbors = false
          $('.item:lt(' + $('.item').index($item) + ')')
            .filter('.roster-source')
            .each((i, source) => {
              const roster = source.getRoster()
              for (const [key, value] of Object.entries(roster)) {
                if (key.toLowerCase().indexOf(arg.toLowerCase()) >= 0) {
                  for (const site of value) {
                    query.rosterResults[site] = true
                  }
                }
              }
            })
          if (!query.rosterResults[location.host]) {
            query.mine = 'no'
          }
          for (const site in query.rosterResults) {
            wiki.neighborhoodObject.registerNeighbor(site)
          }
          break
        case 'MINE':
          if (arg.match(/^yes/i)) {
            query.mine = 'yes'
          } else if (arg.match(/^no/i)) {
            query.mine = 'no'
          } else if (arg.match(/^only/i)) {
            query.mine = 'only'
          } else if (arg.match(/^exclude/i)) {
            query.mine = 'exclude'
          } else {
            throw new Error(`don't know MINE '${arg}' argument`)
          }
          break
        case 'CONVERSATION':
          query.conversation = true
          break
        case 'NARRATIVE':
          query.narrative = true
          break
        default:
          throw new Error(`don't know '${op}' command`)
      }
    } catch (err) {
      query.errors++
      html = `<span style="background-color:#fdd;width:100%;" title="${err.message}">${html}</span>`
    }
    query.listing.push(html)
  }
}

const emit = ($item, item) => {}

const bind = ($item, item) => {
  let omitted = 0

  let tree = h('div')
  let rootNode = createElement(tree)
  $item.append(rootNode)

  const unfilteredPages = new Map()
  let pages = {}

  const display = (query, pages) => {
    // Catch query errors
    if (query.errors) {
      const newTree = h('div', h('p', query.listing.join('<br>')))
      const patches = diff(tree, newTree)
      rootNode = patch(rootNode, patches)
      return
    }

    // create content for the plugin's title
    const header = []
    const subHeadStyle = { style: { marginTop: '0px', marginBottom: '0px' } }

    if (query.searchTerm) header.push(h('p', subHeadStyle, `searching for "${query.searchTerm}"`))
    if (query.since) header.push(h('p', subHeadStyle, `since ${new Date(query.since).toDateString()}`))
    if (query.twins > 0) header.push(h('p', subHeadStyle, `more than ${query.twins} twins`))
    if (query.sortOrder === 'title') header.push(h('p', subHeadStyle, 'sorted by page title'))
    if (query.includeNeighbors === false) header.push(h('p', subHeadStyle, 'excluding neighborhood'))
    if (query.mine === 'no') header.push(h('p', subHeadStyle, 'excluding my pages'))
    if (query.mine === 'only') header.push(h('p', subHeadStyle, 'including only pages I have a twin of'))
    if (query.mine === 'exclude') header.push(h('p', subHeadStyle, "including only pages I don't have a twin of"))

    const activityTitle = h(
      'div',
      { style: { textAlign: 'center', fontSize: 'small', color: 'gray', marginTop: '14px' } },
      header,
    )

    const now = Date.now()
    const sections = [
      { date: now - 1000 * 60 * 60 * 24 * 365, period: 'Years' },
      { date: now - 1000 * 60 * 60 * 24 * 91, period: 'a Year' },
      { date: now - 1000 * 60 * 60 * 24 * 31, period: 'a Season' },
      { date: now - 1000 * 60 * 60 * 24 * 7, period: 'a Month' },
      { date: now - 1000 * 60 * 60 * 24, period: 'a Week' },
      { date: now - 1000 * 60 * 60, period: 'a Day' },
      { date: now - 1000 * 60, period: 'an Hour' },
      { date: now - 1000, period: 'a Minute' },
      { date: now, period: 'Seconds' },
    ]

    let bigger = query.sortOrder === 'title' ? '' : now

    const activityBody = []

    omitted = 0
    for (const sites of pages) {
      if (
        (sites.length >= query.twins || query.twins === 0) &&
        (query.mine !== 'only' || sites.some((twin) => twin.site === location.host)) &&
        (query.mine !== 'exclude' || !sites.some((twin) => twin.site === location.host))
      ) {
        let smaller
        if (query.sortOrder === 'title') {
          smaller = sites[0].page.title.substr(0, 1).toUpperCase()
          if (smaller !== bigger) {
            activityBody.push(h('h3', { style: { width: '100%', textAlign: 'right' } }, smaller))
          }
        } else {
          smaller = sites[0].page.date
          for (const section of sections) {
            if (section.date > smaller && section.date < bigger) {
              activityBody.push(h('h3', `Within ${section.period}`))
              break
            }
          }
        }
        bigger = smaller

        const context = sites[0].site === location.host ? 'view' : `view => ${sites[0].site}`

        const pageURL =
          (sites.length === 1 && sites[0].site !== location.host) || !sites.some((i) => i.site === location.host)
            ? wiki.site(sites[0].site).getURL(`/${sites[0].page.slug}.html`)
            : `/${sites[0].page.slug}.html`

        const pageLink = h(
          'a.internal',
          {
            href: pageURL,
            title: context,
            key: sites[0].page.slug,
            attributes: { 'data-page-name': sites[0].page.slug },
          },
          sites[0].page.title || sites[0].page.slug,
        )

        const links = []

        if (query.narrative) {
          let narrativeLink = sites[0].page.slug
          for (const each of sites) {
            narrativeLink += `@${each.site}`
          }
          links.push(
            h(
              'a',
              {
                href: `http://paul90.github.io/wiki-narrative-chart/#${narrativeLink}`,
                title: 'Narrative Chart',
                target: 'narrative',
              },
              '※',
            ),
          )
        }

        if (query.conversation) {
          let conversationLink = ''
          for (const each of sites.slice().reverse()) {
            conversationLink += `/${each.site}/${each.page.slug}`
          }
          links.push(
            h(
              'a.conversation',
              {
                href: conversationLink,
                title: 'Conversation',
                target: 'conversation',
              },
              '»',
            ),
          )
        }

        const flags = []
        sites.forEach((each, i) => {
          if (i < 10) {
            const joint = i > 0 && sites[i - 1].page.date === each.page.date ? '' : ' '
            flags.unshift(joint)
            flags.unshift(
              h('img.remote', {
                title: `${each.site}\n${wiki.util.formatElapsedTime(each.page.date)}`,
                src: wiki.site(each.site).flag(),
                attributes: { 'data-site': each.site, 'data-slug': each.page.slug },
              }),
            )
          } else if (i === 10) {
            flags.unshift(' ⋯ ')
          }
        })

        activityBody.push(
          h('div', { style: { clear: 'both' }, id: sites[0].page.slug }, [
            h('div', { style: { float: 'left' } }, pageLink),
            h('div', { style: { textAlign: 'right' } }, [
              flags,
              h('div', { style: { float: 'right', marginRight: '-1.1em' } }, links),
            ]),
          ]),
        )
      } else {
        omitted++
      }
    }

    if (omitted > 0) {
      activityBody.push(h('p', h('i', `${omitted} more titles`)))
    }

    const newTree = h('div', [activityTitle, activityBody])
    const patches = diff(tree, newTree)
    rootNode = patch(rootNode, patches)
    tree = newTree

    $item.find('.conversation').on('click', (e) => {
      e.stopPropagation()
      e.preventDefault()
      const this_page = e.shiftKey ? null : $item.parents('.page')
      open_conversation(this_page, $(e.currentTarget).attr('href'))
    })
  }

  const merge = (query, neighborhoodSites) => {
    for (const site of neighborhoodSites) {
      const map = wiki.neighborhood[site]
      if (map.sitemapRequestInflight || !map.sitemap) continue
      if (
        query.includeNeighbors ||
        (!query.includeNeighbors && site === location.host) ||
        site === location.host ||
        query.rosterResults[site]
      ) {
        if (!(query.mine === 'no' && site === location.host)) {
          for (const each of map.sitemap) {
            if (!unfilteredPages.has(each.slug)) {
              unfilteredPages.set(each.slug, [])
            }
            const sites = unfilteredPages.get(each.slug)
            const index = sites.findIndex((el) => el.site == site)
            if (index === -1) {
              sites.push({ site: site, page: { slug: each.slug, title: each.title, date: each.date } })
            } else {
              sites[index] = { site: site, page: { slug: each.slug, title: each.title, date: each.date } }
            }
          }
        }
      }
    }
    pages = Object.fromEntries(unfilteredPages)
    for (const [slug, sites] of Object.entries(pages)) {
      sites.sort((a, b) => (b.page.date || 0) - (a.page.date || 0))
    }
    pages = Object.values(pages)
    pages.sort((a, b) => {
      if (query.sortOrder === 'title') {
        return a[0].page.title.localeCompare(b[0].page.title, { sensitivity: 'accent' })
      } else {
        return (b[0].page.date || 0) - (a[0].page.date || 0)
      }
    })

    omitted = 0
    return pages.filter((e) => {
      let willInclude = true
      if (query.since) {
        if (e[0].page.date <= query.since || e[0].page.date === undefined) {
          willInclude = false
          omitted++
        }
      }
      if (query.searchTerm && willInclude) {
        if (!query.searchResults.finds.some((finds) => finds.page === e[0].page)) {
          willInclude = false
          omitted++
        }
      }
      return willInclude
    })
  }

  const query = {}
  setDefaults(query)
  parse(query, item.text || '', $item)

  omitted = 0
  display(query, merge(query, Object.keys(wiki.neighborhood)))

  $('body').on('new-neighbor-done', (e, site) => {
    if (query.searchTerm) {
      query.searchResults = wiki.neighborhoodObject.search(query.searchTerm)
    }
    omitted = 0
    display(query, merge(query, [site]))
  })

  $item.on('dblclick', () => {
    $('body').off('new-neighbor-done')
    wiki.textEditor($item, item)
  })
}

if (typeof window !== 'undefined') {
  window.plugins.activity = { emit, bind }
}

export const activity = typeof window == 'undefined' ? { escape, parse } : undefined
