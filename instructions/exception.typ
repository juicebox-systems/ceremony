// Exception Sheets are included at the end of the document.

#import "presentation.typ": blank, blanks, checkbox, radio

// A block element for multi-line input.
#let par_blank(lines) = {
  for _ in range(lines) {
    v(1em)
    line(length: 100%, stroke: 0.5pt)
  }
}

// Returns a section of a document with an Exception Sheet. `i` counts from 1.
// The section can be referred to as `@exception_sheet_(i)`.
#let exception_sheet(i) = [
  = Exception Sheet #i
  #label("exception_sheet_" + str(i))

  #v(0.5em)
  #radio(
    [This exception sheet was not needed.],
    [This exception sheet is used.],
  )

  #blanks[Start time][Step number]
  #checkbox[The exception was noted in the step margin.]

  + What was expected?
    #par_blank(4)

  + What happened instead?
    #par_blank(4)

  + What actions and decisions were taken?
    #par_blank(9)
]
