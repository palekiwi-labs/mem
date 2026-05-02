pub mod add;
pub mod list;

use crate::cli::LogCommands;
use std::path::Path;

pub fn handle(cwd: &Path, command: LogCommands) -> anyhow::Result<()> {
    match command {
        LogCommands::Add {
            title,
            body,
            found,
            decided,
            open,
            file,
        } => add::handle(cwd, title, body, found, decided, open, file),
        LogCommands::List { branch } => list::handle(cwd, branch),
    }
}
