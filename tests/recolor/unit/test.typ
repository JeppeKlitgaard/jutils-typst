#import "/src/lib.typ": recolor-svg

#let recolor(..args) = recolor-svg(..args, return-image: false)

#let r = red.to-hex()
#let b = blue.to-hex()

// Every colour is replaced by default, in any spelling and in attributes as
// well as CSS. The root gets a fill for unfilled shapes.
#assert.eq(
  recolor(
    "<svg><a fill='#E63F47'/><b stroke=\"rgb(1, 2, 3)\"/><c style=\"fill:hsl(0, 50%, 50%);stop-color:Teal\"/></svg>",
    red,
  ),
  "<svg fill=\"" + r + "\"><a fill='" + r + "'/><b stroke=\"" + r + "\"/><c style=\"fill:" + r + ";stop-color:" + r + "\"/></svg>",
)

// Values that are not colours are kept, as are related properties such as
// `fill-opacity`. The root already has a fill, so no extra one is added.
#let non-colors = "<svg fill=\"none\"><a fill=\"currentColor\" fill-opacity=\".5\" fill-rule=\"evenodd\"/><b stroke=\"url(#g)\"/><c style=\"fill:inherit;stroke:transparent\"/></svg>"
#assert.eq(recolor(non-colors, red), non-colors)

// Implicit black: the root gets a fill, even when `<svg` is followed by a newline.
#assert.eq(
  recolor("<svg\n xmlns='x'><path/></svg>", red, color-before: black),
  "<svg fill=\"" + r + "\"\n xmlns='x'><path/></svg>",
)

// Spellings of black in attributes and CSS. The root already has a fill, so
// no extra one is added.
#assert.eq(
  recolor(
    "<svg fill=\"#000\"><a stroke='#000000'/><b style=\"fill:BLACK;stroke:rgb(0, 0, 0)\"/><c fill=\"#000F\"/></svg>",
    red,
    color-before: black,
  ),
  "<svg fill=\"" + r + "\"><a stroke='" + r + "'/><b style=\"fill:" + r + ";stroke:" + r + "\"/><c fill=\"" + r + "\"/></svg>",
)

// `<style>` blocks with back-to-back declarations.
#assert.eq(
  recolor("<style>.a{fill:#000}.b{stroke:#000}</style>", red, color-before: black),
  "<style>.a{fill:" + r + "}.b{stroke:" + r + "}</style>",
)

// No false positives.
#let untouched = "<svg fill=\"none\"><a fill=\"#0000ff\" id=\"black\"/><b stroke=\"blackish\"/><c fill=\"currentColor\"/></svg>"
#assert.eq(recolor(untouched, red, color-before: black), untouched)

// Custom `color-before` in a non-RGB colour space; other colours and the root
// are left alone.
#assert.eq(
  recolor("<svg><a fill=\"#FFF\"/><b fill=\"#000\"/><c stop-color=\"white\"/></svg>", blue, color-before: luma(255)),
  "<svg><a fill=\"" + b + "\"/><b fill=\"#000\"/><c stop-color=\"" + b + "\"/></svg>",
)

// Alpha in `color-new` is preserved.
#assert.eq(
  recolor("<svg fill='#ff0000'/>", rgb(0, 0, 255, 50%), color-before: rgb(255, 0, 0)),
  "<svg fill='#0000ff80'/>",
)

// Alpha in `color-before` only matches the same alpha.
#assert.eq(
  recolor("<svg fill='#ff000080'/><a fill='#ff0000'/>", blue, color-before: rgb(255, 0, 0, 128)),
  "<svg fill='" + b + "'/><a fill='#ff0000'/>",
)

// Output type follows input type; a path gives bytes.
#assert.eq(type(recolor("<svg/>", red)), str)
#assert.eq(type(recolor(bytes("<svg/>"), red)), bytes)
#assert.eq(type(recolor(path("../image/example.svg"), red)), bytes)

// An image is returned by default, for a path as well as for a string.
#assert.eq(recolor-svg(path("../image/example.svg"), red).func(), image)
#assert.eq(recolor-svg("<svg/>", red, width: 1cm).func(), image)
