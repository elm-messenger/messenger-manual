// Dark mode for debugging
// #set page(fill: rgb("444352"))
// #set text(fill: rgb("fdfdfd"))

#set text(
  size: 12pt
)
#show link: it => {set text(blue); underline(it)}
#set par(
  justify: true,
  leading: 1em,
  first-line-indent: 2em,
)
#show heading: it => {it;text()[#v(0.3em, weak: true)];text()[#h(0em)]}
#set heading(numbering: "1.")

#line(start: (0%, 10%), end: (8.5in, 10%), stroke: (thickness: 2pt))

#align(horizon + left)[
  #text(size: 32pt, "Messenger Manual")\
  #v(1em)
   #text(size: 16pt, "A Game Engine for Elm")
  #v(10em)
  FOCS Messenger Team
]
  
#align(bottom + right)[#datetime.today().display()]
#pagebreak()

#outline(depth: 2, indent: auto)

#pagebreak()

#align(horizon + center)[
  #text(size: 32pt, "User Guide")\
  #v(1em)
   #text(size: 16pt, "Exploring the features of Messenger", style: "italic")
]

#pagebreak()

#set page(
  paper: "us-letter",
  header: text()[*Messenger: A Game Engine for Elm*],
  number-align: center,
  numbering: "1"
)

#include "intro.typ"

#include "hello world.typ"

#include "render.typ"

#include "event.typ"

#include "component.typ"

#include "sceneproto.typ"

#include "advanced.typ"

#include "appendix.typ"

#pagebreak()

#align(horizon + center)[
  #text(size: 32pt, "Developer Guide")\
  #v(1em)
   #text(size: 16pt, "Implementation details of Messenger", style: "italic")
]

#include "generalmodel.typ"