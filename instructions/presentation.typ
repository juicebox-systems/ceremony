// This module includes layout- and styling-related components, settings, and
// helpers.

#import "debug.typ": debug_color, debug_level, debug_text
#import "model.typ"

// Returns an inline element that is a placeholder. `task` should be content
// describing what needs to be done.
#let todo(task) = text(
  fill: red,
  weight: "bold",
  [\[TODO: #task\]]
)

// Returns a block element that's a single, labeled blank space for a
// handwritten word.
#let blank(label) = block[
  #label: #raw("__________________")
]

// Returns a block element consisting of several labeled blank spaces for
// handwritten words. The advantage of `blanks()` over multiple `blank()` calls
// is that the blanks line up. `args` should be the labels.
#let blanks(..args) = grid(
  columns: 2,
  row-gutter: 1em,
  column-gutter: 0.5em,
  ..args.pos().map(item => (
    [#item:],
    raw("__________________")
  )).flatten()
)

// The background color for table headings.
#let fill_color = gray.lighten(50%)

// When used as a `fill` value with `table()`, sets the background color of the
// first row to `fill_color`.
#let header_fill(col, row) = if row == 0 {
  fill_color
} else {
  none
}

// Parameters defining how `entry_array()` and `entry_row()` behave.
#let _entry_params = (
  "bip39": (
    label: "word",
    width: 1in,
    inner_cols: 1,
  ),
  "char": (
    label: none,
    width: 0.35in,
    inner_cols: 1,
  ),
  "hex": (
    label: "byte",
    width: 0.5in,
    inner_cols: 2,
  ),
)

// Helper to `entry_array()` and `entry_row()`: renders a single compound
// "cell".
#let _entry_item(i, values: none, label: none, cols: 1) = table(
  align: center + horizon,
  columns: 1,
  fill: header_fill,
  inset: 0em,
  rows: (1.5em, 1fr),
  table(
    align: if label == none {
      right + horizon
    } else {
      center + horizon
    },
    inset: if label == none {
      5pt
    } else {
      0em
    },
    columns: 1fr,
    rows: 1fr,
    text(
      size: 0.8em,
      [#label #raw(str(i))]
    ),
  ),
  table(
    columns: range(cols).map(_ => 1fr),
    rows: 1fr,
    ..(if values == none {
      ()
    } else {
      values.slice((i - 1) * cols, count: cols).map(raw)
    })
  )
)

// Helper to `entry_array()` and `entry_row()`: renders a single "cell" with
// static content. Used for things like dashes.
#let _entry_special(label) = table(
  align: center + horizon,
  columns: 1fr,
  fill: fill_color,
  rows: 1fr,
  label,
)

// Returns an unlabeled block element used for displaying a multi-row table of
// values or blanks. For example, this is used to show a BIP-39 mnemonic
// phrase.
#let entry_array(type, count, cols, values: none) = {
  let params = _entry_params.at(type)
  block(
    inset: (x: 1em),
    grid(
      columns: range(cols).map(_ => params.width),
      rows: 3.5em,
      ..range(calc.ceil(count / cols)).map(row => (
        range(cols).map(col => {
          let i = row * cols + col
          if i < count {
            _entry_item(
              i + 1,
              label: if values == none {
                params.label
              } else {
                none
              },
              cols: params.inner_cols,
              values: values,
            )
          } else {
            _entry_special("")
          }
        }),
      )).flatten(),
    )
  )
}

// Returns an unlabeled block element used for displaying a single-line array
// of values or blanks. This allows placing special static characters, like
// dashes, in between groups of cells. For example, this is used to record a
// MAC address.
#let entry_row(kind, runs, values: none) = {
  let params = _entry_params.at(kind)
  block(
    inset: (x: 1em),
    grid(
      columns: runs.map(run => if type(run) == array {
        run.map(_ => params.width)
      } else {
        (2em,)
      }).flatten(),
      rows: 3.5em,
      ..runs.map(run => if type(run) == array {
          run.map(i => _entry_item(
            i,
            label: params.label,
            cols: params.inner_cols,
            values: values,
          ))
        } else {
          _entry_special(run)
        }
      ).flatten(),
    )
  )
}

// Returns an unlabeled block element used to display a long hex value or blank
// hex input.
#let hex_full(bytes: none, value: none) = {
  let columns = if bytes == 20 {
    8 // 10 doesn't quite fit the current width
  } else if bytes == 32 {
    8
  } else {
    panic("only support 20 or 32 byte hex entries")
  }
  entry_array(
    "hex",
    bytes,
    columns,
    values: if value == none {
      none
    } else {
      value.codepoints()
    },
  )
}

// Returns a block element used to display a brief hex value or blank hex
// input, only including the first 3 bytes and the last byte.
#let hex_identifying(bytes: none, value: none) = entry_row(
  "hex",
  ((1, 2, 3), "...", (bytes,)),
  values: if value == none {
    none
  } else {
    value.codepoints()
  }
)

// Splits a BIP-39 mnemonic phrase into an array of words. Newlines are allowed
// in the input string.
#let _parse_bip39(phrase) = {
  phrase.split(regex("[ \n]+"))
    .filter(word => word != "")
}

// Returns the number of words in a BIP-39 mnemonic phrase for the given number
// of bytes of entropy.
#let _bip39_words(bytes) = {
  if bytes == 20 {
    15
  } else if bytes == 32 {
    24
  } else {
    panic("only support 20 or 32 byte BIP-39 mnemonics")
  }
}

// Returns a block element used to display an entire BIP-39 mnemonic phrase or
// blank input. The phrase to display, if any, is given as a string.
#let bip39_full(bytes: none, phrase: none) = entry_array(
  "bip39",
  _bip39_words(bytes),
  4,
  values: if phrase == none {
    none
  } else {
    _parse_bip39(phrase)
  }
)

// Returns a block element used to display a BIP-39 mnemonic phrase or blank
// input, only including the first 3 words and the last word. The phrase to
// display, if any, is given as a string.
#let bip39_identifying(bytes: none, phrase: none) = entry_row(
  "bip39",
  ((1, 2, 3), "...", (_bip39_words(bytes),)),
  values: if phrase == none {
    none
  } else {
    _parse_bip39(phrase)
  },
)

// Returns an unlabeled block element with blanks to write a 10-character
// tamper-evident bag ID.
#let blank_bag_id = entry_row(
  "char",
  ((1, 2, 3, 4, 5, 6, 7, 8, 9, 10),)
)

// Returns a block element with a "Bag ID:" label and blanks to write a
// 10-character tamper-evident bag ID.
#let labeled_blank_bag_id = block(
  breakable: false,
  [Bag ID: #blank_bag_id],
)

// Returns an unlabeled block element with blanks to write an electronic serial
// number for an HSM.
#let blank_entrust_esn = entry_row(
  "char",
  ((1, 2, 3, 4), "-", (5, 6, 7, 8), "-", (9, 10, 11, 12))
)

// Returns an unlabeled block element with blanks to write a paper serial
// number for an HSM, excluding the final character.
#let blank_entrust_serial_short = entry_row(
  "char",
  ((1, 2), "-", (3, 4, 5, 6, 7, 8))
)

// Returns an unlabeled block element with blanks to write a paper serial
// number for an HSM, including the final character.
#let blank_entrust_serial_long = entry_row(
  "char",
  ((1, 2), "-", (3, 4, 5, 6, 7, 8), " ", (9,))
)

// Returns an unlabeled block element with blanks to write a MAC address.
#let blank_mac_address = entry_row(
  "hex",
  ((1, 2, 3, 4, 5, 6),)
)

// Returns an unlabeled block element with blanks to write an Entrust smartcard
// ID.
#let blank_smartcard_id = entry_row(
  "char",
  ((1, 2, 3, 4), "-", (5, 6), "-", (7, 8, 9, 10, 11, 12))
)

// Inline element used for checkboxes.
#let checkbox_symbol = sym.ballot

// Inline element used for radio selections.
#let radio_symbol = sym.circle.stroked.big

// Returns a block element used to require the operator to complete a task.
// `confirming` should be content describing what the operator needs to do.
#let checkbox(confirming) = grid(
  rows: 1,
  columns: 2,
  gutter: 0.5em,
  checkbox_symbol,
  confirming,
)

// Returns a block element used to require the operator to complete a
// checklist. The checklist is formatted as a table with borders. This is used
// for the "Materials" table, but usually consecutive `checkbox()` calls are
// preferable, since they align naturally without all the borders.
#let checkboxes(title: none, ..args) = table(
  columns: 1,
  fill: header_fill,
  inset: 0em,
  if title != none {
    block(
      inset: 5pt,
      [*#title*],
    )
  },
  table(
    columns: (auto, 1fr),
    ..args.pos().map(item => (
      checkbox_symbol,
      [#item],
    )).flatten(),
  )
)

// Returns a block element used to require the operator to complete exactly one
// of the given tasks. The `args` should be content describing each option.
#let radio(..args) = table(
  columns: 1,
  fill: header_fill,
  inset: 0em,
  block(
    inset: 5pt,
    [Choose exactly one of the following:],
  ),
  table(
    columns: (auto, 1fr),
    ..args.pos().map(item => (
      radio_symbol,
      [#item],
    )).flatten(),
  )
)

// Returns an inline element describing a field of output, possibly nested.
// Typically the `args` are given as backtick-quoted text.
//
// Example:
//
// ```typst
// #outpath[`Form 1040`][`Income`][`3a. Qualified dividends`]
// ```
//
// Renders like: Form 1040 > Income > 3a. Qualified dividends
#let outpath(..args) = args.pos().join([ #sym.gt.tri ])

// Returns an inline element descibing a keyboard sequence. Each of `args` can
// either be a simple key or an array of keys to press together.
#let keys(..args) = {
  args.pos().map(arg => {
    if type(arg) == array {
      arg.map(k => raw(block: false, k)).join("-")
    } else {
      raw(block: false, arg)
    }
  }).join(h(0.5em))
}

// Returns an inline element describing a single character in Morse code. `s`
// should be a sting made up of only "-" and "." characters.
#let morse_code(s) = {
  h(0.25em)
  text(
    hyphenate: false,
    weight: "black",
    s
      .replace(".", sym.dot.c)
      .replace("-", sym.dash.en)
      .codepoints()
      .join(sym.space.thin)
  )
  h(0.25em)
}

// Returns a large block element including the entire state of the model
// variables.
#let debug_model() = {
  set text(fill: debug_color, size: 0.9em)
  block(
    breakable: false,
    table(
      columns: 2,
      fill: header_fill,
      [*Model State*], [*Value*],
      ..model.debug_model().pairs().flatten(),
    )
  )
}

// Returns `s` preceded by repeated `padding` such that the result is at least
// `length` bytes long. If `s` is not a string, it is stringified.
#let left_pad(s, len, padding) = {
  s = str(s)
  while s.len() < len {
    s = padding + s
  }
  s
}

// Test for `left_pad`.
#for (input, len, expected) in (
  ("", 0, ""),
  ("", 1, "_"),
  ("", 1, "_"),
  ("a", 1, "a"),
  ("a", 2, "_a"),
  ("a", 4, "___a"),
  ("abc", 2, "abc"),
  ("abc", 5, "__abc"),
  (3, 2, "_3"),
  (3.2, 4, "_3.2"),
) {
  let actual = left_pad(input, len, "_")
  assert(
    actual == expected,
    message: "expected " + repr(expected) + " but got " + repr(actual),
  )
}


// Keeps track of the globlal `step()` number.
#let _step_counter = counter("steps")

// Keeps track of the running estimated cumulative time for all steps.
#let _clock = state("clock", 0) // in seconds

// Helper for `current_time`. Returns the given number of seconds formatted as
// hours and minutes.
#let _format_clock(now) = {
  let h = calc.floor(now / 60 / 60)
  let m = calc.floor(calc.rem(now / 60, 60))
  str(h) + "h" + left_pad(m, 2, "0") + "m"
}

// Test for `_format_clock`:
#for (input, expected) in (
  (0, "0h00m"),
  (59, "0h00m"),
  (60, "0h01m"),
  (3599, "0h59m"),
  (3600, "1h00m"),
  (3600 * 24, "24h00m"),
) {
  let actual = _format_clock(input)
  assert(
    actual == expected,
    message: "expected " + repr(expected) + " but got " + repr(actual),
  )
}

// Returns an inline element with the running estimated cumulative time
// taken by all steps.
#let current_time = _clock.display(_format_clock)

// Returns the given number of seconds formatted as minutes and seconds.
#let _format_duration(d) = {
  let m = calc.floor(d / 60)
  let s = calc.floor(calc.rem(d, 60))
  str(m) + "m" + left_pad(s, 2, "0") + "s"
}

// Test for `_format_duration`:
#for (input, expected) in (
  (0, "0m00s"),
  (59, "0m59s"),
  (60, "1m00s"),
  (63, "1m03s"),
) {
  let actual = _format_duration(input)
  assert(
    actual == expected,
    message: "expected " + repr(expected) + " but got " + repr(actual),
  )
}

// Returns the number of seconds parsed from a duration string. The string
// should be in the format "1m 2s", "1m", or "2s".
#let parse_duration(d) = {
  let match = d.match(regex("^((\d+)m ?)?((\d+)s)?$"))
  let m = match.captures.at(1)
  let s = match.captures.at(3)
  assert(m != none or s != none)
  let m = if m == none { 0 } else { int(m) }
  let s = if s == none { 0 } else { int(s) }
  m * 60 + s
}

// Test for `parse_duration`:
#for (input, expected) in (
  ("00s", 0),
  ("0m", 0),
  ("1m2s", 62),
  ("3m 4s", 184),
  ("10m", 600),
  ("62s", 62),
  ("1m 62s", 122),
) {
  let actual = parse_duration(input)
  assert(
    actual == expected,
    message: "expected " + repr(expected) + " but got " + repr(actual),
  )
}


// Returns a large block element with a table grouping consecutive, related
// steps to take in the ceremony. The given `args` should be return values from
// `step()`; nested arrays of steps are flattened for convenience.
#let steps(..args) = {
  set par(justify: false)

  block(breakable: false, {
    v(0.5em)
    if debug_level >= 1 [
      Start time: #underline[#debug_text[#current_time]]
    ] else [
      #blank[Start time]
    ]
    v(-0.5em)
  })

  if debug_level >= 2 {
    debug_model()
  }

  table(
    columns: (0.35in, 1fr, 1in),
    align: (center, left, center, center),
    fill: header_fill,

    [*Step*], [*Activity*], [*End Time*],
    ..args.pos().flatten().map(child => (
      // Bookkeeping for step number and time, include the step's reference
      // label if present, and display the step number.
      {
        _step_counter.step()
        _step_counter.display()
        _clock.update(now => now + child.time)

        if child.at("label", default: none) != none [
          #assert(
            type(child.label) == label,
            message: "step label must be a <label>",
          )
          // The label needs to attach to some non-paragraph element, so we use
          // a 0-width space.
          #h(0em)
          #child.label
        ]
      },

      // Details of what the operator should do.
      block(
        breakable: false,
        [
          #child.body
          #if debug_level >= 3 [
            #debug_model()
          ]
        ]
      ),

      // The end time column (with the time estimate in debug mode).
      [
        #if debug_level >= 1 [
          #debug_text[
            +#_format_duration(child.time)
            #linebreak()
            =#current_time
          ]
        ]
      ]
    )).flatten(),
  )
}

// Returns an object to be passed to `steps()`. `body` should be content
// describing what the operator should do.
//
// `time` is a required estimate for how long the step will take, beyond that
// of a trivial step. See `parse_duration()` for the format.
//
// `label` is an optional `<foo_step>` label that can be used later with
// `ref_step(<foo_step>)` to resolve to a link like `Step 45`.
#let step(body, label: none, time: none) = {
  assert(time != none)
  (
    body: body,
    label: label,
    // 20 seconds is the baseline overhead for a very simple step
    time: parse_duration(time) + 20,
  )
}

// Returns a link referring to a particular step. The label should be a `<foo>`
// label that is or will be registered with `step()`.
#let ref_step(label) = {
  locate(here_loc => {
    let label_locs = query(label, here_loc)
    assert(
      label_locs.len() > 0,
      message: "can't find label: " + repr(label),
    )
    let label_loc = label_locs.first().location()
    let step = _step_counter.at(label_loc).first()
    link(label, "Step" + sym.space.nobreak + str(step))
  })
}

// Sets up the main document and displays the title.
#let ceremony_doc(
  title: "",
  author: (),
  body,
) = {
  set document(title: title, author: author)
  set page(
    paper: "us-letter",
    margin: (bottom: 1.5in, rest: 1in),
    footer: [
      #set align(right)
      #blank[Date]
      #blank[Initials]
      page #counter(page).display("1 of 1", both: true)
    ]
  )

  set heading(numbering: "1.1")
  set par(justify: true)
  set enum(indent: 0.5em)
  set list(indent: 0.5em)

  show link: underline

  show heading: (it) => {
    if it.level == 1 {
      pagebreak(weak: true)
    }
    block({
      if it.numbering != none {
        if it.level == 1 and it.supplement == [Appendix] [
          Appendix
          #counter(heading).display(it.numbering):
        ] else [
          #counter(heading).display(it.numbering)
        ]
        h(0.3em, weak: true)
      }
      it.body
    })
  }

  show raw.where(block: true): it => block(
    fill: gray.lighten(80%),
    inset: (x: 0.5em, y: 0.5em),
    width: 100%,
    it
  )

  show raw.where(block: false): it => box(
    baseline: 0.2em,
    fill: gray.lighten(80%),
    inset: (x: 0.1em, y: 0.2em),
    outset: (x: 0.1em, y: 0.2em),
    it
  )

  align(center)[
    #text(size: 1.75em, weight: 500, title)
    #v(1em)
  ]

  body
}

// Switches from normal sections to appendix sections with `#show: appendices`.
#let appendices(body) = {
  counter(heading).update(0)
  set heading(
    supplement: [Appendix],
    numbering: "A.1",
  )
  body
}

// Returns a large block element containing samples of many of the available
// reusable elements. This is useful when modifying the elements to make sure
// they render nicely. This is added to the document as an appendix when
// `debug_level >= 2`.
#let component_demo = steps(
  step(time: "0s", [
    Outpath:

    Look for #outpath[`1`][two goes next][`three`] in the output.
  ]),

  step(time: "0s", [
    Keys:

    Press #keys(("Shift", "a"), "x") on the keyboard.
  ]),

  step(time: "0s", [
    Blank:
    #blank("a")

    Blanks (aligned):
    #blanks[bee][c]
  ]),

  step(time: "0s", [
    Checkboxes:

    #checkbox("a")
    #checkbox(lorem(30))
    #checkboxes[bee][#lorem(30)][d]
    #checkboxes(title: "Title")[d][e]
  ]),

  step(time: "0s", [
    Radio:

    #radio[a][bee][#lorem(30)]
  ]),

  step(time: "0s", [
    Blank Entrust serial number (short):
    #blank_entrust_serial_short

    Blank Entrust serial number (long):
    #blank_entrust_serial_long

    Blank Entrust ESN:
    #blank_entrust_esn

    Blank MAC address:
    #blank_mac_address
  ]),

  step(time: "0s", [
    20 bytes hex:

    Blank full:
    #hex_full(bytes: 20)

    Blank identifying bytes:
    #hex_identifying(bytes: 20)

    Full value:
    #hex_full(
      bytes: 20,
      value: "84248cee9c1748b70e4f05e6410595a93411ea1b",
    )

    Identifying bytes:
    #hex_identifying(
      bytes: 20,
      value: "84248cee9c1748b70e4f05e6410595a93411ea1b",
    )
  ]),

  step(time: "0s", [
    32 bytes hex:

    Blank full:
    #hex_full(bytes: 32)

    Blank identifying bytes:
    #hex_identifying(bytes: 32)

    SHA-256:
    #hex_full(
      bytes: 32,
      value: "4b19f93985225dd2a6f0de863830272f458ead1c2f8c1a6459c6584d20350ac6"
    )


    Identifying bytes:
    #hex_identifying(
      bytes: 32,
      value: "4b19f93985225dd2a6f0de863830272f458ead1c2f8c1a6459c6584d20350ac6"
    )
  ]),

  step(time: "0s", [
    20 bytes BIP-39:

    Blank full:
    #bip39_full(bytes: 20)

    Blank identifying words:
    #bip39_identifying(bytes: 20)

    Full:
    #bip39_full(
      bytes: 20,
      phrase: "
        remember bind flat patch
        banana recall possible tourist
        width cycle fringe next
        visa people private
      ",
    )

    Identifying bytes:
    #bip39_identifying(
      bytes: 20,
      phrase: "
        remember bind flat patch
        banana recall possible tourist
        width cycle fringe next
        visa people private
      ",
    )
  ]),

  step(time: "0s", [
    32 bytes BIP-39:

    Blank full:
    #bip39_full(bytes: 32)

    Blank identifying words:
    #bip39_identifying(bytes: 32)

    Full:
    #bip39_full(
      bytes: 20,
      phrase: "
        remember bind flat patch
        banana recall possible tourist
        width cycle fringe next
        visa people private ready
        price tree comic glow
        together print annual cash
      ",
    )

    Identifying bytes:
    #bip39_identifying(
      bytes: 20,
      phrase: "
        remember bind flat patch
        banana recall possible tourist
        width cycle fringe next
        visa people private ready
        price tree comic glow
        together print annual cash
      ",
    )
  ]),
)
