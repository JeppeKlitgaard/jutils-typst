#import "deps.typ": valkyrie as z

#let _noop = x => x

#let institution-schema = z.dictionary((
  name: z.string(),
  department: z.string(optional: true),
  address: z.string(),
))

#let institution(..args) = {
  z.parse(args.named(), institution-schema)
}

#let author-schema = z.dictionary((
  first-name: z.string(),
  last-name: z.string(),
  e-mail: z.string(optional: true),
  affiliations: z.array(institution-schema),
  corresponding: z.boolean(default: false),
))

#let attribution-schema = z.array(author-schema)

#let author(..args) = {
  z.parse(args.named(), author-schema)
}

#let attribution(..args) = {
  z.parse(args.pos(), attribution-schema)
}

// Render
#let render-authors(
  attribution,
  numbering-affiliations: "a",
  marker-transform: xs => super(xs.join(",")),
  corresponding-transform: underline.with(offset: 0.15em),
  corresponding-marker: "†",
) = {
  let attribution = z.parse(attribution, attribution-schema)
  let ordered-affiliations = attribution.map(a => a.affiliations).flatten().dedup()

  attribution.map(author => {
    let name = author.first-name + " " + author.last-name
    let affiliation-numbers = author.affiliations.map(i => ordered-affiliations.position(x => x == i) + 1)
    let markers = affiliation-numbers.map(n => numbering(numbering-affiliations, n))

    if author.corresponding {
      name = corresponding-transform(name)
      markers.push(corresponding-marker)
    }

    [#name#marker-transform(markers)]
  })
}

#let render-affiliations(
  attribution,
  numbering-affiliations: "a",
  content-transform: emph,
  name-transform: _noop,
  department-transform: _noop,
  address-transform: _noop,
  marker-transform: x => super(x),
) = {
  let attribution = z.parse(attribution, attribution-schema)
  let ordered-affiliations = attribution.map(a => a.affiliations).flatten().dedup()

  ordered-affiliations
    .enumerate()
    .map(((index, affiliation)) => {
      let marker = numbering(numbering-affiliations, index + 1)
      let title = (department-transform(affiliation.department), name-transform(affiliation.name), address-transform(affiliation.address)).filter(x => x != none).join(", ")

      [#marker-transform(marker) #content-transform(title)]
    })
}

#let get-corresponding(
  attribution,
) = {
  let attribution = z.parse(attribution, attribution-schema)
  attribution.filter(a => a.corresponding)
}

#let render-corresponding(
  attribution,
  corresponding-marker: "†",
  content-transform: x => strong(emph(x)),
) = {
  let corresponding-authors = get-corresponding(attribution)

  if corresponding-authors.len() == 0 {
    none
  } else {
    let lead = "Corresponding author"
    if corresponding-authors.len() > 1 { lead += "s" }
    lead += ": "

    let names = corresponding-authors.map(a => a.first-name + " " + a.last-name).join(", ")
    [#corresponding-marker #content-transform(lead + names)]
  }
}
)
