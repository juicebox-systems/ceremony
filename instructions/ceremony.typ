#import "data.typ": /*
  */ boot_dvd_sha256, /*
  */ git_commit_hash, /*
  */ known_hashes, /*
  */ read_sha256sums, /*
  */

#import "debug.typ": debug_level, debug_text

#import "exception.typ": exception_sheet

#import "model.typ": /*
  */ assert_card, /*
  */ assert_card_reader, /*
  */ assert_card_reader_connected, /*
  */ assert_component_loaded, /*
  */ assert_computer_on, /*
  */ assert_computer_plugged_in, /*
  */ assert_dvd_drive, /*
  */ assert_hsm_installed, /*
  */ assert_hsm_mode, /*
  */ assert_wrist_strap_connected, /*
  */ boot_dvd, /*
  */ boot_dvd_title, /*
  */ realm_dvd, /*
  */ realm_dvd_title, /*
  */ set_card_reader, /*
  */ set_component_loaded, /*
  */ set_wrist_strap_connected, /*
  */ vendor_dvd, /*
  */ vendor_dvd_title, /*
  */

#import "presentation.typ": /*
  */ appendices, /*
  */ bip39_full, /*
  */ bip39_identifying, /*
  */ blank, /*
  */ blank_mac_address, /*
  */ blank_smartcard_id, /*
  */ blanks, /*
  */ ceremony_doc, /*
  */ checkbox, /*
  */ checkbox_symbol, /*
  */ checkboxes,/*
  */ component_demo, /*
  */ entry_array, /*
  */ fill_color, /*
  */ header_fill, /*
  */ hex_identifying, /*
  */ keys, /*
  */ labeled_blank_bag_id, /*
  */ morse_code, /*
  */ outpath, /*
  */ radio, /*
  */ radio_symbol, /*
  */ ref_step, /*
  */ step, /*
  */ steps, /*
  */ todo, /*
  */

#import "routines.typ": *

#show: body => ceremony_doc(
  title: "Juicebox Realm Initialization Ceremony",
  author: "Juicebox Systems, Inc",
  body,
)

This document contains instructions for conducting a key ceremony to initialize
a Juicebox HSM realm.

The source code for this document is available at
#link("https://github.com/juicebox-systems/ceremony")
and identified by the Git commit hash #raw(block: false, git_commit_hash).

Identifying bytes of the SHA-256 hash of the PDF file built from that source
code:
#hex_identifying(bytes: 32)

#block(
  width: 50%,
  radio[Practice ceremony][Production ceremony]
)

#blanks[Codename][Date][Start time][Location]

#pagebreak(weak: true)
#outline(
  indent: auto,
  fill: text(
    fill: gray,
    repeat([.#h(.25em)]),
  ),
)

= Introduction

The purpose of the ceremony is to create cryptographic keys that may only be
accessed within the trust boundaries of a fixed set of HSMs, and only while
those HSMs execute a fixed software release. Additionally, the initialization
process will create a single NVRAM file on each HSM for only the fixed software
release to read and write.

One of the cryptographic keys to be generated is an asymmetric key pair used
for encrypted communication with clients. Assuming the private key is indeed
restricted to this software release on these HSMs, clients using the public key
recorded during this ceremony will have certainty that they are communicating
with this software running on the HSMs initialized during this ceremony.

The HSMs used in the ceremony are PCIe expansion cards and thus require a host
computer. The HSMs, software, and ceremony are designed so that secrets are
never accessible to the host computer. However, the security of the realm
depends on the host computer making the correct management requests to the HSMs
and presenting the expected HSM software build to the first HSM to be signed.
The ceremony will use a brand new computer that is never connected to a
network.

The computer's factory Windows OS will be used to verify the hashes of a
publicly auditable "#boot_dvd", as well as a vendor-proprietary "#vendor_dvd".
Then, the Linux OS on the #boot_dvd will be used for the main ceremony. See
@state_appendix for details on the DVDs and state management.

Each HSM has an external port for a smartcard reader/writer. The HSMs read and
write secret keys onto smartcards for administrative operations. The ceremony
will utilize two smartcards, referred to as "ACS" and "OCS". The smartcards
must be used only as prescribed and must be destroyed during the ceremony.

The ceremony will involve setting up a computer, then using the first HSM to
initialize a "Security World", write to two smartcards, sign the software, and
create the realm keys. The OCS smartcard will be destroyed after it is used to
sign the software. The keys reside in encrypted form on the host filesystem
(protected by keys that reside on the HSMs and smartcards). As that filesystem
is in volatile memory, the signed software and keys will be burned to a
"#realm_dvd" to be accessed later, both during the ceremony and after the
ceremony to set up the production environment.

After completing the Security World and realm initialization process on the
first HSM, the HSM will be reset. Then, each of the five HSMs (including the
first) will be enrolled in the Security World and have its NVRAM file
initialized. After the final HSM has been initialized, the ACS smartcard will
be destroyed.

= Procedures

The following roles are defined for participants of the ceremony:

 - The MC introduces the event, keeps it moving, and is the final decision
   maker for any exceptions, as explained below.

 - The Operator executes the steps as instructed in this document. The Operator
   should be the only person to approach or access the computer, HSMs, and
   smartcards during the ceremony. The Operator's copy of this document is the
   official record.

 - Any number of witnesses observe the ceremony.

A small number of other non-participants may also be present for (parts of) the
ceremony, for example to record video.

If, at any point, the instructions are ambiguous, contain an error, fail to
instruct the operator in a particular situation, or must be deviated from, the
operator should write "Exception" in the margin and fill out an "Exception
Sheet". Several sheets are included at the end of this document
(@exception_sheet_1 through @exception_sheet_5). The participants may then
discuss concerns and options, but the MC ultimately decides how to proceed.

In this document, a checkbox (#checkbox_symbol) denotes a confirmation step that
is not optional. If the operator is unable to meet the requirements to check a
checkbox, that's an exception. A circle (#radio_symbol) is used when exactly one
of multiple mutually exclusive options is required.

The ceremony is expected to take about 6 hours. The ceremony instructions
include one break at #ref_step(<intermission>), about halfway through, allowing
(and requiring) the participants to leave the room. If any of the participants
need to leave the room at other times, that should be handled as an exception.


= Participants

#block(
  breakable: false,
  [
    This document is filled out by the following person:

    #blanks[Name][Affiliation]
  ]
)

#v(1em)

#block(
  breakable: false,
  [
    Ceremony participants:

    #block(
      inset: (x: 2em),
      [
        #set text(size: 0.9em, weight: "bold")
        Do not initial until the completion of the ceremony. By initialing in
        this table, you agree that:

        - You were present for the entire ceremony (excluding breaks).
        - To the best of your knowledge, the instructions in this document were
          followed correctly (except as noted elsewhere in this document) and
          without deception.
        - To the best of your knowledge, this document is a true and accurate
          record.

        If you do not agree, write "do not agree" instead of your initials and
        record an explanation.
      ]
    )

    #table(
      columns: (auto, 1fr, 1fr, 1in),
      align: (center, center, center),
      fill: header_fill,
      [*Role*], [*Name*], [*Affiliation*],
      [*Initials* \ (see above)],
      [MC], [], [], [],
      [Operator], [], [], [],
      ..range(10).map(i =>
        ([Witness], [], [], [])
      ).flatten()
    )
  ]
)

= Getting Started

== Materials <materials>

#steps(
  step(time: "1m", [
    Inspect the operator and the environment.

    #checkbox[
      There is a prominent analog clock with a second hand.
    ]
    #checkbox[
      There are two outlets available on the wall or a power strip nearby.
    ]
  ]),

  step(time: "5m", [
    Inspect the materials available to the operator.

    #checkbox[
      The materials below are available and do not appear tampered with.
    ]
    #checkbox[No other materials are available to the operator.]
  ]),
)

#let computer_brand = "Lenovo"
#let computer_model = "90T2000SUS"

#checkboxes(
  title: [Materials],
  [1 antistatic wrist strap],
  [1 pair of scissors],
  [1 Phillips screwdriver],
  [1 rotary tool to sand through smartcards],
  [1 table number holder (to display smartcards prominently when not in use)],

  [2 printouts of this document],
  [1 permanent marker],
  [1 roll of masking tape],
  [2 blue pens],
  [2 bottles of water],
  [2 juice boxes (preferably apple)],
  [
    1 sealed pack of 100 tamper-evident bags (ProAmpac GCS0912)

    // We need these to be secure, with sequential IDs, and large enough to
    // fit HSMs, card readers, or this printed document.
    //
    // The Root DNSSEC KCK Ceremony 50 script declares these bags acceptable:
    // AMPAC:
    // - GCS1013 (may be discontinued?).
    // - GCS0912 (appears to be the ProAmpac Valut Bundle Federal Compliant
    //   Bags, 9.75x12 size, clear, single-pocket).
    // - GCS1216 (appears to be the ProAmpac Valut Bundle Federal Compliant
    //   Bags, 12.75x16 size, clear, single-pocket).
    // MMF Industries (no direct web presence?):
    // - 2362010N20
    // - 2362011N20
  ],

  [1 pre-burned and finalized #boot_dvd],
  [1 pre-burned and finalized #vendor_dvd],
  [1 sealed spindle of blank DVD-Rs (for the #realm_dvd)],
  [
    1 #computer_brand #computer_model computer with a DVD burner and keyboard,
    further sealed by the purchaser with tamper-evident tape
  ],
  [
    1 VGA video projector, limited to a low resolution (so the text is visible
    to all participants)
  ],
  [
    1 sealed pack of 10 Entrust smartcards
    #v(1in) // layout hack
  ],
  [At least 5 of the following Entrust HSMs:

    #let hsm_row(sn, esn, packaging) = (
      raw(sn, block: false),
      raw(esn, block: false),
      packaging,
      radio_symbol,
      radio_symbol,
      [\##raw("____")],
    )

    #table(
      columns: 6,
      align: center,
      fill: header_fill,
      [*Serial Number*], [*ESN*], [*Packaging*], [*Present*], [*Absent*], [*Used As*],
      ..hsm_row("46-X19834", "A114-05E0-D947", [#todo[Bag ID]]),
      ..hsm_row("46-X20349", "B216-05E0-D947", [#todo[Bag ID]]),
      ..hsm_row("46-X20517", "3B17-05E0-D947", [#todo[Bag ID]]),
      ..hsm_row("46-X21267", "341A-05E0-D947", [Factory]),
      ..hsm_row("46-X21271", "351A-05E0-D947", [Factory]),
      ..hsm_row("46-X21323", "611A-05E0-D947", [Factory]),
    )

    The first HSM used in the ceremony should be in factory packaging, which
    includes a smartcard reader. Fill in the "Used As" column as you unpack the
    HSMs ("\#1", "\#2", etc). The serial number sometimes contains an
    additional character after the space (likely `A`), not included here.
  ],
)

== Set Up the Computer <set_up_computer>

#steps(
  step(label: <inspect_computer_packaging>, time: "5m", [
    Inspect the computer packaging:

    #checkbox[The box does not appear tampered with.]
    #checkbox[
      The box ends are sealed with customer-applied tamper-evident tape,
      on top of somewhat loose #(computer_brand)-branded tape.
    ]

    Inspect the #computer_brand sticker:
    - #checkbox[
        The model (#outpath[`(31P) M/T Model`]) is
        #raw(block: false, computer_model).
      ]
    - Serial Number #outpath[`S(SN)`]:
      #entry_array("char", 8, 8)
    - Wi-Fi MAC address (#outpath[`WMAC`]):
      #blank_mac_address
    - #blank[#outpath[`Mfg Date`] (as printed)]

    Inspect the shipping sticker(s):
    - #blank[#outpath[`SHIP DATE`] (as printed)]
  ]),

  step(time: "4m30s", [
    Open the computer box from the top with scissors.

    *Outer Box:*
    - Remove the small box containing the mouse and power cord from the outer
      box.
    - Remove the long box containing the keyboard from the outer box.
    - Remove the computer, sandwiched by two large pieces of foam, from the
      outer box.
    - Put away the outer box.

    *Desktop:*
    - Remove the foam from the desktop, and put away the foam.
    - Remove the plastic bag surrounding the desktop (which is not sealed), and
      put away the bag.

    *Keyboard Box:*
    - Open the keyboard box.
    - Remove the keyboard from its surrounding plastic (which is not sealed).
    - Inspect the keyboard and the label under it.
      #blank[Date on label under keyboard (#outpath[`MFG`], as shown)]
    - Remove the twist tie on the keyboard's USB cable.
    - Put away the keyboard box, plastic bag, and twist tie.

    *Mouse and Power Cord Box:*
    - Open the mouse and power cord box.
    - Remove the power cable from the box.
    - Remove the twist tie and plug cover on the power cable, and put away the
      tie and cover.
    - Remove the mouse (still in a plastic bag) and paperwork from the box,
      place them into a tamper-evident bag, and put away the bag. (We don't
      expect to need the mouse during this ceremony.)
      #labeled_blank_bag_id
    - Retain the empty box to prop up the DVD drive later.

    #checkbox[The box contents did not appear tampered with or used.]
  ]),

  step(time: "3m", [
    Inspect the computer case. Set it down on its right side to inspect the
    label on the bottom.

    #checkbox[The case does not appear tampered with.]
    #checkbox[A Windows sticker is present on the left side panel.]
    #checkbox[An Intel Core i5 sticker is present on the front panel.]
    #checkbox[
      The serial number matches the label on the box
      (#ref_step(<inspect_computer_packaging>)).
    ]
    #checkbox[
      The manufacturing date (#outpath[`Mfg Date`]) matches the label on the
      box (#ref_step(<inspect_computer_packaging>)).
    ]
  ]),

  step(time: "2m30s", [
    Remove the left panel of the case and the front panel:

    - Unscrew the two screws holding the left panel in place using the
      screwdriver.
    - Remove the left panel, and put it away.
    - Ground yourself to the unpainted computer chassis with the antistatic
      wrist strap. It can be worn on your upper arm or ankle.
    - Lift up on the three plastic tabs (top, middle, bottom) to get the left
      side of the front panel off.
    - Wiggle the front panel off, and put it away.

    #checkbox[
      The power supply's wattage rating (labeled as
      #outpath[`Total output continuous shall not exceed`]) is 260 W.
    ]

    #set_wrist_strap_connected(true)
  ]),

  step(time: "2m30s", [
    Remove the SATA drive shelf:

    - Brace the DVD drive and press the black and red tab towards the front of
      the computer release it. Note: it may eject forcefully.
    - Unplug the SATA and power cables from the back of the DVD drive.
    - Set the DVD drive nearby on top of the box that the mouse and power cable
      came in (since the cables are too short to set the drive down on the
      table).
    - Unplug the SATA and power cables from the 3.5" hard drive.
    - Pull up on the silver and red tab (on the front, left side, middle) to
      release the SATA drive shelf.
    - Wiggle the SATA drive shelf off (with the 3.5" hard drive attached),
      and put away the drive shelf.
    - Plug the SATA and power cables back into the DVD drive.
  ]),

  step(time: "3m30s", [
    Remove the wireless card and antennas:

    - Pull up forcefully on the plastic pin holding the wireless card in place
      (near where the DC cables come out of the power supply).
    - Remove a small bit of clear plastic that the pin was on.
    - Remove the wireless card from the slot.
    - Gently pry the two antenna cables from the wireless card.
    - Pull forcefully on the front antenna to overcome the adhesive,
      then remove any tape holding the cable and pull the cable through.
    - Remove the plastic antenna cover on the back of the case by pushing the
      tab on top (near the case fan) and wiggling the cover off.
    - Pull forcefully on the rear antennas to overcome the adhesive,
      then remove any tape holding the cable and pull the cable through.

    #checkbox[
      The Wi-Fi MAC address (#outpath[`WFM`]) on the wireless card's label
      matches the label on the computer box
      (#ref_step(<inspect_computer_packaging>)).
    ]

    Place the wireless card, antennas, and plastic bits into a tamper-evident
    bag for storage.
    #labeled_blank_bag_id
  ]),

  step(time: "1m", [
    Prepare the PCIe x16 slot:

    - Pull up on the silver and red tab above the placeholder brackets near the
      PCIe slots to open the flap.
    - Remove the metal placeholder bracket blocking the PCIe x16 slot and put
      it away.
    - Close the metal flap.
  ]),

  step(time: "3m", [
    Open the projector packaging, and put away the packaging.

    #checkbox[The packaging does not appear tampered with.]
    #checkbox[The projector does not appear tampered with.]
  ]),

  step(time: "30s", [
    Plug in the projector power and turn on the projector.
  ]),

  step(time: "30s", [
    Plug the USB keyboard and VGA projector into the computer.
  ]),

  boot_into_windows(),

  step(time: "1m", [
    When the Windows "Out of Box Experience" prompts for input (asking for your
    country or region):

    - Press #keys(("Shift", "F10")) to open a terminal. (Do not use the
      terminal. Opening it switches focus, which enables more hotkeys.)
    - Press #keys(("Win", "r")) to open a Run dialog.
    - Run `powershell`.
    - Press #keys(("Win", "Up")) to maximize the Powershell window.
  ]),

  load_dvd(boot_dvd),

  step(time: "1m30s", [
    Calculate the SHA-256 hash of the #boot_dvd image.

    ```powershell
    $s = [system.io.file]::open('\\.\e:', 'open', 'read', 'read')
    get-filehash -inputstream $s
    $s.close()
    ```

    The `get-filehash` command should take about 1 minute.

    // This displays 3 column headers and one row:
    // Algorithm: SHA256
    // Hash: 64 hex characters (uppercase)
    // Path: empty

    #checkbox[
      The #boot_dvd's SHA-256 digest matches
      #raw(block: false, boot_dvd_sha256).
    ]
  ]),

  step(time: "3m", [
    Copy the main filesystem image and a small script from the #boot_dvd onto
    the NVMe drive.

    ```powershell
    dir
    cp -verbose e:\live\filesystem.squashfs
    cp -verbose e:\entrust.ps1
    dir
    ```

    This will copy the files into `C:\Users\defaultuser0\`. The first copy
    command should take about 2 minutes, and the second one should take up to a
    few seconds.
  ]),

  load_dvd(vendor_dvd),

  step(time: "10m", [
    Copy the Entrust-provided files from the #vendor_dvd onto the NVMe drive.

    ```powershell
    cat entrust.ps1
    set-executionpolicy -scope process unrestricted
    .\entrust.ps1
    dir
    ```

    Enter #keys("Y") for yes when setting the policy.

    The script verifies the hashes of the files and copies them into
    `C:\Users\defaultuser0\`. It should take about 10 minutes. During this
    time, review @state_appendix, which discusses the various DVDs and files.
  ]),

  load_dvd(boot_dvd),

  power_off(os: "windows"),

  boot_into_dvd(uefi_setup: true),

  step(time: "2m", [
    Display some information about the computer's devices:

    ```sh
    lsblk
    lsusb
    lspci | nl
    ```

    #checkbox[
      `lsblk` reports `loop0` (loopback devices), `sr0` (the DVD drive),
      `nvme0n1` with 4 partitions (the Windows disk), and no other block
      devices.
    ]
    #checkbox[
      `lsusb` reports a "3.0 root hub", a "2.0 root hub", a "Lenovo New
      Calliope USB Keyboard", and no other USB devices.
    ]
    #checkbox[
      `lspci` reports 24 devices: 22 from Intel, a "Non-Volatile memory
      controller" from Samsung Electronics, and an "Ethernet controller" from
      Realtek Semiconductor.
    ]
  ]),

  power_off(),
)

= Realm Creation <realm_creation>

== Prepare the First HSM

#steps(
  unpack_hsm(first: true),
  boot_into_dvd(),
  initialize_hsm(0),
)


== Unpack the Smartcards

#steps(
  step(time: "30s", [
    Inspect the smartcard packaging.

    #checkbox[The packaging does not appear tampered with.]
  ]),

  step(time: "1m", [
    Open the smartcard packaging. Take out two cards, and put the rest in a
    tamper-evident bag.

    #labeled_blank_bag_id
  ]),

  step(time: "1m20s", [
    Inspect the first smartcard. Label it "OCS".

    #checkbox[The smartcard does not appear tampered with.]
    #checkbox[The smartcard has nShield and Entrust trademarks.]
    Smartcard ID:
    #blank_smartcard_id
  ]),

  step(label: <acs_id>, time: "1m20s", [
    Inspect the second smartcard. Label it "ACS".

    #checkbox[The smartcard does not appear tampered with.]
    #checkbox[The smartcard has nShield and Entrust trademarks.]
    Smartcard ID:
    #blank_smartcard_id
  ]),

  step(time: "2m", [
    Ask a few witnesses to choose a distinctive character or shape, and draw
    these on the cards.
  ]),

  step(time: "15s", [
    Place the ACS smartcard in the card reader and place the OCS smartcard
    visibly in the stand.

    #set_card_reader(from: none, to: "ACS")
  ]),
)

== Create the Security World and Sign the Software

#steps(
  step(label: <create_world>, time: "2m", [
    Create the HSM Security World, enroll the first HSM in it, and write to the
    ACS smartcard. Enter an empty passphrase when prompted.

    ```sh
    ceremony hsm create-world
    ```

    Identifying bytes of `KNSO` hash (#outpath[`hknso`]):
    #hex_identifying(bytes: 20)

    This command takes about 45 seconds. It writes to the ACS smartcard and
    creates encrypted keys on the computer's filesystem.

    #assert_card("ACS")
    #assert_hsm_mode("initialization")
    #assert_component_loaded("secworld", true)
  ]),

  step(label: <display_hkmsw>, time: "1m", [
    Display information about the Security World:

    ```sh
    ceremony hsm world-info
    ```

    Identifying bytes of `KMSW` Security World key hash
    (#outpath[`World`][`hkm`]):
    #hex_identifying(bytes: 20)

    #assert_component_loaded("secworld", true)
  ]),

  restart_hsm("operational"),

  step(time: "10s", [
    Remove the ACS smartcard from the card reader. Place the OCS smartcard in
    the card reader and place the ACS smartcard visibly in the stand.

    #set_card_reader(from: "ACS", to: "OCS")
  ]),

  step(time: "20s", [
    Write to the OCS smartcard. Enter an empty passphrase when prompted.

    ```sh
    ceremony smartcard write-ocs
    ```

    This command should take about 12 seconds.

    #assert_hsm_mode("operational")
    #assert_card("OCS")

    #assert_component_loaded("secworld", true)
  ]),

  step(time: "10s", [
    Create a signing key:

    ```sh
    ceremony sign create-key
    ```

    This command should take about 6 seconds. It writes an encrypted key to the
    host computer's filesystem.

    #assert_card("OCS")
    #assert_hsm_mode("operational")

    #assert_component_loaded("secworld", true)
  ]),

  step(label: <signing_key_hash>, time: "1m", [
    Display information about the signing key:

    ```sh
    ceremony sign key-info
    ```

    Identifying bytes of signing key hash
    (#outpath[`Key AppName seeinteg Ident jbox-signer`][`hash`]):
    #hex_identifying(bytes: 20)

    #assert_component_loaded("secworld", true)
  ]),

  install_codesafe(),

  step(time: "40s", [
    Build the `entrust_init` tool:

    ```sh
    ceremony build init
    ```

    This command should take about 30 seconds.

    #checkbox[
      The SHA-256 hash of `entrust_init` encoded as a BIP-39 mnemonic matches:
      #bip39_full(bytes: 32, phrase: known_hashes.at("entrust_init_bip39"))
    ]

    #assert_component_loaded("codesafe", true)
    #set_component_loaded("entrust_init", true)
  ]),

  step(time: "40s", [
    Build the HSM software:

    ```sh
    ceremony build hsm
    ```

    This command should take about 30 seconds.

    #checkbox[
      Identifying words of the BIP-39 mnemonic encoding of the SHA-256 hash of
      `entrust_hsm.elf` match:

      #bip39_identifying(
        bytes: 32,
        phrase: known_hashes.at("entrust_hsm_elf_bip39"),
      )

      The full mnemonic is checked in the next step when this software is
      signed.
    ]


    #assert_component_loaded("codesafe", true)
  ]),

  step(time: "1m", [
    Sign the HSM software:

    ```sh
    ceremony sign software
    ```

    This command should take about 2 seconds. It requires the OCS smartcard. It
    reads an ELF-format executable from the host computer's filesystem and
    writes a signed version of that back to the host computer's filesystem.

    #checkbox[
      The SHA-256 hash of the input file (`entrust_hsm.elf`) encoded as a
      BIP-39 mnemonic matches:
      #bip39_full(bytes: 32, phrase: known_hashes.at("entrust_hsm_elf_bip39"))
    ]

    Identifying words of the BIP-39 mnemonic encoding of the SHA-256 hash of
    the signed file (`entrust_hsm.sar`):
    #bip39_identifying(bytes: 32)

    #assert_card("OCS")
    #assert_component_loaded("secworld", true)
  ]),

  step(time: "1m", [
    Sign the HSM userdata:

    ```sh
    ceremony sign userdata
    ```

    This command should take about 1 second. It requires the OCS smartcard. It
    reads the string `dummy` from the host computer's filesystem (the content
    is ignored) and writes a signed version of that back to the host computer's
    filesystem.

    #checkbox[
      The input file (`userdata.dummy`) SHA-256 hash encoded as a BIP-39
      mnemonic matches:

      #bip39_full(
        bytes: 32,
        // ceremony bip39 encode $(echo -n dummy | sha256sum | cut -d' ' -f1)
        phrase: "
          remember bind flat patch
          banana recall possible tourist
          width cycle fringe next
          visa people private ready
          price tree comic glow
          together print annual cash
        ",
      )
    ]

    Identifying words of the BIP-39 mnemonic encoding of the SHA-256 hash of
    the signed file (`userdata.sar`):
    #bip39_identifying(bytes: 32)

    #assert_card("OCS")
    #assert_component_loaded("secworld", true)
    #set_component_loaded("sar_files", true)
  ]),
)

== Destroy the OCS Smartcard

#steps(
  destroy("OCS")
)

== Create the Realm Keys

#steps(
  step(time: "3m", [
    Generate the realm keys:

    ```sh
    ceremony realm create-keys
    ```

    Each key's ACL is the same, except for identifiers, having three permission
    groups:

    - Permission Group 1 allows reading the ACL itself and allows the key to be
      duplicated with the same ACL. It should look like:

      ```
      Action: OpPermissions: DuplicateHandle, GetACL
      ```

    - Permission Group 2 allows HSM software signed with the signing key to
      read the key (and associated data, which is not used). It should look
      like:

      ```
      Requires Cert: hash: ❰SIGNING-KEY-HASH❱ mechanism: Any
      Flags: certmech_present
      Action: OpPermissions: ExportAsPlain, GetAppData
      ```

    - Permission Group 3 allows the key to be saved as a blob on the host
      filesystem, encrypted by the Security World key (`KMSW`), only once. It
      should look like (in two lines, wrapped here):

      ```
      Use Limit: Global: max: 1 id: ❰VARYING-40-HEX-CHARS❱
      Action: MakeBlob: Flags: AllowKmOnly, AllowNonKm0, kmhash_present kmhash: ❰KMSW-HASH❱
      ```


    #checkbox[
      #outpath[`Creating key simple,jbox-mac`...][`Permission Group 2`][`Requires Cert`][`hash`]
      matches the signing key hash in #ref_step(<signing_key_hash>).
    ]
    #checkbox[
      #outpath[`Creating key simple,jbox-mac`...][`Permission Group 3`][`Action`][`kmhash`]
      matches the Security World key hash in #ref_step(<display_hkmsw>).
    ]
    #checkbox[
      #outpath[`Creating key simple,jbox-record`...][`Permission Group 2`][`Requires Cert`][`hash`]
      shows the same value as the `jbox-mac` permissions.
    ]
    #checkbox[
      #outpath[`Creating key simple,jbox-record`...][`Permission Group 3`][`Action`][`kmhash`]
      shows the same value as the `jbox-mac` permissions.
    ]
    #checkbox[
      #outpath[`Creating key simple,jbox-noise`...][`Permission Group 2`][`Requires Cert`][`hash`]
      shows the same value as the `jbox-mac` permissions.
    ]
    #checkbox[
      #outpath[`Creating key simple,jbox-noise`...][`Permission Group 3`][`Action`][`kmhash`]
      shows the same value as the `jbox-mac` permissions.
    ]

    // Note: does not require smartcard.
    #assert_component_loaded("entrust_init", true)
    #set_component_loaded("simple_keys", true)
  ]),

  step(time: "1m", [
    Verify the ACL on each key no longer allows creating a key blob:

    ```sh
    ceremony realm print-acl mac
    ceremony realm print-acl record
    ceremony realm print-acl noise
    ```

    #checkbox[
      `Permission Group 3` is no longer present for the `jbox-mac` key.
    ]
    #checkbox[
      `Permission Group 3` is no longer present for the `jbox-record` key.
    ]
    #checkbox[
      `Permission Group 3` is no longer present for the `jbox-noise` key.
    ]

    // Note: does not require smartcard.
    #assert_component_loaded("entrust_init", true)
    #assert_component_loaded("simple_keys", true)
  ]),

  step(time: "3m", [
    Record the public key that clients will use to authenticate this realm.

    ```sh
    ceremony realm noise-public-key
    ```

    The output `Qx` is the X25519 public key encoded in hex.

    Identifying bytes of Noise public key (#outpath[`Qx`]):
    #hex_identifying(bytes: 32)

    Copy and paste the public key into the next command (using the keyboard
    shortcuts documented in @tmux_reference):

    ```sh
    ceremony bip39 encode ❰Qx❱
    ```

    Noise public key encoded as a BIP-39 mnemonic phrase:
    #bip39_full(bytes: 32)

    #assert_component_loaded("simple_keys", true)
    #assert_component_loaded("secworld", true)
  ]),
)

== Write the #realm_dvd_title

#steps(
  step(label: <create_realm_dvd_iso>, time: "0s", [
    Create the #realm_dvd image:

    ```sh
    ceremony realm-dvd create-iso
    ```

    This command should take less than 1 second. See @state_appendix for
    details on which files are included on the image.

    Identifying bytes of SHA-256 hash of the #realm_dvd image
    (`/root/realm.iso`):
    #hex_identifying(bytes: 32)

    #assert_component_loaded("entrust_init", true)
    #assert_component_loaded("sar_files", true)
    #assert_component_loaded("simple_keys", true)
  ]),

  eject_dvd(),

  step(time: "30s", [
    Inspect the blank DVD packaging.

    #checkbox[The packaging does not appear tampered with.]
  ]),

  step(time: "2m", [
    Take one blank DVD and label it with:
      - "Ceremony #realm_dvd_title",
      - the local date and time, and
      - the identifying bytes of the SHA-256 hash of the ISO file from
        #ref_step(<create_realm_dvd_iso>).

    #checkbox[The DVD does not appear tampered with and appears blank.]

    Place the remaining spindle in a tamper-evident bag.
    #labeled_blank_bag_id
  ]),

  load_dvd(realm_dvd),

  step(time: "4m", [
    Write the image to the DVD:

    ```sh
    ceremony realm-dvd write
    ```

    This command should take about 4 minutes and should eject the DVD when
    completed. Ejecting the DVD is intended to clear any OS or drive caches.

    #checkbox[The computer ejected the DVD.]

    #set_dvd_drive(from: realm_dvd, to: none)
  ]),

  load_dvd(realm_dvd),

  step(time: "1m", [
    Verify the files were written to the #realm_dvd correctly:

    ```sh
    ceremony realm-dvd verify
    ```

    #assert_component_loaded("entrust_init", true)
    #assert_component_loaded("sar_files", true)
    #assert_component_loaded("simple_keys", true)
  ]),

)

== Clear the First HSM

#steps(
  erase_hsm(),

  load_dvd(boot_dvd),

  power_off(),
)

= HSM Enrollment

== Set up the First HSM

#steps(
  boot_into_dvd(),
  install_secworld(),
  restart_hsm("initialization"),
  load_dvd(realm_dvd),
  restore_realm_dvd_files(),
  enroll_hsm_and_init_nvram(),
  load_dvd(boot_dvd),
  power_off(),
  store_hsm(),
)

== Intermission

#steps(
  step(time: "15s", [
    Detach the operator end of the antistatic wrist strap, leaving it connected
    to the computer chassis.

    #set_wrist_strap_connected(false)
  ]),

  step(time: "1m", [
    Remove the ACS smartcard from the stand.

    Wrap the end of the smartcard with masking tape three times over, covering
    the electronics.

    Place the ACS smartcard in a tamper-evident bag.
    #labeled_blank_bag_id
  ]),

  step(time: "1m", [
    Place the card reader in a tamper-evident bag.

    #labeled_blank_bag_id

    #assert_card_reader(none)
    #assert_card_reader_connected(false)
  ]),

  step(time: "30s", [
    _MC:_ Decide on an approximate duration for the break.

    #blanks[Duration][Resume at (time)]
  ]),

  step(time: "1m", [
    Place this document in a tamper-evident bag.

    #labeled_blank_bag_id
  ]),

  step(label: <intermission>, time: "30m", [
    The operator must step away from the station. Then, everyone (all
    participants and anyone else present) should leave the room together.

    *No one may enter the room during the break.*

    After the break, all participants should reenter the room together. Then,
    the operator should return to the station and remove this document from its
    bag.

    #checkbox[The bag does not appear tampered with.]
    #checkbox[The bag ID matches the one recorded above.]
    #checkbox[
      By a show of hands, each of the participants agrees that, to the best of
      their knowledge, no one enter the room during the break.

      #blank[Count]
    ]
  ]),

  step(time: "30s", [
    Remove the card reader from its bag.

    #checkbox[The bag does not appear tampered with.]
    #checkbox[The bag ID matches the one recorded above.]
  ]),

  step(time: "30s", [
    Remove the ACS smartcard from the bag, remove the masking tape from it, and
    place it visibly in the stand.

    #checkbox[The bag does not appear tampered with.]
    #checkbox[The bag ID matches the one recorded above.]
    #checkbox[The smartcard ID matches #ref_step(<acs_id>).]
  ]),

  step(time: "15s", [
    Ground yourself to the unpainted computer chassis with the antistatic wrist
    strap. It can be worn on your upper arm or ankle.

    #set_wrist_strap_connected(true)
  ]),
)

#let ordinals = ("First", "Second", "Third", "Fourth", "Fifth")

#let last_hsm = 4
#for i in range(1, last_hsm + 1) [
  == Set Up the #ordinals.at(i) HSM

  #steps(
    unpack_hsm(),
    boot_into_dvd(),
    initialize_hsm(i),
    load_dvd(realm_dvd),
    restore_realm_dvd_files(),

    if i < last_hsm {(
      enroll_hsm_and_init_nvram(leave_acs_in_reader: false),
      load_dvd(boot_dvd),
      power_off(),
      store_hsm(),
    )} else {(
      // For the last HSM, leave the ACS smartcard in the reader so that it can
      // be wiped. The remaining steps are done after the ACS destruction in
      // the Conclusion.
      enroll_hsm_and_init_nvram(leave_acs_in_reader: true),
    )},

  )
]

= Conclusion

#steps(
  destroy("ACS"),

  eject_dvd(),
  power_off(),
  store_hsm(),

  step(time: "1m", [
    Place the card reader in a tamper-evident bag.

    #labeled_blank_bag_id
  ]),

  step(time: "2m", [
    Put away the computer, keyboard, and other materials. Detach both ends of
    the antistatic wrist strap.

    #set_wrist_strap_connected(false)
  ]),

  step(time: "3m", [
    Close out any unused exception sheets.

    #blank[Exception sheets used]
  ]),

  step(time: "5m", [
    Collect initials from all ceremony participants.

    #radio[All participants initialed][Not all participants initialed]
  ]),

  step(time: "5m", [
    Display each sheet of this document in sequence to be recorded on video.
  ]),
)

The ceremony is now complete.

#assert_card_reader(none)
#assert_card_reader_connected(false)
#assert_computer_on(false)
#assert_computer_plugged_in(false)
#assert_dvd_drive(none)
#assert_hsm_installed(false)
#assert_hsm_mode(none)
#assert_wrist_strap_connected(false)

The operator should digitize and publish this document as soon as possible.
Store the paper copy in a tamper-evident bag.

#labeled_blank_bag_id

#show: appendices

= State <state_appendix>

Other than the computer's factory-provided firmware and Windows installation,
the state entering the ceremony is on the public #boot_dvd (see @boot_dvd) and
the Entrust-confidential #vendor_dvd (see @vendor_dvd).

In @set_up_computer, several files are copied from the DVDs to the NVMe drive,
to avoid delays from reading DVDs repeatedly during the ceremony. These files
are copied into the primary Windows partition (`C:` or `/dev/nvme0n1p3`, an
NTFS filesystem) into `/Users/defaultuser0`:

  + `/live/filesystem.squashfs` from the #boot_dvd,
  + `/entrust.ps1` from the #boot_dvd,
  + `/CODESAFE.ZIP` from the #vendor_dvd,
  + `/FIRMWARE.ZIP` from the #vendor_dvd, and
  + `/SECWORLD.ZIP` from the #vendor_dvd.

Subsequently, when booting the #boot_dvd, the initial ramdisk will attempt to
mount the Windows partition in read-only mode, validate the copy of the
Squashfs filesystem against the SHA-256 hash found on the #boot_dvd, and boot
into that Squashfs filesystem. If the #boot_dvd cannot validate this hash, it
raises an error.

After booting the #boot_dvd, the Windows partition remains mounted (at
`/run/win`). The ceremony tool verifies the hashes of the copies of the
#vendor_dvd files as found on the Windows partition, then uses those copies
instead of reading the #vendor_dvd.

In @realm_creation, several new files are produced that are burned to a blank
#realm_dvd (see @realm_dvd). The #realm_dvd is used during the ceremony and
must be retained to set up the realm's production environment.

The HSMs themselves contain some state initialized during the ceremony. Each
will contain the `KMSW` key to decrypt the encryption keys found on the
#realm_dvd, and each will have an empty file allocated on its NVRAM. After the
ceremony, each HSM's key and NVRAM file are only accessible within the trust
boundary of that HSM.

== #boot_dvd_title <boot_dvd>

The #boot_dvd contains only public content, which can be reviewed and
reproduced at #link("https://github.com/juicebox-systems/ceremony/"). The hash
of the ISO 9660 image burned to the DVD is #raw(block: false, boot_dvd_sha256).
The #boot_dvd includes:

- a bootable Linux OS based on Debian 12 (Bookworm),
- an official Rust/Cargo toolchain (pre-installed in binary form),
- Rust's standard library source code (pre-installed in source form),
- Juicebox "ceremony tool" source code (from
  #link(
    "https://github.com/juicebox-systems/ceremony/tree/" +
    git_commit_hash +
    "/tool"
  ), at `/root/ceremony/tool`),
- Juicebox HSM software and tooling source code (from
  #link(
    "https://github.com/juicebox-systems/juicebox-hsm-realm/tree/" +
    known_hashes.at("juicebox_hsm_realm_git_sha1")
  ), at `/root/juicebox-hsm-realm`),
- source code for Rust dependencies for the above three bullets (at
  `/root/crates`), and
- CodeSafe feature activation files received from Entrust for these particular
  HSMs (at `/root/features`).

Most of the #boot_dvd contents are stored inside a root filesystem in a
Squashfs file (`/live/filesystem.squashfs`), while the boot loader, kernel,
initial ramdisk, and SHA-256 hashes of all files reside outside of this
filesystem. The #boot_dvd writes all filesystem changes to an in-memory
overlay, which is discarded on shutdown.

== #vendor_dvd_title <vendor_dvd>

The #vendor_dvd consists of three files that are distributed by Entrust to
their nShield HSM customers. We have not found a public location listing these
hashes, and we are not authorized to publish these files. See
#link("https://nshielddocs.entrust.com/") and contact
#link("mailto:nshield.support@entrust.com") or
#link("mailto:nshield.docs@entrust.com") for details.

#let vendor_dvd_file(
  path: none,
  vendor_filename: none,
  sha256: none,
  bytes: none,
  description,
) = table(
  columns: 2,
  fill: (col, row) => if col == 0 {
    fill_color
  } else {
    none
  },
  [Path on #vendor_dvd], raw(path, block: false),
  [Entrust filename], raw(vendor_filename, block: false),
  [SHA-256 hash], raw(sha256, block: false),
  [Size], [#raw(bytes) bytes],
  [Description], description,
)

#let vendor_input_hashes = read_sha256sums("../vendor-dvd/sha256sum.inputs.txt")

#vendor_dvd_file(
  path: "/CODESAFE.ZIP",
  vendor_filename: "Codesafe_Lin64-13.4.3.iso.zip",
  sha256: vendor_input_hashes.at("./inputs/Codesafe_Lin64-13.4.3.iso.zip"),
  bytes: "586,472,486",
  [
    Compiler, libraries, and header files used to build source code to run on the
    HSM or interface with the HSM
  ],
)
#vendor_dvd_file(
  path: "/FIRMWARE.ZIP",
  vendor_filename: "nShield_HSM_Firmware-13.4.4.iso.zip",
  sha256: vendor_input_hashes.at("./inputs/nShield_HSM_Firmware-13.4.4.iso.zip"),
  bytes: "1,856,501,013",
  [Signed HSM firmware images],
)
#vendor_dvd_file(
  path: "/SECWORLD.ZIP",
  vendor_filename: "SecWorld_Lin64-13.4.4.iso.zip",
  sha256: vendor_input_hashes.at("./inputs/SecWorld_Lin64-13.4.4.iso.zip"),
  bytes: "678,977,000",
  [Host tools, daemons, and driver to manage HSMs],
)

Note that Linux maps the filenames to lowercase when mounting the #vendor_dvd.

The overall hash of the #vendor_dvd ISO 9660 image is \
#raw(block: false,
  read_sha256sums("../vendor-dvd/sha256sum.output.txt")
    .at("./target/vendor.iso")
).

== #realm_dvd_title <realm_dvd>

These files are copied from the root filesystem overlay to the root directory
of the #realm_dvd:

- Host path: `/opt/nfast/kmdata/local/key_simple_jbox-mac`

  A blob of the symmetric key that Juicebox's HSM code uses for HSM-to-HSM
  authentication, encrypted by `KMSW`.

- Host path: `/opt/nfast/kmdata/local/key_simple_jbox-noise`

  A blob of the asymmetric key used for client-to-HSM communication, encrypted
  by `KMSW`.

- Host path: `/opt/nfast/kmdata/local/key_simple_jbox-record`

  A blob of the symmetric key that Juicebox's HSM code uses to encrypt its
  data, encrypted by `KMSW`.

- Host path: `/opt/nfast/kmdata/local/world`

  Contains key blobs for `KMSW` and `KNSO`, encrypted by key(s) encoded in the
  ACS smartcard(s), as well as other Security World blobs and information.

- Host path: \
  `/root/juicebox-hsm-realm/target/powerpc-unknown-linux-gnu/release/entrust_hsm.sar`

  Juicebox's executable program to run within the HSMs, signed by the signing
  key.

- Host path: \
  `/root/juicebox-hsm-realm/target/powerpc-unknown-linux-gnu/release/userdata.sar`

  The string `dummy`, signed by the signing key. This is required to run
  software on the HSM, but Juicebox's software does not read the contents.

- Host path: `/root/juicebox-hsm-realm/target/release/entrust_init`

  A tool that runs on the host computer to create HSM keys and initialize HSM
  NVRAM with appropriate ACLs. This is included on the #realm_dvd to avoid
  having to compile it repeatedly.

The #realm_dvd is used during the ceremony and must be retained to set up the
realm's production environment. We have chosen not to publish the #realm_dvd
contents because we are not familiar with the exact file formats and
cryptography used in these files.

= HSM Keys

This appendix describes relevant keys created by the HSM. The authoritative
resource for this information is Entrust (see the Security Manual:
#link("https://nshielddocs.entrust.com/security-world-docs/v13.3/security-manual/intro.html")).

The keys are identified by hashes, encoded as 40 hexadecimal characters. These
hashes are labeled using several conventions but are most commonly prefixed
with an `h` (for example, `hknso` for the hash of the `KNSO` key).

#table(
  columns: 2,
  fill: header_fill,

  [*Name*],
  [*Description*],

  [`KLTU`],
  [
    The key that is encoded in the OCS smartcard(s). Its hash is output when
    creating a new OCS.
  ],

  [`KMSW` or `KM_sw`],
  [
    The Security World key that is copied to every HSM in the Security World.
    It is generated when the Security World is created. It encrypts application
    key blobs in the Security World.

    The key is stored within the HSMs that are enrolled in the Security World.
    It is also stored as a blob in `/opt/nfast/kmdata/local/world`, encrypted
    by a key that's encoded in the ACS smartcard(s).

    Although the Security World key is one of multiple "module" keys (`KM`
    keys), the hash of `KMSW` is reported by `/opt/nfast/bin/nfkminfo`
    (`ceremony hsm world-info`) as `hkm` and in the ACLs as `kmhash`.
  ],

  [`KNSO`],
  [
    A key that is created and its hash is output when creating a Security
    World. When other HSMs are enrolled in the Security World, they output the
    same hash.

    The key blob is stored in `/opt/nfast/kmdata/local/world`, encrypted by a
    key that's encoded in the ACS smartcard(s).
  ],

)

= Reference

== NATO Alphabet and Morse Code

The NATO alphabet should be used to spell out alphanumeric strings, except
using normal English number pronunciation.

The HSMs have a blue LED that emits error codes in Morse code. Refer to
#link("https://nshielddocs.entrust.com/1/solo-ug/13.3/morse-code-errors") for
the meaning of the error codes. The dashes should have 3 times the duration of
a dot, and the word gap should be 7 times the duration of a dot.

#let alphabet = (
  ("A", "Alfa",      ".-"),
  ("B", "Bravo",     "-..."),
  ("C", "Charlie",   "-.-."),
  ("D", "Delta",     "-.."),
  ("E", "Echo",      "."),
  ("F", "Foxtrot",   "..-."),
  ("G", "Golf",      "--."),
  ("H", "Hotel",     "...."),
  ("I", "India",     ".."),
  ("J", "Juliett",   ".---"),
  ("K", "Kilo",      "-.-"),
  ("L", "Lima",      ".-.."),
  ("M", "Mike",      "--"),
  ("N", "November",  "-."),
  ("O", "Oscar",     "---"),
  ("P", "Papa",      ".--."),
  ("Q", "Quebec",    "--.-"),
  ("R", "Romeo",     ".-."),
  ("S", "Sierra",    "..."),
  ("T", "Tango",     "-"),
  ("U", "Uniform",   "..-"),
  ("V", "Victor",    "...-"),
  ("W", "Whiskey",   ".--"),
  ("X", "Xray",      "-..-"),
  ("Y", "Yankee",    "-.--"),
  ("Z", "Zulu",      "--.."),
  ("0", "Zero",      "-----"),
  ("1", "One",       ".----"),
  ("2", "Two",       "..---"),
  ("3", "Three",     "...--"),
  ("4", "Four",      "....-"),
  ("5", "Five",      "....."),
  ("6", "Six",       "-...."),
  ("7", "Seven",     "--..."),
  ("8", "Eight",     "---.."),
  ("9", "Nine",      "----."),
)

#let alphabet_table(rows) = table(
  align: (center + horizon, left + horizon, left + horizon),
  columns: 3,
  fill: header_fill,
  [*Letter*], [*Code Word*], [*Morse Code*],
  ..rows.map(((letter, word, morse)) => (
    raw(letter),
    word,
    morse_code(morse),
  )).flatten()
)

#align(center, grid(
  column-gutter: 2em,
  columns: 3,
  alphabet_table(alphabet.slice(0, 18)),
  alphabet_table(alphabet.slice(18)),
))

#pagebreak(weak: true)
== Windows Keyboard Shortcuts

- #keys(("Win", "R")) to open window to launch a program. For example, you can
  then run `powershell`.
- #keys(("Win", "Up")) to maximize the current window.
- #keys(("Win", "Down")) to un-maximize the current window if maximized, or to
  minimize it otherwise.
- #keys(("Alt", "Tab")) to switch windows.
- #keys(("Alt", "F4")) to close the current window.

== tmux Keyboard Shortcuts <tmux_reference>

#let tmux_prefix = ("Ctrl", "a")

The `tmux` terminal multiplexer is used in the #boot_dvd environment, primarily
to provide scrolling and copy-paste. `tmux` is set to `vi` mode and
#keys(tmux_prefix) is the prefix key.

- #keys(tmux_prefix, "?") for online help (and then #keys("q") or
  #keys("Enter") to close the help).
- #keys(tmux_prefix, "[") to enter copy mode.
- #keys(tmux_prefix, "]") to paste.

In copy mode (a scroll indicator will appear on the top-right):
- #keys("Space") to start a visual selection.
- #keys("Enter") to copy the current selection and exit copy mode.
- #keys("Esc") to cancel a selection.
- #keys("q") to exit copy mode.
- Move the cursor with `vi`-like keys or arrows.
- #keys(("Ctrl", "y")) to scroll up by one line and #keys(("Ctrl", "e")) to
  scroll down by one line.
- #keys("PageUp") and #keys("PageDown") to scroll by almost one screen.


#for i in range(1, 6) {
  exception_sheet(i)
}

#if debug_level >= 2 [
  = #debug_text[Component Demo]

  #component_demo
]
