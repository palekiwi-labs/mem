use anyhow::Result;
use std::path::Path;

pub fn handle(
    _cwd: &Path,
    _branch: Option<String>,
    _all: bool,
    _include_gitignored: bool,
    _json: bool,
) -> Result<()> {
    Ok(())
}
