use crate::config::Config;
use crate::git;
use anyhow::{Context, Result};
use std::fs;
use std::path::Path;

pub fn handle(cwd: &Path, branch_name: Option<String>) -> Result<()> {
    // 1. Verify git repo
    git::run_git(["rev-parse", "--git-dir"], cwd).context("Not in a git repository")?;

    // 2. Get git root
    let root = git::get_git_root(cwd)?;

    // 3. Load config
    let config = Config::load(&root)?;

    // 4. Check if .mem exists
    let mem_path = root.join(&config.dir_name);
    if !mem_path.exists() {
        return Ok(()); // Silently exit
    }

    // 5. Get branch
    let branch = if let Some(b) = branch_name {
        b
    } else {
        git::get_current_branch(&root)
            .context("Could not determine current branch. Have you made your first commit yet?")?
    };
    let branch_dir = branch.replace(['/', '\\'], "-");

    let log_file_path = mem_path.join(&branch_dir).join("spec").join("log.md");

    if log_file_path.exists() {
        let content = fs::read_to_string(&log_file_path)
            .with_context(|| format!("Failed to read {}", log_file_path.display()))?;
        print!("{}", content);
    }

    Ok(())
}
