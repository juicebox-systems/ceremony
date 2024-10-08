_This file is automatically generated._

# ceremony

```
This tool is used during HSM key ceremonies to run pre-determined commands.

Usage: ceremony [OPTIONS] <COMMAND>

Commands:
  bip39      Convert to and from BIP-39 mnemonic phrase format
  build      Compile HSM-related programs from source
  computer   Manage the host computer
  feature    Manage optional HSM capabilities
  firmware   Manage HSM firmware
  hsm        Manage the core aspects of the HSM
  meta       Commands about this ceremony tool
  realm      Commands for Juicebox-specific HSM and realm initialization
  realm-dvd  Create or verify a "Realm DVD" containing encrypted keys and signed HSM software
  sign       Manage signing keys and sign HSM software and userdata
  smartcard  Manage HSM smartcards (which can contain sensitive keys)
  vendor     Load vendor-supplied software and artifacts
  help       Print this message or the help of the given subcommand(s)

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

## ceremony bip39

```
Convert to and from BIP-39 mnemonic phrase format.

BIP-39 mnemonic phrases encode 128 to 256 bits of data and include a checksum in the final word. See <https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki> for details. This program uses the standard English wordlist.

Usage: ceremony bip39 [OPTIONS] <COMMAND>

Commands:
  decode  Print the hex data encoded in a BIP-39 mnemonic phrase
  encode  Encode data as a BIP-39 mnemonic phrase
  help    Print this message or the help of the given subcommand(s)

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony bip39 decode

```
Print the hex data encoded in a BIP-39 mnemonic phrase.

The 12-24 word mnemonic should be given or typed as stdin and may span multiple lines.

Usage: ceremony bip39 decode [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony bip39 encode

```
Encode data as a BIP-39 mnemonic phrase

Usage: ceremony bip39 encode [OPTIONS] <HEX>

Arguments:
  <HEX>  32-64 hex characters of input data

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

## ceremony build

```
Compile HSM-related programs from source

Usage: ceremony build [OPTIONS] <TARGETS>...

Arguments:
  <TARGETS>...
          What to build

          Possible values:
          - init: The `entrust_init` program, which runs on the host computer to create HSM keys and initialize HSM NVRAM with appropriate ACLs
          - hsm:  The `entrust_hsm.elf` HSM program which must be signed, and the signed archive can be executed on the HSM

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

## ceremony computer

```
Manage the host computer

Usage: ceremony computer [OPTIONS] <COMMAND>

Commands:
  shutdown  Shut down the host computer gracefully
  help      Print this message or the help of the given subcommand(s)

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

### ceremony computer shutdown

```
Shut down the host computer gracefully

Usage: ceremony computer shutdown [OPTIONS]

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

## ceremony feature

```
Manage optional HSM capabilities.

Features can be enabled with a certificate from Entrust. This tool supports enabling features using certificates in plain files (but certificates can also be delivered on smartcards). Most features are static: once enabled they cannot be disabled, even by erasing the HSM.

Usage: ceremony feature [OPTIONS] <COMMAND>

Commands:
  activate  Enable an HSM feature
  info      Print which features have been activated on this HSM
  help      Print this message or the help of the given subcommand(s)

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony feature activate

```
Enable an HSM feature.

WARNING: Most features are static: once enabled they cannot be disabled, even by erasing the HSM.

Usage: ceremony feature activate [OPTIONS] <FILE>

Arguments:
  <FILE>
          An ASCII certificate file signed from Entrust for this particular HSM

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony feature info

```
Print which features have been activated on this HSM

Usage: ceremony feature info [OPTIONS]

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

## ceremony firmware

```
Manage HSM firmware

Usage: ceremony firmware [OPTIONS] <COMMAND>

Commands:
  file-info  Print information about an HSM firmware file
  write      Update the firmware on the HSM
  help       Print this message or the help of the given subcommand(s)

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

### ceremony firmware file-info

```
Print information about an HSM firmware file

Usage: ceremony firmware file-info [OPTIONS] [FILE]

Arguments:
  [FILE]  A binary NFF file for this particular HSM model [default: /run/ceremony/nShield_HSM_Firmware-13.4.4/firmware/SoloXC/latest/soloxc-13-3-1-vsn37.nff]

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

### ceremony firmware write

```
Update the firmware on the HSM.

The HSM must be in maintenance mode.

Usage: ceremony firmware write [OPTIONS] [FILE]

Arguments:
  [FILE]
          A binary NFF file for this particular HSM model
          
          [default: /run/ceremony/nShield_HSM_Firmware-13.4.4/firmware/SoloXC/latest/soloxc-13-3-1-vsn37.nff]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

## ceremony hsm

```
Manage the core aspects of the HSM

Usage: ceremony hsm [OPTIONS] <COMMAND>

Commands:
  create-world  Create a new Security World and enroll the HSM into it
  erase         Reinitialize the HSM state, generating a new module key
  info          Print status information about the hardserver and the HSM
  join-world    Enroll the HSM into an existing Security World
  restart       Restart the HSM, optionally switching to a different mode
  world-info    Print information about the HSM's current Security World
  help          Print this message or the help of the given subcommand(s)

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

### ceremony hsm create-world

```
Create a new Security World and enroll the HSM into it.

The HSM must be in initialization mode. This erases the HSM and writes to a single ACS smartcard.

Usage: ceremony hsm create-world [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony hsm erase

```
Reinitialize the HSM state, generating a new module key.

The HSM must be in initialization mode.

Usage: ceremony hsm erase [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony hsm info

```
Print status information about the hardserver and the HSM.

The hardserver is a host daemon that manages communication with the HSM.

Usage: ceremony hsm info [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony hsm join-world

```
Enroll the HSM into an existing Security World.

The HSM must be in initialization mode. This erases the HSM and requires the ACS smartcard.

Usage: ceremony hsm join-world [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony hsm restart

```
Restart the HSM, optionally switching to a different mode.

Note: The switch and jumpers on the HSM may be configured to restrict changing the mode in software.

Usage: ceremony hsm restart [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

      --mode <MODE>
          HSM boot mode
          
          [default: operational]

          Possible values:
          - initialization: Used to create or join an existing Security World
          - maintenance:    Used to upgrade firmware
          - operational:    Used for normal functionality

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony hsm world-info

```
Print information about the HSM's current Security World

Usage: ceremony hsm world-info [OPTIONS]

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

## ceremony meta

```
Commands about this ceremony tool

Usage: ceremony meta [OPTIONS] <COMMAND>

Commands:
  hash   Print the SHA-256 digest of this binary
  paths  Print the paths of things on the filesystem, reflecting the current environment variables
  help   Print this message or the help of the given subcommand(s)

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

### ceremony meta hash

```
Print the SHA-256 digest of this binary.

The digest is printed in hex and as a BIP-39 mnemonic.

Usage: ceremony meta hash [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony meta paths

```
Print the paths of things on the filesystem, reflecting the current environment variables

Usage: ceremony meta paths [OPTIONS]

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

## ceremony realm

```
Commands for Juicebox-specific HSM and realm initialization

Usage: ceremony realm [OPTIONS] <COMMAND>

Commands:
  create-nvram-file  Allocate a section of the HSM's NVRAM
  create-keys        Create the secret keys for the Juicebox realm
  noise-public-key   Print the public key that clients will use to authenticate this realm
  print-acl          Print the ACL for an existing key
  help               Print this message or the help of the given subcommand(s)

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

### ceremony realm create-nvram-file

```
Allocate a section of the HSM's NVRAM.

An ACL on the NVRAM file ensures that it may only be accessed by the signed software.

Usage: ceremony realm create-nvram-file [OPTIONS] --signing-key-hash <SIGNING_KEY_HASH>

Options:
      --dry-run
          Don't execute commands but display them unambiguously

      --signing-key-hash <SIGNING_KEY_HASH>
          The hash of the signing key, given as 40 hex characters. Used in the ACL for the NVRAM file

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony realm create-keys

```
Create the secret keys for the Juicebox realm.

ACLs on the keys ensure that they may only be accessed by the signed software.

Usage: ceremony realm create-keys [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony realm noise-public-key

```
Print the public key that clients will use to authenticate this realm

Usage: ceremony realm noise-public-key [OPTIONS]

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

### ceremony realm print-acl

```
Print the ACL for an existing key

Usage: ceremony realm print-acl [OPTIONS] <KEY>

Arguments:
  <KEY>
          Possible values:
          - mac:     Juicebox symmetric key used for HSM-to-HSM authentication
          - noise:   Juicebox asymmetric key used for client-HSM communication
          - record:  Juicebox symmetric key used for data encryption
          - signing: Asymmetric key used for signing HSM software and userdata

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

## ceremony realm-dvd

```
Create or verify a "Realm DVD" containing encrypted keys and signed HSM software

Usage: ceremony realm-dvd [OPTIONS] <COMMAND>

Commands:
  create-iso  Collect the files into a disc image file
  mount       Mount the DVD onto /run/dvd
  restore     Copy the expected files from the DVD onto the host filesystem
  unmount     Unmount the DVD
  verify      Check that a DVD contains exactly the expected files as found on the host filesystem
  write       Burn an ISO file to a DVD
  help        Print this message or the help of the given subcommand(s)

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

### ceremony realm-dvd create-iso

```
Collect the files into a disc image file

Usage: ceremony realm-dvd create-iso [OPTIONS]

Options:
      --dry-run        Don't execute commands but display them unambiguously
      --output <FILE>  [default: /home/ceremony-test/realm.iso]
  -h, --help           Print help
```

### ceremony realm-dvd mount

```
Mount the DVD onto /run/dvd

Usage: ceremony realm-dvd mount [OPTIONS]

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

### ceremony realm-dvd restore

```
Copy the expected files from the DVD onto the host filesystem.

This mounts and unmounts the DVD if needed. It also lists the files and their hashes.

Usage: ceremony realm-dvd restore [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony realm-dvd unmount

```
Unmount the DVD

Usage: ceremony realm-dvd unmount [OPTIONS]

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

### ceremony realm-dvd verify

```
Check that a DVD contains exactly the expected files as found on the host filesystem.

This mounts and unmounts the DVD if needed. It also lists the files and their hashes.

Usage: ceremony realm-dvd verify [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony realm-dvd write

```
Burn an ISO file to a DVD

Usage: ceremony realm-dvd write [OPTIONS]

Options:
      --dry-run     Don't execute commands but display them unambiguously
      --iso <FILE>  [default: /home/ceremony-test/realm.iso]
  -h, --help        Print help
```

## ceremony sign

```
Manage signing keys and sign HSM software and userdata

Usage: ceremony sign [OPTIONS] <COMMAND>

Commands:
  create-key  Create a software signing key
  key-info    Print information about the signing key, including its hash
  software    Sign the HSM software binary
  userdata    Sign dummy HSM userdata
  help        Print this message or the help of the given subcommand(s)

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

### ceremony sign create-key

```
Create a software signing key.

This will prompt for the OCS smartcard if not inserted.

Usage: ceremony sign create-key [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony sign key-info

```
Print information about the signing key, including its hash.

The ACLs refer to the signing key based on its hash.

Usage: ceremony sign key-info [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony sign software

```
Sign the HSM software binary.

This requires the OCS smartcard.

Usage: ceremony sign software [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

      --input <FILE>
          [default: /home/ceremony-test/juicebox-hsm-realm/target/powerpc-unknown-linux-gnu/release/entrust_hsm.elf]

      --output <FILE>
          [default: /home/ceremony-test/juicebox-hsm-realm/target/powerpc-unknown-linux-gnu/release/entrust_hsm.sar]

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony sign userdata

```
Sign dummy HSM userdata.

The userdata is a required file that may contain auxiliary information for the HSM software binary. Juicebox's software binary currently does not read this file, so its contents do not matter.

This requires the OCS smartcard.

Usage: ceremony sign userdata [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

      --tempfile <FILE>
          The path where the string "dummy" will be written
          
          [default: /home/ceremony-test/juicebox-hsm-realm/target/powerpc-unknown-linux-gnu/release/userdata.dummy]

      --output <FILE>
          [default: /home/ceremony-test/juicebox-hsm-realm/target/powerpc-unknown-linux-gnu/release/userdata.sar]

  -h, --help
          Print help (see a summary with '-h')
```

## ceremony smartcard

```
Manage HSM smartcards (which can contain sensitive keys).

Smartcards are inserted into a card reader that is directly attached to the HSM.

Usage: ceremony smartcard [OPTIONS] <COMMAND>

Commands:
  erase      Erase the contents of a smartcard, if possible
  info       Print information about the currently attached smartcard
  write-ocs  Write a new operator card (OCS)
  help       Print this message or the help of the given subcommand(s)

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony smartcard erase

```
Erase the contents of a smartcard, if possible.

It's possible to erase ACS cards, blank cards, and OCS cards from the current Security World. Due to restrictions in the underlying Entrust tools, it's not allowed to erase OCS cards from a different Security World.

Usage: ceremony smartcard erase [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony smartcard info

```
Print information about the currently attached smartcard

Usage: ceremony smartcard info [OPTIONS]

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

### ceremony smartcard write-ocs

```
Write a new operator card (OCS).

The HSM must be in operational mode. This writes a cardset made up of a single operator card.

Usage: ceremony smartcard write-ocs [OPTIONS]

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

## ceremony vendor

```
Load vendor-supplied software and artifacts

Usage: ceremony vendor [OPTIONS] <COMMAND>

Commands:
  install  Mount, unpack, and install components from the boot DVD
  mount    Mount the vendor's zipped ISO images on the filesystem
  unmount  Unmount the vendor's zipped ISO images
  help     Print this message or the help of the given subcommand(s)

Options:
      --dry-run  Don't execute commands but display them unambiguously
  -h, --help     Print help
```

### ceremony vendor install

```
Mount, unpack, and install components from the boot DVD

Usage: ceremony vendor install [OPTIONS] <COMPONENTS>...

Arguments:
  <COMPONENTS>...
          Possible values:
          - codesafe: Headers and libraries used to build code to run on HSMs
          - secworld: Drivers, daemons, and programs to access HSMs

Options:
      --dry-run
          Don't execute commands but display them unambiguously

      --zips-dir <DIR>
          Directory containing zipped ISO images. This is only used if the images aren't loopback-mounted already
          
          [default: /run/win/Users/defaultuser0]

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony vendor mount

```
Mount the vendor's zipped ISO images on the filesystem

Usage: ceremony vendor mount [OPTIONS] <DISCS>...

Arguments:
  <DISCS>...
          Possible values:
          - codesafe: Headers and libraries used to build code to run on HSMs
          - firmware: Low-level vendor-signed firmware for HSMs
          - secworld: Drivers, daemons, and programs to access HSMs

Options:
      --dry-run
          Don't execute commands but display them unambiguously

      --zips-dir <DIR>
          Directory containing zipped ISO images
          
          [default: /run/win/Users/defaultuser0]

  -h, --help
          Print help (see a summary with '-h')
```

### ceremony vendor unmount

```
Unmount the vendor's zipped ISO images

Usage: ceremony vendor unmount [OPTIONS] <DISCS>...

Arguments:
  <DISCS>...
          Possible values:
          - codesafe: Headers and libraries used to build code to run on HSMs
          - firmware: Low-level vendor-signed firmware for HSMs
          - secworld: Drivers, daemons, and programs to access HSMs

Options:
      --dry-run
          Don't execute commands but display them unambiguously

  -h, --help
          Print help (see a summary with '-h')
```

