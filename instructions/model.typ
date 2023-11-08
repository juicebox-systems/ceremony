// The model represents the state of the real world as it changes during the
// ceremony.
//
// The variables that are tracked in the model are  useful to catch errors in
// the instructions. Many other things that may seem important are not tracked.
// For example, tracking which HSM is active wouldn't be valuable because the
// HSMs are used sequentially.
//
// Due to Typst's execution model, most of the functions in this module return
// content that must be displayed. Often the content is empty, but it must
// still go into the document. This will happen "by default" in most contexts.
// See https://typst.app/docs/reference/meta/state/#definitions-update for more
// info.

#import "debug.typ": debug_level, debug_text, error


//////// Model Variables and Values

// A state variable tracking which smartcard is in the smartcard reader, if
// any.
#let card_reader = state("card_reader", none)
#let card_reader_values = (none, "ACS", "OCS")

// A boolean state variable tracking whether the smartcard reader is connected
// to the current HSM.
#let card_reader_connected = state("card_reader_connected", false)

// A container of boolean state variables that track whether a particular
// software component or files have been created/installed/loaded.
#let components_loaded = state("components_loaded", (
  // `ceremony vendor install codesafe` is done.
  codesafe: false,
  // The `entrust_init` executable is on the filesystem (either built from
  // source or restored from the realm DVD).
  entrust_init: false,
  // `entrust_hsm.sar` and `userdata.sar` are on the filesystem (either just
  // signed or restored from the realm DVD).
  sar_files: false,
  // `ceremony vendor install secworld` is done.
  secworld: false,
  // The MAC, noise, and record key blobs, along with the 'world' file, are on
  // the filesystem (either just generated or restored from the realm DVD).
  simple_keys: false,
))

// A boolean state variable tracking whether the computer is turned on.
#let computer_on = state("computer_on", false)

// A boolean state variable tracking whether the computer power supply is
// plugged in to power.
#let computer_plugged_in = state("computer_plugged_in", false)

// A state variable tracking which DVD is in the computer's DVD burner, if any.
#let dvd_drive = state("dvd_drive", none)
#let boot_dvd = "boot DVD"
#let boot_dvd_title = "Boot DVD"
#let realm_dvd = "realm DVD"
#let realm_dvd_title = "Realm DVD"
#let vendor_dvd = "vendor DVD"
#let vendor_dvd_title = "Vendor DVD"
#let dvd_drive_values = (none, boot_dvd, realm_dvd, vendor_dvd)

// A boolean state variable tracking whether the current HSM has been inserted
// into the computer's PCIe slot.
#let hsm_installed = state("hsm_installed", false)

// A state variable tracking the operational mode of the HSM. `none` can
// indicate that the HSM is not installed, the computer is off, or the mode is
// unknown.
#let hsm_mode = state("hsm_mode", none)
#let hsm_mode_values = (none, "initialization", "maintenance", "operational")

// A boolean state variable tracking whether the antistatic wrist strap is
// connecting the operator to the computer chassis.
#let wrist_strap_connected = state("wrist_strap_connected", false)


//////// Debug functions

// Returns a dictionary of all model variables, mapping from their names to
// content representing their current values.
#let debug_model() = (
  card_reader: card_reader.display(repr),
  card_reader_connected: card_reader_connected.display(repr),
  computer_on: computer_on.display(repr),
  computer_plugged_in: computer_plugged_in.display(repr),
  components_loaded: components_loaded.display(c => table(
    columns: 2,
    ..c.pairs().map(((component, is_loaded)) =>
      (component, repr(is_loaded))
    ).flatten(),
  )),
  dvd_drive: dvd_drive.display(repr),
  hsm_installed: hsm_installed.display(repr),
  hsm_mode: hsm_mode.display(repr),
  wrist_strap_connected: wrist_strap_connected.display(repr),
)


//////// Helper functions

#let is_boolean(v) = v == false or v == true

// Test for is_boolean.
{
  #assert(is_boolean(true))
  #assert(is_boolean(false))
  #assert(not is_boolean(1))
  #assert(not is_boolean(0))
  #assert(not is_boolean(none))
  #assert(not is_boolean("true"))
}

// Returns the name of a state variable. This is a convenient hack used for
// better debug messages.
#let state_key(state_var) = {
  assert(type(state_var) == state, message: repr(state_var))
  repr(state_var).match(regex("^state\(\"(.+)\",")).captures.at(0)
}

// Test for `state_key`.
#assert(
  state_key(card_reader) == "card_reader",
  message: "got " + repr(state_key(card_reader)),
)

// Helper for `require_*` functions.
#let join_messages(..messages) = {
  let nonempty = messages.pos()
    .filter((m) => m != none and m != "")
  if nonempty == () {
    ""
  } else {
    nonempty.join(": ")
  }
}

// Test for `join_messages`.
#for (input, expected) in (
  ((), ""),
  (("", none), ""),
  ((none, "a", ""), "a"),
  (("a", none, "", "b"), "a: b"),
) {
  let actual = join_messages(..input)
  assert(
    actual == expected,
    message: "expected " + repr(expected) + " but got " + repr(actual),
  )
}

// Asserts that a state variable has the given value.
#let require_eq(state, required, message: none) = {
  if debug_level >= 2 {
    block(debug_text[
      Requires #state_key(state) is #repr(required).
    ])
  }

  state.display((actual) => {
    if actual != required {
      error(join_messages(
        message,
        (
          state_key(state) +
          " must be " +
          repr(required) +
          " but found " +
          repr(actual)
        ),
      ))
    }
  })
}

// Asserts that a dictionary state variable has a given key set to the given
// value.
#let require_key_eq(state, key, value, message: none) = {
  assert(is_boolean(value))

  if debug_level >= 2 {
    block(debug_text[
      Requires #state_key(state) has #repr(key) set to #repr(value).
    ])
  }

  state.display((actual) => {
    if actual.at(key) != value {
      error(join_messages(
        message,
        state_key(state) + " must have " + repr(key) + " set to " + repr(value)
      ))
    }
  })
}


//////// State assertion functions

#let assert_card_reader(card, message: none) = {
  require_eq(card_reader, card, message: message)
}

#let assert_card_reader_connected(value, message: none) = {
  require_eq(card_reader_connected, value, message: message)
}

#let assert_component_loaded(component, is_loaded, message: none) = {
  require_key_eq(components_loaded, component, is_loaded, message: message)
}

#let assert_computer_on(value, message: none) = {
  require_eq(computer_on, value, message: message)
}

#let assert_computer_plugged_in(value, message: none) = {
  require_eq(computer_plugged_in, value, message: message)
}

#let assert_dvd_drive(disc, message: none) = {
  require_eq(dvd_drive, disc, message: message)
}

#let assert_hsm_installed(value, message: none) = {
  require_eq(hsm_installed, value, message: message)
}

#let assert_hsm_mode(mode, message: none) = {
  require_eq(hsm_mode, mode, message: message)
}

#let assert_wrist_strap_connected(value, message: none) = {
  require_eq(wrist_strap_connected, value, message: message)
}

// Requires that `card` is in the smartcard reader and the smartcard reader is
// connected to the HSM. `card` must not be none.
#let assert_card(card, message: none) = {
  assert(card != none)
  assert_card_reader(card, message: message)
  assert_card_reader_connected(
    true,
    message: "card reader must be connected to access " + card
  )
}


//////// State manipulation functions

#let set_card_reader(from: -1, to: -1) = {
  assert_card_reader(from)
  assert(
    card_reader_values.contains(to),
    message: "set_card_reader: to is invalid smartcard/none",
  )
  assert(
    from != to,
    message: "set_card_reader: no change",
  )
  card_reader.update(to)
}

#let set_card_reader_connected(value) = {
  assert(
    is_boolean(value),
    message: "invalid card_reader_connected value",
  )
  assert_card_reader_connected(not value)

  // Since the PCI bracket isn't on the HSM, there's a good chance that
  // plugging/unplugging the card reader would knock the HSM out of the PCI
  // slot. That might be bad for the HSM or set off tamper alarms.
  assert_computer_plugged_in(
    false,
    message: (
      "power must be off when plugging in card reader, since it may knock " +
      "the HSM out of the PCI slot"
    ),
  )

  card_reader_connected.update(value)
}

#let clear_all_components_loaded() = {
  components_loaded.update((old) => {
    for component in old.keys() {
      old.insert(component, false)
      old
    }
  })
}

#let set_component_loaded(component, is_loaded) = {
  assert(is_boolean(is_loaded))
  assert_component_loaded(component, not is_loaded)
  assert_computer_on(
    true,
    message: "computer must be on to (un)load components",
  )
  components_loaded.update((old) => {
    old.insert(component, is_loaded)
    old
  })
}

#let set_computer_on(value) = {
  assert(
    is_boolean(value),
    message: "invalid computer_on value"
  )
  assert_computer_on(not value)
  if value {
    assert_computer_plugged_in(
      true,
      message: "computer must be plugged in to power on",
    )
    hsm_installed.display(installed => if installed {
      // The HSM boots back up into operational mode because that's what the
      // hardware switch is set to.
      hsm_mode.update("operational")
    })
  } else {
    hsm_installed.display(installed => if installed {
      // The HSM boots back up into operational mode because that's what the
      // hardware switch is set to.
      hsm_mode.update("none")
    })
  }
  clear_all_components_loaded()
  computer_on.update(value)
}

#let set_computer_plugged_in(value) = {
  assert(
    is_boolean(value),
    message: "invalid computer_plugged_in value"
  )
  assert_computer_plugged_in(not value)

  // This computer seems to power on when plugged in if it was powered on when
  // last unplugged. The ceremony instructions always power off the computer
  // before unplugging it.
  assert_computer_on(
    false,
    message: "computer must be off when unplugging or plugging in power",
  )

  computer_plugged_in.update(value)
}

#let set_dvd_drive(from: -1, to: -1) = {
  assert_dvd_drive(from)
  assert(
    dvd_drive_values.contains(to),
    message: "set_dvd_drive: to is invalid disc/none",
  )
  assert(
    from != to,
    message: "set_dvd_drive: no change",
  )
  assert_computer_on(
    true,
    message: "computer must be on to eject DVD tray",
  )
  dvd_drive.update(to)
}

#let set_hsm_installed(value) = {
  assert(
    is_boolean(value),
    message: "invalid hsm_installed value"
  )
  assert_hsm_installed(not value)
  assert_computer_plugged_in(
    false,
    message: "power must be disconnected to (un)install HSM " +
      "(the computer doesn't have a power switch)",
  )
  assert_wrist_strap_connected(
    true,
    message: "wrist strap needed to (un)install HSM"
  )
  assert_card_reader_connected(
    false,
    message: "card reader must be unplugged to (un)install HSM"
  )
  hsm_mode.update(none)
  hsm_installed.update(value)
}

#let set_hsm_mode(mode) = {
  assert(
    hsm_mode_values.contains(mode),
    message: "invalid HSM mode/none",
  )
  assert_computer_on(
    true,
    message: "computer must be on to set HSM mode",
  )
  assert_hsm_installed(
    true,
    message: "HSM must be installed to set HSM mode",
  )
  assert_component_loaded(
    "secworld",
    true,
    message: "secworld must be loaded to set HSM mode"
  )
  hsm_mode.update(mode)
}

#let set_wrist_strap_connected(value) = {
  assert(
    is_boolean(value),
    message: "invalid wrist_strap_connected value",
  )
  assert_wrist_strap_connected(not value)
  wrist_strap_connected.update(value)
}
