mod cli;
mod commands;
mod config;
mod git;

use crate::cli::{Cli, Commands};
use anyhow::Context;
use clap::Parser;
use std::env;
use std::io::{self, Read};

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
            file,
            mem_type,
            force,
        } => {
            let resolved_content: Vec<u8> = if let Some(path) = file {
                std::fs::read(&path).with_context(|| format!("Failed to read file {}", path))?
            } else if let Some(c) = content {
                if c == "-" {
                    let mut buf = Vec::new();
                    io::stdin()
                        .read_to_end(&mut buf)
                        .context("Failed to read from stdin")?;
                    buf
                } else {
                    c.into_bytes()
                }
            } else {
                Vec::new()
            };

            commands::add::handle(&cwd, &filename, resolved_content, mem_type, force)?;
        }
    }

    Ok(())
}
