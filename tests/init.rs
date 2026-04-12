use anyhow::{Context, Result};
use assert_cmd::Command;
use std::fs;
use std::path::Path;
use std::process::Command as StdCommand;
use tempfile::TempDir;

/// Extension trait to isolate Git commands from the user's environment.
pub trait IsolatedGitCommand {
    fn isolated_git(&mut self, isolation_dir: &Path) -> &mut Self;
}

impl IsolatedGitCommand for StdCommand {
    fn isolated_git(&mut self, isolation_dir: &Path) -> &mut Self {
        self.env("GIT_CONFIG_GLOBAL", "/dev/null")
            .env("GIT_CONFIG_SYSTEM", "/dev/null")
            .env("GIT_CONFIG_NOSYSTEM", "1")
            .env("HOME", isolation_dir)
            .env("XDG_CONFIG_HOME", isolation_dir)
            .env("GIT_TERMINAL_PROMPT", "0")
            .env("GIT_AUTHOR_NAME", "Test Author")
            .env("GIT_AUTHOR_EMAIL", "author@example.com")
            .env("GIT_COMMITTER_NAME", "Test Committer")
            .env("GIT_COMMITTER_EMAIL", "committer@example.com")
    }
}

fn setup_git_repo() -> Result<TempDir> {
    let temp = tempfile::tempdir().context("Failed to create temporary directory")?;
    let path = temp.path();

    // Initialize git repo with a predictable default branch
    StdCommand::new("git")
        .isolated_git(path)
        .current_dir(path)
        .args(["init", "--initial-branch=master"])
        .status()
        .context("Failed to run git init")?;

    // Create initial commit (worktrees need at least one commit)
    fs::write(path.join("README.md"), "test").context("Failed to write README.md")?;

    StdCommand::new("git")
        .isolated_git(path)
        .current_dir(path)
        .args(["add", "."])
        .status()
        .context("Failed to run git add")?;

    StdCommand::new("git")
        .isolated_git(path)
        .current_dir(path)
        .args(["commit", "-m", "initial"])
        .status()
        .context("Failed to run git commit")?;

    Ok(temp)
}

#[test]
fn init_creates_orphan_branch_and_worktree() -> Result<()> {
    // GIVEN: A fresh git repository (with at least one commit)
    // WHEN: We run `mem init`
    // THEN:
    //   - Command succeeds
    //   - .mem directory exists
    //   - .mem is a git worktree
    //   - mem branch exists and is orphan (zero parents)
    //   - .mem/.gitignore exists with correct content
    //   - .mem/.rgignore exists with correct content
    let project = setup_git_repo()?;

    // Run mem init
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(project.path())
        .arg("init")
        .assert()
        .success();

    // Verify .mem directory exists
    let mem_dir = project.path().join(".mem");
    assert!(mem_dir.exists());

    // Verify it's a worktree
    assert!(mem_dir.join(".git").is_file());

    // Verify mem branch exists and is orphan
    let output = StdCommand::new("git")
        .isolated_git(project.path())
        .args(["log", "--format=%P", "mem"]) // %P = parent hashes
        .current_dir(project.path())
        .output()?;

    let parents = String::from_utf8(output.stdout)?;
    assert_eq!(
        parents.trim(),
        "",
        "mem branch should be orphan (no parents)"
    );

    // Verify .gitignore exists with correct content
    let gitignore = fs::read_to_string(mem_dir.join(".gitignore"))?;
    assert!(gitignore.contains("*/tmp/"));
    assert!(gitignore.contains("*/ref/"));

    // Verify .rgignore exists
    let rgignore = fs::read_to_string(mem_dir.join(".rgignore"))?;
    assert!(rgignore.contains("!*/tmp/"));
    assert!(rgignore.contains("!*/ref/"));

    Ok(())
}
