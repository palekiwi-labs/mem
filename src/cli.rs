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
    #[command(arg_required_else_help = true)]
    Add {
        /// Name of the artifact file
        filename: String,
        /// Initial content for the file (use "-" to read from stdin)
        #[arg(conflicts_with_all = &["file", "clipboard"])]
        content: Option<String>,
        /// Read content from a file (recommended for AI agents to avoid escaping)
        #[arg(short = 'f', long = "file", conflicts_with_all = &["content", "clipboard"])]
        file: Option<String>,
        /// Read content from system clipboard
        #[arg(short = 'c', long = "clipboard", conflicts_with_all = &["content", "file"])]
        clipboard: bool,
        /// Type of artifact
        #[arg(short = 't', long = "type", value_enum, default_value = "spec")]
        mem_type: MemType,
        /// Overwrite existing file
        #[arg(long)]
        force: bool,
    },
}
