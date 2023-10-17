//! This tool is used during HSM key ceremonies to run pre-determined commands.

use clap::{self, command, Parser};
use std::process::ExitCode;

mod bip39;
mod commands;
mod digests;
mod errors;
mod paths;
mod system;

use digests::Sha256Sum;
use errors::Error;
use paths::{join_path, join_paths, Paths};
use system::Process;

/// Command-line arguments.
#[derive(Debug, Parser)]
#[clap(about = "This tool is used during HSM key ceremonies to run pre-determined commands.")]
struct Args {
    #[clap(flatten)]
    common: CommonArgs,

    #[command(subcommand)]
    command: commands::Command,
}

/// Global command-line arguments (part of [`Args`]). Available in [`Context`].
#[derive(Debug, Parser)]
struct CommonArgs {
    /// Don't execute commands but display them unambiguously.
    #[arg(long, global(true))]
    dry_run: bool,
}

/// There is one `Context` per invocation of this program. Commands use this to
/// access global state and call methods that need global state.
///
/// Note: the [`digests`] and [`system`] modules also add impls to Context.
pub struct Context {
    common_args: CommonArgs,
    paths: &'static Paths,
}

/// Runs the program.
fn main() -> ExitCode {
    let args = Args::parse();
    println!("{args:#?}");
    println!();

    let context = Context {
        common_args: args.common,
        paths: Paths::get(),
    };

    match commands::run(&args.command, &context) {
        Ok(()) => ExitCode::SUCCESS,

        Err(error) => {
            eprintln!("ERROR: {error}");
            ExitCode::FAILURE
        }
    }
}

#[cfg(test)]
mod tests {
    use super::Args;
    use clap::CommandFactory;
    use std::fmt::Write;
    use std::fs;

    fn usage() -> String {
        fn recursive_usage(buf: &mut String, path: &str, command: &mut clap::Command) {
            command.set_bin_name(path);
            let heading_level = "#".repeat(path.matches(' ').count() + 1);
            writeln!(buf, "{heading_level} {path}").unwrap();
            writeln!(buf).unwrap();
            writeln!(buf, "```").unwrap();
            write!(buf, "{}", command.render_long_help()).unwrap();
            writeln!(buf, "```").unwrap();
            writeln!(buf).unwrap();

            for subcommand in command.get_subcommands_mut() {
                let name = subcommand.get_name();
                if name == "help" {
                    continue;
                }
                let subpath = format!("{path} {name}");
                recursive_usage(buf, &subpath, subcommand);
            }
        }

        let mut all_usage = String::new();

        let that = "This";
        writeln!(&mut all_usage, "_{that} file is automatically generated._").unwrap();
        writeln!(&mut all_usage).unwrap();

        recursive_usage(&mut all_usage, "ceremony", &mut Args::command());
        all_usage
    }

    /// Snapshot test for usage messages. See `usage.md`.
    #[test]
    fn test_usage() {
        let expected = fs::read_to_string("usage.md").unwrap();
        let actual = usage();
        if expected != actual {
            fs::write("usage.actual.md", &actual).unwrap();
            panic!("usage differs: compare expected (`usage.md`) with actual (`usage.actual.md`)");
        }
    }
}
