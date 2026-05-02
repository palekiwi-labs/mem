use crate::config::Config;
use crate::git;
use anyhow::{Context, Result};
use serde::Serialize;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Serialize)]
struct MemFile {
    path: String,
    name: String,
    branch: String,
    category: String,
    hash: Option<String>,
    commit_hash: Option<String>,
    commit_timestamp: u64,
}

pub fn handle(
    cwd: &Path,
    branch_name: Option<String>,
    all: bool,
    include_gitignored: bool,
    json: bool,
) -> Result<()> {
    // 1. Verify git repo
    git::run_git(["rev-parse", "--git-dir"], cwd).context("Not in a git repository")?;

    // 2. Get git root
    let root = git::get_git_root(cwd)?;

    // 3. Load config
    let config = Config::load(&root)?;

    // 4. Check if .mem exists
    let mem_path = root.join(&config.dir_name);
    if !mem_path.is_dir() {
        anyhow::bail!(
            "{} directory does not exist. Run `mem init` first.",
            config.dir_name
        );
    }

    // 5. Determine scan directory/directories
    let mut paths = if all {
        collect_files(&mem_path)?
    } else {
        let branch = if let Some(b) = branch_name {
            b
        } else {
            git::get_current_branch(&root)?
        };
        let branch_dir = branch.replace(['/', '\\'], "-");
        let scan_dir = mem_path.join(&branch_dir);

        if scan_dir.exists() {
            collect_files(&scan_dir)?
        } else {
            Vec::new()
        }
    };

    // 7. Sort
    paths.sort();

    // 8. Process files
    let mut mem_files = Vec::new();
    for path in paths {
        let Ok(rel_to_mem) = path.strip_prefix(&mem_path) else {
            continue;
        };
        let components: Vec<_> = rel_to_mem
            .components()
            .map(|c| c.as_os_str().to_string_lossy().to_string())
            .collect();

        if components.len() < 3 {
            continue;
        }

        let branch = &components[0];
        let category = &components[1];

        if !include_gitignored && (category == "tmp" || category == "ref") {
            continue;
        }

        let name = path
            .file_name()
            .map(|n| n.to_string_lossy().to_string())
            .unwrap_or_default();

        let rel_path = path
            .strip_prefix(&root)
            .unwrap_or(&path)
            .to_string_lossy()
            .to_string();

        let mut mem_file = MemFile {
            path: rel_path,
            name,
            branch: branch.clone(),
            category: category.clone(),
            hash: None,
            commit_hash: None,
            commit_timestamp: 0,
        };

        // Trace/Tmp handling for hash/timestamp
        if (category == "trace" || category == "tmp") && components.len() >= 4 {
            let ts_hash_dir = &components[2];
            if let Some((ts_str, hash_str)) = ts_hash_dir.split_once('-')
                && let Ok(ts) = ts_str.parse::<u64>() {
                    mem_file.commit_timestamp = ts;
                    mem_file.hash = Some(hash_str.to_string());
                    mem_file.commit_hash = Some(hash_str.to_string());
                }
        }

        mem_files.push(mem_file);
    }

    // 9. Output
    if json {
        println!("{}", serde_json::to_string_pretty(&mem_files)?);
    } else {
        for file in mem_files {
            println!("{}", file.path);
        }
    }

    Ok(())
}

fn collect_files(dir: &Path) -> Result<Vec<PathBuf>> {
    if !dir.is_dir() {
        return Ok(vec![]);
    }

    fs::read_dir(dir)?
        .map(|entry| -> Result<Vec<PathBuf>> {
            let path = entry?.path();
            if path.is_dir() {
                collect_files(&path)
            } else {
                Ok(vec![path])
            }
        })
        .collect::<Result<Vec<_>>>()
        .map(|v| v.into_iter().flatten().collect())
}
