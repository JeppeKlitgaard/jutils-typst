// SVG presentation attributes / CSS properties that carry a colour.
#let _color-props = (
  "fill",
  "stroke",
  "stop-color",
  "flood-color",
  "lighting-color",
  "color",
)

// The 16 basic CSS colour keywords, keyed by their `#rrggbb` value.
#let _named-colors = (
  "#000000": "black",
  "#c0c0c0": "silver",
  "#808080": "gray|grey",
  "#ffffff": "white",
  "#800000": "maroon",
  "#ff0000": "red",
  "#800080": "purple",
  "#ff00ff": "fuchsia|magenta",
  "#008000": "green",
  "#00ff00": "lime",
  "#808000": "olive",
  "#ffff00": "yellow",
  "#000080": "navy",
  "#0000ff": "blue",
  "#008080": "teal",
  "#00ffff": "aqua|cyan",
)

// Builds a regex alternation matching the common spellings of `c` in SVG:
// `#rrggbb`, `#rgb`, `#rrggbbaa`, `#rgba`, `rgb(r, g, b)`, `rgba(r, g, b, a)`
// and the CSS keyword, if any. Matching is case-insensitive via the caller.
#let _color-variants(c) = {
  let hex = rgb(c).to-hex()
  let rgb6 = hex.slice(1, 7)
  let alpha = if hex.len() == 9 { hex.slice(7, 9) } else { "ff" }
  let (r, g, b, a) = rgb(c).components(alpha: true).map(x => int(calc.round(x / 100% * 255)))

  // `#aabbcc` -> `#abc` only when every channel is a doubled digit.
  let shorten(h) = {
    let pairs = range(0, h.len(), step: 2).map(i => h.slice(i, i + 2))
    if pairs.all(p => p.at(0) == p.at(1)) { pairs.map(p => p.at(0)).join() }
  }

  let hexes = (rgb6 + alpha,)
  if alpha == "ff" { hexes.push(rgb6) }
  let variants = ()
  for h in hexes {
    variants.push("#" + h + "\\b")
    let short = shorten(h)
    if short != none { variants.push("#" + short + "\\b") }
  }
  // Only fully opaque colours can be written without an alpha channel.
  let channels = str(r) + "\\s*,\\s*" + str(g) + "\\s*,\\s*" + str(b)
  if a == 255 {
    variants.push("rgba?\\(\\s*" + channels + "\\s*\\)")
    variants.push("rgba\\(\\s*" + channels + "\\s*,\\s*(?:1(?:\\.0*)?|100%)\\s*\\)")
    let name = _named-colors.at("#" + rgb6, default: none)
    if name != none { variants.push("(?:" + name + ")\\b") }
  }
  variants.join("|")
}

/// Recolours an SVG by replacing every occurrence of one colour with another.
///
/// The colour is matched in presentation attributes (`fill="…"`) and in CSS
/// declarations (`style="fill: …"` or `<style>` blocks) for the properties
/// `fill`, `stroke`, `stop-color`, `flood-color`, `lighting-color` and
/// `color`. Common spellings of `color-before` are recognised
/// case-insensitively: `#000`, `#000000`, `#000000ff`, `rgb(0, 0, 0)`,
/// `black`, and so on.
///
/// SVG renders unfilled shapes black. So when `color-before` is black, the
/// root `<svg>` element also gets a `fill` attribute (unless it already has
/// one), which recolours shapes with no explicit fill.
///
/// The result has the same type as the input (`str` or `bytes`):
///
/// ```typ
/// #let icon = read("icon.svg")
/// #image(bytes(recolor(icon, red)))
/// #image(bytes(recolor(icon, blue, color-before: white)))
/// ```
///
/// -> str | bytes
#let recolor(
  /// The SVG source, for example from `read("file.svg")`.
  /// -> str | bytes
  svg,
  /// The colour to replace `color-before` with.
  /// -> color
  color-new,
  /// The colour in the SVG to replace.
  /// -> color
  color-before: black,
) = {
  assert(
    type(svg) in (str, bytes),
    message: "recolor: `svg` must be a string or bytes, got " + str(type(svg)),
  )
  assert(
    type(color-new) == color,
    message: "recolor: `color-new` must be a color, got " + str(type(color-new)),
  )
  assert(
    type(color-before) == color,
    message: "recolor: `color-before` must be a color, got " + str(type(color-before)),
  )

  let input-type = type(svg)
  let src = if input-type == bytes { str(svg) } else { svg }
  let new-hex = rgb(color-new).to-hex()

  // `(prop + separator)(value)`. Each variant ends in `\b` or `)`, so e.g.
  // `#000` will not match the start of `#0000ff`.
  let pattern = regex(
    "(?i)(\\b(?:"
      + _color-props.join("|")
      + ")\\s*(?:=\\s*[\"']\\s*|:\\s*))(?:"
      + _color-variants(color-before)
      + ")",
  )
  let out = src.replace(pattern, m => m.captures.at(0) + new-hex)

  if rgb(color-before).to-hex() == black.to-hex() {
    let root = out.find(regex("<svg\\b[^>]*>"))
    if root != none and root.find(regex("\\sfill\\s*=")) == none {
      out = out.replace(
        regex("<svg\\b"),
        "<svg fill=\"" + new-hex + "\"",
        count: 1,
      )
    }
  }

  if input-type == bytes { bytes(out) } else { out }
}

/// Loads an SVG file, recolours it with @recolor and returns it as an
/// `image`.
///
/// The file must be given as a `path` rather than a string. A `path` is
/// resolved relative to the file that creates it, whereas a string would be
/// resolved relative to this package.
///
/// ```typ
/// #recolor-image(path("icon.svg"), red, width: 1em)
/// #recolor-image(path("logo.svg"), blue, color-before: white, alt: "Logo")
/// ```
///
/// -> content
#let recolor-image(
  /// The SVG file to load, for example `path("icon.svg")`.
  /// -> path
  source,
  /// The colour to replace `color-before` with.
  /// -> color
  color-new,
  /// The colour in the SVG to replace.
  /// -> color
  color-before: black,
  /// Further named arguments for `image`, such as `width`, `height`, `fit`
  /// or `alt`.
  /// -> arguments
  ..args,
) = {
  assert(
    type(source) == path,
    message: "recolor-image: `source` must be a path, got "
      + str(type(source))
      + if type(source) == str { ". Hint: use path(" + repr(source) + ")" } else { "" },
  )
  assert(
    args.pos().len() == 0,
    message: "recolor-image: unexpected positional arguments " + repr(args.pos()),
  )

  let data = recolor(read(source, encoding: none), color-new, color-before: color-before)
  image(data, format: "svg", ..args.named())
}
