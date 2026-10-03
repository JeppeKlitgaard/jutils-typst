#import "/src/lib.typ": recolor

#let r = red.to-hex()
#let b = blue.to-hex()

// Implicit black: the root gets a fill, even when `<svg` is followed by a newline.
#assert.eq(
  recolor("<svg\n xmlns='x'><path/></svg>", red),
  "<svg fill=\"" + r + "\"\n xmlns='x'><path/></svg>",
)

// Spellings of black in attributes and CSS. The root already has a fill, so
// no extra one is added.
#assert.eq(
  recolor(
    "<svg fill=\"#000\"><a stroke='#000000'/><b style=\"fill:BLACK;stroke:rgb(0, 0, 0)\"/><c fill=\"#000F\"/></svg>",
    red,
  ),
  "<svg fill=\"" + r + "\"><a stroke='" + r + "'/><b style=\"fill:" + r + ";stroke:" + r + "\"/><c fill=\"" + r + "\"/></svg>",
)

// `<style>` blocks with back-to-back declarations.
#assert.eq(
  recolor("<style>.a{fill:#000}.b{stroke:#000}</style>", red),
  "<style>.a{fill:" + r + "}.b{stroke:" + r + "}</style>",
)

// No false positives.
#let untouched = "<svg fill=\"none\"><a fill=\"#0000ff\" id=\"black\"/><b stroke=\"blackish\"/><c fill=\"currentColor\"/></svg>"
#assert.eq(recolor(untouched, red), untouched)

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

// Output type follows input type.
#assert.eq(type(recolor("<svg/>", red)), str)
#assert.eq(type(recolor(bytes("<svg/>"), red)), bytes)
