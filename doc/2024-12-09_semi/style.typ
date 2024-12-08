#import "@preview/codly:1.1.1": *
#import "@preview/codly-languages:0.1.1": *

#let style = (
  title: str,
  body,
) => {
  // コードブロックをいい感じにスタイリングしてくれる
  show: codly-init.with()
  codly(languages: codly-languages)
  codly(zebra-fill: none)

  set text(
    size: 10pt,
    lang: "ja",
    font: ("IPAMincho")
  )

  set page(header: context {
    let selector = selector(heading).before(here())
    let level = counter(selector)
    let headings = query(selector)
    if headings.len() == 0 {
    return
  }
    let heading = headings.last()

    if counter(page).get().first() > 1 [
    #h(1fr)
    #level.display(heading.numbering)
    #heading.body
  ]
  })

  set page(footer: context [
    #title
    #h(1fr)
    #counter(page).display(
      "1/1",
      both: true,
    )
  ])

  set heading(numbering: "1.1.1.1.")
  show heading: it => {
    block(width: 100%)[
      #if (it.level == 1) {
      text(it, size: 16pt)
    } else if (it.level == 2) {
      text(it, size: 12pt)
    } else {
      text(it, size: 10pt)
    }
      #v(-0.3cm)
      #line(length: 100%, stroke: gray)
      #v(0.3cm)
    ]
  }

  set list(indent: 12pt, body-indent: 0.7em, spacing: 0.8em)
  set enum(indent: 12pt, body-indent: 0.7em, spacing: 0.8em)

  body
}

#let title_page = (
  title: str,
  author: str
) => {
  place(
    top + center,
    float: true,
    scope: "parent",
  )[
    #align(center, text(20pt)[
      #title
    ])
    #v(-1em)
    #line(length: 100%)
    #grid(
      columns: (1fr, 1fr),
      align(left)[
        #text(12pt)[
          2024/12/09
        ]
      ],
      align(right)[
        #text(12pt)[
          #author
        ]
      ]
    )
    #v(1.5em)
    #outline(depth: 2, indent: 12pt)
    #v(1.5em)
  ]
}
