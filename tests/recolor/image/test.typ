#import "/src/lib.typ": recolor-svg

#set page(width: auto, height: auto, margin: 4pt)

#let src = path("example.svg")

#stack(
  dir: ltr,
  spacing: 4pt,
  image(src, width: 2cm),
  recolor-svg(src, red, width: 2cm),
  recolor-svg(src, blue, width: 2cm),
  recolor-svg(src, green, color-before: white, width: 2cm),
)

// Several non-black fills, some written in uppercase hex.
#let qim = path("qim.svg")

// Every colour replaced with a different one, by chaining calls through
// `return-image: false`.
#let qim-all = {
  let s = recolor-svg(qim, black, color-before: rgb("#747474"), return-image: false)
  s = recolor-svg(s, blue, color-before: rgb("#e63f47"), return-image: false)
  recolor-svg(s, green, color-before: rgb("#fc7323"), width: 3cm)
}

#stack(
  dir: ltr,
  spacing: 4pt,
  image(qim, width: 3cm),
  recolor-svg(qim, black, color-before: rgb("#747474"), width: 3cm),
  recolor-svg(qim, blue, color-before: rgb("#e63f47"), width: 3cm),
  recolor-svg(qim, green, color-before: rgb("#fc7323"), width: 3cm),
  qim-all,
  // Every colour replaced with the same one.
  recolor-svg(qim, red, width: 3cm),
)
