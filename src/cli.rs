use clap::{Parser, Subcommand, ValueEnum};

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(ValueEnum, Clone, Copy, Debug)]
pub enum MemType {
    Spec,
    Trace,
    Tmp,
    Ref,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Initialize agent artifacts directory structure
    Init,
    /// Add a new artifact
    Add {
        /// Name of the artifact file
        filename: String,
        /// Initial content for the file
        content: Option<String>,
        /// Type of artifact
        #[arg(short = 't', long = "type", value_enum, default_value = "spec")]
        mem_type: MemType,
        /// Overwrite existing file
        #[arg(long)]
        force: bool,
    },
}
