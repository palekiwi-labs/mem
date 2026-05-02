mod cli;
mod commands;
mod config;
mod git;

use crate::cli::{Cli, Commands};
use clap::Parser;
use std::env;

fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();
    let cwd = env::current_dir()?;

    match cli.command {
        Commands::Init => {
            commands::init::handle(&cwd)?;
        }
        Commands::Add {
            filename,
            content,
            mem_type,
            force,
        } => {
            commands::add::handle(&cwd, &filename, content, mem_type, force)?;
        }
    }

    Ok(())
}
