//! Filesystem mounting.

use super::{Context, Process};
use crate::Error;

/// Filesystem mounting.
///
/// These respect dry runs.
impl Context {
    /// Note: Always returns true during dry runs.
    pub(crate) fn is_mounted(&self, mount_path: &str) -> Result<bool, Error> {
        self.exec_ok(Process::new("findmnt", &["--mountpoint", mount_path]))
    }

    pub(crate) fn mount_readonly(&self, device_path: &str, mount_path: &str) -> Result<(), Error> {
        if self.common_args.dry_run {
            println!("Not creating {mount_path:?} because --dry-run");
        } else {
            self.create_dir_all(mount_path)?;
        }

        self.exec(Process::new(
            "mount",
            &["-o", "ro", device_path, mount_path],
        ))
    }

    pub(crate) fn unmount(&self, mount_path: &str) -> Result<(), Error> {
        self.exec(Process::new("umount", &[mount_path]))?;
        self.remove_dir_only(mount_path)
    }
}
