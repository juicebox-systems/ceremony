# Juicebox HSM Key Ceremony

This repo contains several components:

- [`boot-dvd`](./boot-dvd) contains scripts to create the reproducible boot DVD
  used during the ceremony.

- [`instructions`](./instructions) contains a document describing the steps of
  the ceremony. The printout serves as the record of the ceremony.

- [`tool`](./tool) contains a program that runs as the `ceremony` command on
  the boot DVD, providing a collection of predetermined commands.

- [`vendor-dvd`](./vendor-dvd) contains scripts to create a DVD with non-public
  files provided by the HSM vendor. This DVD is needed during the ceremony.
