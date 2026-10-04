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

// Values of colour properties that are not colours, and so are never
// replaced when recolouring every colour. `url` is the start of a paint
// reference such as `url(#gradient)`.
#let _non-colors = (
  "url",
  "none",
  "transparent",
  "currentcolor",
  "inherit",
  "initial",
  "unset",
  "revert",
  "context-fill",
  "context-stroke",
)

// Matches any colour value: hex, a colour function or a keyword. Keywords in
// `_non-colors` are filtered out afterwards, as Typst regexes have no
// lookahead.
#let _any-color = (
  "#[0-9a-f]{3,8}\\b"
    + "|(?:rgba?|hsla?|hwb|lab|lch|oklab|oklch|color)\\([^)]*\\)"
    + "|[a-z][a-z-]*\\b"
)

// Replaces `color-before` with `color-new` in the SVG source string `svg`.
// If `color-before` is `none`, every colour is replaced.
#let _recolor(svg, color-new, color-before) = {
  let new-hex = rgb(color-new).to-hex()

  // `(prop + separator)(value)`. Each variant ends in `\b` or `)`, so e.g.
  // `#000` will not match the start of `#0000ff`.
  let pattern = regex(
    "(?i)(\\b(?:"
      + _color-props.join("|")
      + ")\\s*(?:=\\s*[\"']\\s*|:\\s*))("
      + if color-before == none { _any-color } else { _color-variants(color-before) }
      + ")",
  )
  let out = svg.replace(pattern, m => {
    let (prop, value) = m.captures
    if lower(value) in _non-colors { m.text } else { prop + new-hex }
  })

  // Unfilled shapes render black, so they are recoloured through the root.
  if color-before == none or rgb(color-before).to-hex() == black.to-hex() {
    let root = out.find(regex("<svg\\b[^>]*>"))
    if root != none and root.find(regex("\\sfill\\s*=")) == none {
      out = out.replace(
        regex("<svg\\b"),
        "<svg fill=\"" + new-hex + "\"",
        count: 1,
      )
    }
  }

  out
}

/// Recolours an SVG, either entirely or by replacing one colour with another.
///
/// Colours are found in presentation attributes (`fill="…"`) and in CSS
/// declarations (`style="fill: …"` or `<style>` blocks) for the properties
/// `fill`, `stroke`, `stop-color`, `flood-color`, `lighting-color` and
/// `color`.
///
/// By default every colour is replaced with `color-new`. Values that are not
/// colours, such as `none`, `currentColor` or `url(#gradient)`, are left
/// alone. Given a `color-before`, only that colour is replaced. Common
/// spellings of it are recognised case-insensitively: `#000`, `#000000`,
/// `#000000ff`, `rgb(0, 0, 0)`, `black`, and so on.
///
/// SVG renders unfilled shapes black. So when every colour or black is
/// replaced, the root `<svg>` element also gets a `fill` attribute (unless it
/// already has one), which recolours shapes with no explicit fill.
///
/// A file must be given as a `path` rather than a string. A `path` is
/// resolved relative to the file that creates it, whereas a string is taken
/// to be the SVG source itself.
///
/// By default the result is an `image`. With `return-image: false`, the
/// recoloured source is returned instead, with the same type as the input
/// (`bytes` for a `path`). This lets calls be chained to replace several
/// colours:
///
/// ```typ
/// #recolor-svg(path("icon.svg"), red, width: 1em)
/// #recolor-svg(path("logo.svg"), blue, color-before: white, alt: "Logo")
///
/// #let src = recolor-svg(path("logo.svg"), red, color-before: black, return-image: false)
/// #recolor-svg(src, blue, color-before: white)
/// ```
///
/// -> content | str | bytes
#let recolor-svg(
  /// The SVG file, for example `path("icon.svg")`, or its source as a
  /// string or bytes, for example from `read("icon.svg")`.
  /// -> path | str | bytes
  source,
  /// The colour to replace `color-before` with.
  /// -> color
  color-new,
  /// The colour in the SVG to replace, or `none` to replace every colour.
  /// -> color | none
  color-before: none,
  /// Whether to return an `image` rather than the recoloured source.
  /// -> bool
  return-image: true,
  /// Further named arguments for `image`, such as `width`, `height`, `fit`
  /// or `alt`. Only allowed when `return-image` is `true`.
  /// -> arguments
  ..args,
) = {
  assert(
    type(source) in (path, str, bytes),
    message: "recolor-svg: `source` must be a path, string or bytes, got " + str(type(source)),
  )
  assert(
    type(color-new) == color,
    message: "recolor-svg: `color-new` must be a color, got " + str(type(color-new)),
  )
  assert(
    color-before == none or type(color-before) == color,
    message: "recolor-svg: `color-before` must be a color or none, got " + str(type(color-before)),
  )
  assert(
    type(return-image) == bool,
    message: "recolor-svg: `return-image` must be a bool, got " + str(type(return-image)),
  )
  assert(
    args.pos().len() == 0,
    message: "recolor-svg: unexpected positional arguments " + repr(args.pos()),
  )
  assert(
    return-image or args.named().len() == 0,
    message: "recolor-svg: image arguments " + repr(args.named()) + " require `return-image: true`",
  )

  let data = if type(source) == path { read(source, encoding: none) } else { source }
  let out = _recolor(str(data), color-new, color-before)

  if return-image {
    image(bytes(out), format: "svg", ..args.named())
  } else if type(data) == bytes {
    bytes(out)
  } else {
    out
  }
}
