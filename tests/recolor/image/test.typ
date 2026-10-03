#import "/src/lib.typ": recolor-image

#set page(width: auto, height: auto, margin: 4pt)

#let src = path("example.svg")

#stack(
  dir: ltr,
  spacing: 4pt,
  image(src, width: 2cm),
  recolor-image(src, red, width: 2cm),
  recolor-image(src, blue, width: 2cm),
  recolor-image(src, green, color-before: white, width: 2cm),
)
