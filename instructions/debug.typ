// Debug levels:
// - 0: Used for the final PDF with no debugging output.
// - 1: Shows estimated timestamps.
// - 2: Shows the component demo appendix, the requirements of each step, and
//      the model variables at the start of each set of steps.
// - 3: Shows the model variables after each step.
#let debug_level = 0

#let debug_color = green

#let debug_text(content) = text(fill: debug_color, content)

// Some "panics" (mostly used in the model) can be hard to understand and
// locate when they don't generate a PDF. Set this to false to turn them into
// soft errors, with the label "ERROR:" inline in the document.
#let errors_fatal = true

// A "panic" that can be made non-fatal with `errors_fatal`. The `message`
// should be a string.
#let error(message) = {
  if errors_fatal {
    panic(
      "ERROR",
      message,
      "Rerun with `errors_fatal = false` to see the error in the document"
    )
  } else {
    block(
      text(
          fill: red,
          weight: bold,
          [ERROR: #message]
      )
    )
  }
}
