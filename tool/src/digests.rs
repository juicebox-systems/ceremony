//! Utilities for dealing with cryptographic digests.

use sha2::{Digest, Sha256};
use std::fmt;
use std::io::{self, Write};

use super::Context;
use crate::bip39;
use crate::Error;

/// The output of SHA-256 (from the SHA2 family of cryptographic hash functions).
#[derive(Clone, PartialEq)]
pub struct Sha256Sum([u8; 32]);

impl Sha256Sum {
    pub const DUMMY: Self = Self([
        0xab, 0xad, 0xde, 0xca, 0xfc, 0x0f, 0xfe, 0xe1, //
        0xab, 0xad, 0xde, 0xca, 0xfc, 0x0f, 0xfe, 0xe2, //
        0xab, 0xad, 0xde, 0xca, 0xfc, 0x0f, 0xfe, 0xe3, //
        0xab, 0xad, 0xde, 0xca, 0xfc, 0x0f, 0xfe, 0xe4,
    ]);

    pub fn compute(data: &[u8]) -> Self {
        Self(Sha256::digest(data).into())
    }

    pub fn from_hex(hex: &str) -> Result<Self, hex::FromHexError> {
        let mut bytes = [0u8; 32];
        hex::decode_to_slice(hex, &mut bytes)?;
        Ok(Self(bytes))
    }
}

impl fmt::Display for Sha256Sum {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        hex::encode(self.0).fmt(f)
    }
}

impl fmt::Debug for Sha256Sum {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        hex::encode(self.0).fmt(f)
    }
}

/// Prints a BIP39 mnemonic phrase to stdout.
///
/// The phrase is split across multiple lines, with each line indented by 4 spaces
/// and including up to 4 words.
pub fn print_bip39_mnemonic(mnemonic: &[&'static str]) {
    let mut out = io::stdout().lock();
    for (i, word) in mnemonic.iter().enumerate() {
        if i % 4 == 0 {
            if i > 0 {
                writeln!(out).unwrap();
            }
            write!(out, "    {}", word).unwrap();
        } else {
            write!(out, " {}", word).unwrap();
        }
    }
    writeln!(out).unwrap();
}

impl Context {
    pub fn check_file_digest<'a>(
        &self,
        file: &'a str,
        expected: &Sha256Sum,
    ) -> Result<&'a str, Error> {
        println!();
        let digest: Sha256Sum = if self.common_args.dry_run {
            println!("Not computing file digest for {file:?} because --dry-run");
            expected.clone()
        } else {
            self.file_digest(file)?
        };

        println!("File {file:?}");
        println!("SHA-256: {digest}");
        println!("as BIP-39 mnemonic:");
        let mnemonic = bip39::to_mnemonic(&digest.0).unwrap();
        print_bip39_mnemonic(&mnemonic);
        if &digest != expected && !self.common_args.dry_run {
            return Err(Error::new(format!(
                "expected SHA-256 {expected} for {file:?}"
            )));
        }
        println!("Matches expected digest");
        println!();
        Ok(file)
    }

    pub fn file_digest(&self, file: &str) -> Result<Sha256Sum, Error> {
        if self.common_args.dry_run {
            println!("Not computing file digest for {file:?} because --dry-run");
            Ok(Sha256Sum::DUMMY)
        } else {
            let contents = self.read(file)?;
            Ok(Sha256Sum::compute(&contents))
        }
    }

    pub fn print_file_digest(&self, file: &str) -> Result<(), Error> {
        let digest = self.file_digest(file)?;
        println!("File {file:?}");
        println!("SHA-256: {digest}");
        println!("as BIP-39 mnemonic:");
        let mnemonic = bip39::to_mnemonic(&digest.0).unwrap();
        print_bip39_mnemonic(&mnemonic);
        println!();
        Ok(())
    }
}
