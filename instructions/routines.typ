// This module contains a bunch of reusable steps for `ceremony.typ`.

#import "debug.typ": debug_level, debug_text

#import "model.typ": /*
  */ assert_card, /*
  */ assert_card_reader, /*
  */ assert_component_loaded, /*
  */ assert_dvd_drive, /*
  */ assert_hsm_mode, /*
  */ boot_dvd, /*
  */ dvd_drive, /*
  */ realm_dvd, /*
  */ set_card_reader, /*
  */ set_card_reader_connected, /*
  */ set_component_loaded, /*
  */ set_computer_on, /*
  */ set_computer_plugged_in, /*
  */ set_dvd_drive, /*
  */ set_hsm_installed, /*
  */ set_hsm_mode /*
  */

#import "presentation.typ": /*
  */ blank, /*
  */ blank_entrust_esn, /*
  */ blank_entrust_serial_long, /*
  */ blanks, /*
  */ checkbox, /*
  */ keys, /*
  */ labeled_blank_bag_id, /*
  */ morse_code, /*
  */ outpath, /*
  */ radio, /*
  */ ref_step, /*
  */ step, /*
  */ todo /*
  */

#let boot_into_windows() = step(time: "1m50s", [
  Boot into Windows:

  - Plug the power cord into the back of the computer.
  - Press the "power button" on the front of the computer.
  - Boot the computer into the pre-installed Windows OS.

  #set_computer_plugged_in(true)
  #set_computer_on(true)
  #assert_dvd_drive(
    none,
    message: boot_dvd + " can't be in the drive",
  )
])

#let boot_into_dvd(uefi_setup: false) = {
  let start = (
    [
      Plug the power cord into the back of the computer.

      #set_computer_plugged_in(true)
    ],
    [
      Press the "power button" on the front of the computer.

      #set_computer_on(true)
    ],
  )

  let end = (
    [
      The computer should boot into the bootloader on the #boot_dvd.
    ],
    [
      Press #keys("Enter") at the GRUB menu to boot into Linux.

      #assert_dvd_drive(boot_dvd)
    ],
  )

  if uefi_setup {(
    step(time: "30s", [
      Determine the current date and 24-hour time in UTC. This will be used to
      set the system time.

      #radio(
        [Pacific Standard Time (UTC−08:00)],
        [Pacific Daylight Time (UTC−07:00)],
      )
      #blanks(
        [Local Date (`MM/DD/YYYY`)],
        [Local Time (`HH:MM`, from analog clock)],
        [UTC Date (`MM/DD/YYYY`)],
        [UTC Time (`HH:MM`)]
      )
    ]),

    step(time: "3m40s", [
      Configure UEFI and boot into the #boot_dvd:

      #enum(
        ..start,
        [
          Tap #keys("F1") repeatedly during boot to enter the UEFI setup.
        ],
        [
          Press #keys("Enter") to dismiss the help dialog.
        ],

        // Time & Date
        [
          Press #keys("Right") to enter the #outpath[`Main`] settings.
        ],
        [
          Press #keys("Down"), then #keys("Enter") to enter the
          #outpath[`Main`][`System Time & Date`] settings.
        ],
        [
          Set the time and date to UTC. Use the arrows and #keys("Enter") to
          navigate, and #keys("+") and #keys("-") to adjust the time. Use the
          time and date calculated in the previous step, adjusted for the
          minutes that have since passed.
        ],
        [
          Press #keys("Up") repeatedly until highlighting the back arrow, then
          #keys("Enter"), then #keys("Left") to return to the main menu.
        ],

        // Secure Boot
        [
          Press #keys("Down") several times, then #keys("Right") to enter the
          #outpath[`Security`] settings.
        ],
        [
          Press #keys("Down") several times, then #keys("Enter") to enter the
          #outpath[`Security`][`Secure Boot`] settings.
        ],
        [
          Press #keys("Enter"), then #keys("Up"), then #keys("Enter") to
          disable Secure Boot. (The Linux kernel would refuse to load the
          vendor's HSM driver with Secure Boot enabled.)
        ],
        [
          Press #keys("Up"), then #keys("Enter"), then #keys("Left") to return
          to the main menu.
        ],

        // Boot Priority
        [
          Press #keys("Down"), then #keys("Right") to enter #outpath[`Startup`]
          settings.
        ],
        [
          Press #keys("Enter") to enter the
          #outpath[`Startup`][`Boot Priority Order`] settings.
        ],
        [
          Except for the SATA DVD-RW drive, press #keys("x") on each device to
          exclude it from the boot order. (Skip the DVD-RW drive with
          #keys("Down"). You can also un-exclude something with #keys("x").)
        ],

        [
          Press #keys("F10"), then #keys("Enter") to save the changes and
          reboot.
        ],
        ..end
      )
    ]),
  )} else {
    step(time: "40s", [
      Boot into the #boot_dvd:

      #list(
        ..start,
        ..end,
      )
    ])
  }
}

#let power_off(os: "linux") = step(time: "20s", [
  Power off the computer:

  #if os == "linux" [
    - ```sh
      ceremony computer shutdown
      ```
  ] else if os == "windows" [
    - Press and release the "power button" on the front of the computer.
  ] else {
    panic("unrecognized os")
  }
  - Wait for the computer to turn off.
  - Unplug the power cord from the back of the computer.
  - Wait a few seconds.

  #set_computer_on(false)
  #set_computer_plugged_in(false)
])

#let eject_dvd() = step(time: "10s", [
  #dvd_drive.display(previous => [
    Eject the #previous by pressing the button and remove it from the DVD
    drive.

    #set_dvd_drive(from: previous, to: none)
  ])
])

#let load_dvd(next) = step(time: "10s", [
  #assert(next != none)
  #dvd_drive.display(previous => [
    #if previous == none [
      Insert the #next into the DVD drive.
    ] else [
      Eject the #previous by pressing the button and insert the #next into the
      DVD drive.
    ]

    #set_dvd_drive(from: previous, to: next)
  ])
])

#let unpack_hsm(first: false) = {
  // HSM factory packaging notes (based on loaner):
  // - Outermost box was brown cardboard. (For the newer HSMs, they've shipped
  //   multiple in one outer box.)
  // - Inside that, packing list included "Item: NC4035E-B" and "Serial Numbers:
  //   46-X19142".
  // - Then there's a clear plastic bag with a sticker that says the date,
  //   customer, PO and order numbers and a second "WIP Completion / Picking
  //   Label" with "Serial Nbr: 46X19142".
  // - Inside that, there's a white NCipher-branded plastic bag that's somewhat
  //   tamper-evident.
  // - Inside that, there's a white box with an Entrust nShield-branded sleeve.
  //   On the end is a label that includes a checkbox for "nC4035E-000", a
  //   checkbox for "Base" (vs "Mid" or "High"), a serial number "46-X19142 A".
  // - Inside that is an Installation Guide, the module (which came with the
  //   half-height plate attached) in an antistatic bag, and a white box.
  // - Inside the white box is a card reader, wrapped in clear plastic.
  // - On the side of the module there's a white sticker that says "S/N:
  //   46-X19142 A" and "Model: nC4035E-000"
  // - On the end of the module there's a "REV" label with "06" written in
  //   marker.

  let smoosh = v(-0.4em) // layout hack
  let open_shipping_box = [
    Inspect the outer shipping box:

    #smoosh
    #checkbox[The box does not appear tampered with.]
    #smoosh

    Open the outer shipping box, remove its contents, and put away the box
    and any extra padding.
  ]

  let factory_checks = [
    Inspect the white plastic bag containing this HSM:

    #checkbox[
      The text says "NCIPHER: AN ENTRUST DATACARD COMPANY", with the first "N"
      enclosed in a circle.
    ]
    #smoosh
    #checkbox[The bag is sealed and does not appear tampered with.]

    Use scissors to open the end of the bag at the dashed line. Remove the bag
    and put it away. Inspect the box sleeve:

    #checkbox[
      The text says "ENTRUST: SECURING A WORLD IN MOTION" with the hexagonal
      "E" logo and "nShield: Hardware Security Modules".
    ]
    #smoosh
    #checkbox[The box sleeve does not appear tampered with.]

    Remove the box sleeve and put it away. Inspect the box:

    #checkbox[The box does not appear tampered with.]

    Inspect the sticker at the end of the box:

    #checkbox[The top text says "ENTRUST: nShield Solo XC".]
    #smoosh
    #checkbox[Only the `nC4035E-000 nShield Solo XC F3` model is checked.]
    #smoosh
    #checkbox[Only the `Base` speed is checked.]
    #smoosh
    #checkbox[The serial number matches an unused HSM listed in @materials.]
  ]

  (
    if first {(
      step(time: "2m", [
        This step will process the HSM packaging.

        #checkbox[The HSM is in factory packaging.]

        #open_shipping_box
        #factory_checks

        Serial number: #blank_entrust_serial_long
      ]),
    )} else {(
      step(time: "1m", [
        #radio(
          [
            *The HSM is in factory packaging.*

            #radio(
              [The outer shipping box was opened earlier in the ceremony.],
              [
                The outer shipping box was not opened earlier in the ceremony.
                #open_shipping_box
              ],
            )

            #factory_checks
          ],
          [
            *The HSM is in a tamper-evident bag.*

            #checkbox[The bag does not appear tampered with.]
            #smoosh
            #checkbox[
              The serial number and bag ID match an unused HSM listed in
              @materials.
            ]
          ]
        )

        Serial number: #blank_entrust_serial_long
      ]),
    )},

    step(time: "1m", [
      Unpack and inspect the HSM. Put away its packaging.

      #checkbox[The HSM does not appear tampered with.]

      Inspect the sticker on the side of the HSM:

      #checkbox[
        The serial number (#outpath[`S/N`]) matches that of the previous step.
      ]
      #checkbox[The model is `nC4035E-000`.]
    ]),

    step(time: "10s", [
      Set the mode switch and jumpers on the HSM:

      #checkbox[
        Set the outside-facing physical switch to `O` (the middle position).
      ]
      #checkbox[
        Ensure both override jumper switches are set to off.
      ]
    ]),

    step(time: "1m30s", [
      #if first [
        Note: To fit different computer cases, the HSM may have a low-profile
        PCI bracket or a full-height PCI bracket attached. Due to a
        misalignment, the HSM is physically unable to fit into this particular
        computer when it has either bracket attached, so it will be used
        without a bracket.
      ]

      #radio(
        [
          The HSM currently has no PCI bracket.
        ],
        [
          The HSM currently has a low-profile or full-height PCI bracket.

          Remove the two screws holding the bracket from the HSM, then remove
          the bracket. Put away the bracket and the screws.
        ]
      )
    ]),

    step(time: "1m", [
      Insert the HSM (without an attached bracket) into the PCIe x16 slot in
      the computer.

      #set_hsm_installed(true)
    ]),

    if first {
        step(time: "1m", [
          Unpack the card reader. Put away the packaging.

          #checkbox[
            The card reader is etched with "ENTRUST" text and the hexagonal "E"
            logo.
          ]
          #checkbox[
            The card reader does not appear tampered with.
          ]
        ])
    } else {
      step(time: "1m", [
        #radio(
          [
            This HSM did not come with a card reader.
          ],
          [
            This HSM came with a card reader.

            Place the new card reader in a tamper-evident bag for storage.

            #labeled_blank_bag_id
          ]
        )
      ])
    },

    step(time: "15s", [
      #if first [
        While bracing the HSM, plug the card reader into the HSM's external
        port.
      ] else [
        While bracing the HSM, plug the existing card reader into the HSM's
        external port.
      ]

      #assert_card_reader(none)
      #set_card_reader_connected(true)
    ]),
  )
}

// The body of the `restart_hsm()` step. This is also used as a bullet point
// when activating the codesafe feature.
#let _restart_hsm_inner(mode) = [
  Restart the HSM in #mode mode:

  #if mode == "initialization" [
    ```sh
    ceremony hsm restart --mode initialization
    ```
  ] else if mode == "maintenance" [
    ```sh
    ceremony hsm restart --mode maintenance
    ```
  ] else if mode == "operational" [
    ```sh
    ceremony hsm restart
    ```
  ] else [
    #panic("unsupported HSM mode")
  ]

  This command should take about 55 seconds.
  #set_hsm_mode(mode)
]

#let restart_hsm(mode) = step(time: "55s", _restart_hsm_inner(mode))

#let erase_hsm() = (
  restart_hsm("initialization"),

  step(time: "30s", [
    Initialize the HSM with a new module key:

    ```sh
    ceremony hsm erase
    ```

    #checkbox[
      The output includes the line `Initialising Unit 1 (SetNSOPerms)`.
    ]
    #checkbox[
      #outpath[`Module Key Info`][`HKM[0] is`] shows 20 random-looking bytes in
      hex.
    ]

    This command should take less than 1 second. This key is temporary, as
    creating or joining a Security World later will generate a new module key.

    #assert_hsm_mode("initialization")
    #assert_component_loaded("secworld", true)
  ])
)

#let install_secworld() = step(time: "1m20s", [
  Install Entrust's tools, daemons, and driver:

  ```sh
  ceremony vendor install secworld
  ```

  This command takes about 80 seconds.

  #set_component_loaded("secworld", true)
])

#let install_codesafe() = step(time: "10s", [
  Install Entrust's compiler, libraries, and header files:

  ```sh
  ceremony vendor install codesafe
  ```

  This command should take about 10 seconds.

  #set_component_loaded("codesafe", true)
])

#let restore_realm_dvd_files() = step(time: "30s", [
  Copy the files from the #realm_dvd:

  ```sh
  ceremony realm-dvd restore
  ```

  #assert_dvd_drive(realm_dvd)
  #set_component_loaded("entrust_init", true)
  #set_component_loaded("sar_files", true)
  #set_component_loaded("simple_keys", true)
])

#let initialize_hsm(i) = {
  let esn_step = label("hsm_" + str(i) + "_esn")

  let activate_codesafe() = [
    Activate the SEE (CodeSafe) feature on the HSM:

    - ```sh
      ceremony feature activate features/SEEUE_❰ESN❱.txt
      ```

      // Note: This command doesn't work immediately after a firmware flash,
      // until a KNSO is generated.

      This command takes about 55 seconds. It has a side effect of leaving the
      HSM in operational mode.

      // Features can probably be enabled from other modes, but we happen to
      // always run it in initialization mode.
      #assert_hsm_mode("initialization")

      #assert_component_loaded("secworld", true)
      #set_hsm_mode("operational")

    - #_restart_hsm_inner("initialization")

    - ```sh
      ceremony feature info
      ```

      #checkbox[`SEE Activation (EU+10)` is activated (shows `Y`).]
      #assert_component_loaded("secworld", true)
  ]

  (
    install_secworld(),

    step(time: "1m40s", label: esn_step, [
      Print HSM info:

      ```sh
      ceremony hsm info
      ```

      ESN (#outpath[`Module #1`][`serial number`]):
      #blank_entrust_esn

      #checkbox[The ESN matches the HSM listed in @materials.]

      #blank[Firmware version (#outpath[`Module #1`][`version`])]
      #checkbox[
        #outpath[`Module #1`][`product name`] shows all of
        `nC3025E/nC4035E/nC4335N`.
      ]

      #assert_component_loaded("secworld", true)
    ]),

    restart_hsm("maintenance"),

    step(time: "3m", [
      Update/overwrite the HSM firmware to version 13.3.1:

      ```sh
      ceremony vendor mount firmware
      ceremony firmware write
      ceremony vendor unmount firmware
      ```

      These commands should take about 3 minutes if starting from the same
      version and may take several more minutes if starting from an earlier
      version.

      #assert_hsm_mode("maintenance")
      #assert_component_loaded("secworld", true)
    ]),

    step(time: "30s", [
      Wait until the HSM is done:

      ```sh
      ceremony hsm info
      ```

      #checkbox[
        #outpath[`Module #1`][`enquiry reply flags`] shows `none` (not
        `Offline`).
      ]
      #checkbox[
        #outpath[`Module #1`][`hardware status`] shows `OK`.
      ]
      #checkbox[
        The HSM LED is blinking in the repeated #morse_code("--") pattern.
      ]

      Wait and re-run the command until these conditions are satisfied.

      #assert_component_loaded("secworld", true)
    ]),

    power_off(),

    boot_into_dvd(),

    install_secworld(),

    step(time: "30s", [
      Wait until the HSM is ready:

      ```sh
      ceremony hsm info
      ```

      #checkbox[
        #outpath[`Module #1`][`enquiry reply flags`] shows `none` (not
        `Offline`).
      ]
      #checkbox[
        #outpath[`Module #1`][`mode`] shows `uninitialized`.
      ]
      #checkbox[
        #outpath[`Module #1`][`serial number`] matches #ref_step(esn_step).
      ]
      #checkbox[
        #outpath[`Module #1`][`version`] shows `13.3.1`.
      ]
      #checkbox[
        #outpath[`Module #1`][`hardware status`] shows `OK`.
      ]
      #checkbox[
        The HSM LED is blinking in the repeated #morse_code("-.-") pattern.
      ]

      Wait and re-run the command until these conditions are satisfied.

      If the module does not appear at all, check `dmesg` for the error
      `nfp_open: device ❰...❱ failed to open with error: -5`. Powering the
      computer off and on should resolve this. While this problem is somewhat
      anticipated, use an _exception sheet_ the first time it occurs.

      #assert_component_loaded("secworld", true)
    ]),

    erase_hsm(),

    step(time: "2m", [
      #assert_component_loaded("secworld", true)

      Check which features have been activated on the HSM:

      ```sh
      ceremony feature info
      ```

      #blank[Active features (excluding SEE)]

      #if i == 0 [
        #checkbox[`SEE Activation (EU+10)` is not activated (shows `N`).]
      ] else [
        #radio(
          [
            `SEE Activation (EU+10)` is already activated (shows `Y`).
          ],
          [
            `SEE Activation (EU+10)` is not activated (shows `N`).

            #activate_codesafe()
          ],
        )
      ]
    ]),

    if i == 0 {
      step(time: "0s", activate_codesafe())
    } else {
      ()
    }
  )
}

#let destroy(card) = (
  step(time: "30s", [
    Erase the #card smartcard:

    ```sh
    ceremony smartcard erase
    ```

    This command takes about 30 seconds.

    #assert_card(card)
    #assert_component_loaded("secworld", true)
  ]),

  step(time: "2m", [
    Remove the #card smartcard from the card reader and physically destroy it.
    Use a rotary tool to grind the smartcard electronics into a powder. Use
    scissors to shred the remaining plastic.

    #set_card_reader(from: card, to: none)
  ]),
)

#let enroll_hsm_and_init_nvram(leave_acs_in_reader: false) = (
  step(time: "0s", [
    Place the ACS smartcard in the card reader.

    #set_card_reader(from: none, to: "ACS")
  ]),

  step(time: "50s", [
    Enroll the HSM in the Security World:

    ```sh
    ceremony hsm join-world
    ```

    This command takes about 22 seconds and reads from the ACS smartcard.

    #checkbox[
      The output `hknso` matches the one recorded in
      #ref_step(<create_world>).
    ]

    #assert_card("ACS")
    #assert_hsm_mode("initialization")
    #assert_component_loaded("secworld", true)
    #assert_component_loaded("simple_keys", true)
  ]),

  restart_hsm("operational"),

  step(time: "40s", [
    Print the signing key hash from the ACL of a key:

    ```sh
    ceremony realm print-acl noise
    ```

    #checkbox[
      #outpath[`key simple,jbox-noise exists`...][`Permission Group 2`][`Requires Cert`][`hash`]
      matches the signing key hash in #ref_step(<signing_key_hash>).
    ]

    #assert_component_loaded("entrust_init", true)
    #assert_component_loaded("simple_keys", true)
    #assert_component_loaded("secworld", true) // probably
  ]),

  step(time: "50s", [
    Initialize this HSM's NVRAM file, providing the same signing key hash as
    the previous step for its ACL:

    ```sh
    ceremony realm create-nvram-file --signing-key-hash ❰HASH❱
    ```

    #checkbox[
      #outpath[`Permission Group 2`][`Requires Cert`][`hash`]
      matches the signing key hash in #ref_step(<signing_key_hash>).
    ]

    This command takes about 1 second and reads from the ACS smartcard.

    #assert_card("ACS")
    #assert_hsm_mode("operational")

    #assert_component_loaded("entrust_init", true)
    #assert_component_loaded("secworld", true)
  ]),

  if leave_acs_in_reader {
    ()
  } else {
    step(time: "30s", [
      Remove the ACS smartcard from the card reader and place it visibly in the
      stand.

      #set_card_reader(from: "ACS", to: none)
    ])
  }
)

#let store_hsm() = (
  step(time: "0s", [
    Unplug the card reader from the HSM.

    #assert_card_reader(none)
    #set_card_reader_connected(false)
  ]),

  step(time: "2m", [
    Remove the HSM from the computer and insert it into a tamper-evident bag
    (for transport to the production environment).

    #labeled_blank_bag_id

    #set_hsm_installed(false)
  ]),
)
