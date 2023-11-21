# Ceremony Instructions

This directory contains the ceremony instructions in source form.

## Build the PDF

You can build using Docker, which creates reproducible output:

```sh
./build.sh
```

Or, install [Typst](https://github.com/typst/typst) and then run:

```sh
typst compile --root .. ceremony.typ
```

This way is likely to use different fonts and therefore result in a byte-wise
different PDF.
