use crate::cli::MemType;
use crate::config::Config;
use crate::git;
use anyhow::{bail, Context, Result};
use std::fs;
use std::path::Path;
use std::time::{SystemTime, UNIX_EPOCH};

pub fn handle(
    cwd: &Path,
    filename: &str,
    content: Option<String>,
    mem_type: MemType,
    force: bool,
) -> Result<()> {
    // 1. Verify git repo
    git::run_git(&["rev-parse", "--git-dir"], cwd).context("Not in a git repository")?;

    // 2. Get git root
    let root = git::get_git_root(cwd)?;

    // 3. Load config
    let config = Config::load(&root)?;

    // 4. Check if .mem exists
    let mem_path = root.join(&config.dir_name);
    if !mem_path.exists() {
        bail!(
            "{} directory does not exist. Run `mem init` first.",
            config.dir_name
        );
    }

    // 5. Get current branch
    let branch = git::get_current_branch(&root)?;

    // 6. Resolve destination directory
    let dest_dir = match mem_type {
        MemType::Spec => mem_path.join(&branch).join("spec"),
        MemType::Trace => {
            let ts = SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs();
            let hash = git::get_short_head_hash(&root)?;
            mem_path
                .join(&branch)
                .join("trace")
                .join(format!("{}-{}", ts, hash))
        }
        MemType::Tmp => {
            let ts = SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs();
            let hash = git::get_short_head_hash(&root)?;
            mem_path
                .join(&branch)
                .join("tmp")
                .join(format!("{}-{}", ts, hash))
        }
        MemType::Ref => mem_path.join(&branch).join("ref"),
    };

    let file_path = dest_dir.join(filename);

    // 7. Check if exists
    if file_path.exists() && !force {
        bail!(
            "File exists: {}. Use --force to overwrite.",
            file_path.to_string_lossy()
        );
    }

    // 8. Create parent dirs
    if let Some(parent) = file_path.parent() {
        fs::create_dir_all(parent)?;
    }

    // 9. Write file
    fs::write(&file_path, content.unwrap_or_default())?;

    // 10. Print confirmation
    let rel_path = file_path.strip_prefix(&root).unwrap_or(&file_path);
    println!("✓ Created {}", rel_path.to_string_lossy());

    Ok(())
}
