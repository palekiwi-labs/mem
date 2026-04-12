use assert_cmd::Command;
use std::process::Command as StdCommand;
use tempfile::TempDir;
use std::fs;
use anyhow::Result;

fn setup_git_repo() -> Result<TempDir> {
    let temp = tempfile::tempdir().unwrap();

    //Initialize git repo
    StdCommand::new("git")
        .arg("init")
        .current_dir(temp.path())
        .status()?;

    //Create initial commit (worktrees need at least one commit)
    fs::write(temp.path().join("README.md"), "test").unwrap();
    StdCommand::new("git")
        .args(["add", "."])
        .current_dir(temp.path())
        .status()?;

    StdCommand::new("git")
        .args(["commit", "-m", "initial"])
        .current_dir(temp.path())
        .status()?;

    Ok(temp)
}

#[test]
fn init_creates_orphan_branch_and_worktree() -> Result<()>{
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

    // Verify mem brach exists and is orphan
    let output = StdCommand::new("git")
        .args(["log", "--format=%P", "mem"]) // %P = parent hashes
        .current_dir(project.path())
        .output()?;

    let parents = String::from_utf8(output.stdout)?;
    assert_eq!(parents.trim(), "", "mem branch should be orphan (no parents)");

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
