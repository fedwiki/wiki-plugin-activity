# This script will generate pages to cover all possible pairs of commands
#
# It will create a page "Activity Test - Possible Pairs", and a page for each
# pair of commands.
#
# It expects there to be a server running on 'localhost:3000', which it will
# use to create these pages.

crypto = require 'crypto'
fs = require 'fs'

# directory to create files in
fileDir = "../pages/"

asSlug = (name) ->
  name.replace(/\s/g, '-').replace(/[^A-Za-z0-9-]/g, '').toLowerCase()

# Test Commands
tests = [
  {desc: "SINCE", test: ["SINCE 1 week"]},
  {desc: "NEIGHBORHOOD", test: ["NEIGHBORHOOD yes", "NEIGHBORHOOD no"]},
  {desc: "TWINS", test: ["TWINS 2"]},
  {desc: "SORT", test: ["SORT date", "SORT titles"]},
  {desc: "SEARCH", test: ["SEARCH test"]},
  {desc: "ROSTER", test: ["ROSTER test 1"]},
  {desc: "MINE", test: ["MINE yes", "MINE no", "MINE exclude", "MINE only"]},
  {desc: "CONVERSATION", test: ["CONVERSATION"]},
  {desc: "NARRATIVE", test: ["NARRATIVE"]}
]

#
# Single Commands
#

links = ""
code = ""

t1 = 0

for command in tests
  links += """
  {
    "type": "markdown",
    "id": "#{crypto.randomBytes(8).toString('hex')}",
    "text": "# #{command.desc}"
  },
  """
  for test1 in command.test
    t1++
    if command.test.length == 1
      name1 = "#{command.desc}"
    else
      name1 = "#{command.desc}(#{t1})"

    pageName = "Activity Test - #{name1}"

    story = """
    [
      {
        "type": "code",
        "id": "#{crypto.randomBytes(8).toString('hex')}",
        "text": "#{test1}"
      },
      {
        "type": "activity",
        "id": "#{crypto.randomBytes(8).toString('hex')}",
        "text": "#{test1}"
      }
    ]
    """

    journal = """
    [
      {
        "type": "create",
        "item": {
          "title": "#{pageName}",
          "story": #{story}
        },
        "date": #{new Date().getTime()}
      }
    ]
    """

    page = """
    {
      "title": "#{pageName}",
      "story": #{story},
      "journal": #{journal}
    }
    """

    fileName = fileDir + asSlug(pageName)

    fs.writeFileSync(fileName, page)

    code += "#{test1}\\n"
    links += """
    {
      "type": "paragraph",
      "id": "#{crypto.randomBytes(8).toString('hex')}",
      "text": "[[#{pageName}]]"
    },
    """

  t1 = 0
  code += "\\n"

pageName = "Activity Test - Single Commands"

fileName = fileDir + asSlug(pageName)
story = """
[
  {
    "type": "paragraph",
    "id": "#{crypto.randomBytes(8).toString('hex')}",
    "text": "The commands used in these tests are:"
  },
  {
    "type": "code",
    "id": "#{crypto.randomBytes(8).toString('hex')}",
    "text": "#{code.substring(0, code.length - 2)}"
  },
  #{links.substring(0, links.length - 1)}
]
"""

journal = """
[
  {
    "type": "create",
    "item": {
      "title": "#{pageName}",
      "story": #{story}
    },
    "date": #{new Date().getTime()}
  }
]
"""

page = """
{
  "title": "#{pageName}",
  "story": #{story},
  "journal": #{journal}
}
"""

fileName = fileDir + asSlug(pageName)

fs.writeFileSync(fileName, page)

#
# Possible Pairs
#

links = ""

t1 = 0
t2 = 0

for pair1 in tests
  links += """
  {
    "type": "markdown",
    "id": "#{crypto.randomBytes(8).toString('hex')}",
    "text": "# #{pair1.desc} and..."
  },
  """
  for test1 in pair1.test
    t1++
    for pair2 in tests
      for test2 in pair2.test
        t2++
        if pair1.test.length == 1
          name1 = "#{pair1.desc}"
        else
          name1 = "#{pair1.desc}(#{t1})"

        if pair2.test.length == 1
          name2 = "#{pair2.desc}"
        else
          name2 = "#{pair2.desc}(#{t2})"

        pageName = "Activity Test - #{name1} #{name2}"

        id1 = crypto.randomBytes(8).toString('hex')
        id2 = crypto.randomBytes(8).toString('hex')

        story = """
        [
          {
            "type": "code",
            "id": "#{id1}",
            "text": "#{test1}\\n#{test2}"
          },
          {
            "type": "activity",
            "id": "#{id2}",
            "text": "#{test1}\\n#{test2}"
          }
        ]
        """

        journal = """
        [
          {
            "type": "create",
            "item": {
              "title": "#{pageName}",
              "story": #{story}
            },
            "date": #{new Date().getTime()}
          }
        ]
        """

        page = """
        {
          "title": "#{pageName}",
          "story": #{story},
          "journal": #{journal}
        }
        """

        fileName = fileDir + asSlug(pageName)

        fs.writeFileSync(fileName, page)

        links += """
        {
          "type": "paragraph",
          "id": "#{crypto.randomBytes(8).toString('hex')}",
          "text": "[[#{pageName}]]"
        },
        """

      t2 = 0
  t1 = 0

pageName = "Activity Test - Possible Pairs"

fileName = fileDir + asSlug(pageName)
story = """
[
  {
    "type": "paragraph",
    "id": "#{crypto.randomBytes(8).toString('hex')}",
    "text": "The commands used in these tests are:"
  },
  {
    "type": "code",
    "id": "#{crypto.randomBytes(8).toString('hex')}",
    "text": "#{code.substring(0, code.length - 2)}"
  },
  #{links.substring(0, links.length - 1)}
]
"""

journal = """
[
  {
    "type": "create",
    "item": {
      "title": "#{pageName}",
      "story": #{story}
    },
    "date": #{new Date().getTime()}
  }
]
"""

page = """
{
  "title": "#{pageName}",
  "story": #{story},
  "journal": #{journal}
}
"""

fileName = fileDir + asSlug(pageName)

fs.writeFileSync(fileName, page)
