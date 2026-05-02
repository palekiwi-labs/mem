mod helpers;

use assert_cmd::Command;
use predicates::prelude::*;
use std::fs;
use tempfile::TempDir;

#[test]
fn test_add_spec_default() -> anyhow::Result<()> {
    let temp = TempDir::new()?;
    helpers::setup_git_repo(temp.path());

    // Initialize mem
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("init");
    cmd.assert().success();

    // Add a file
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("add")
        .arg("index.md")
        .arg("Project scope");

    cmd.assert().success().stdout(predicate::str::contains(
        "Created .test-mem/main/spec/index.md",
    ));

    let file_path = temp.path().join(".test-mem/main/spec/index.md");
    assert!(file_path.exists());
    let content = fs::read_to_string(file_path)?;
    assert_eq!(content, "Project scope");

    Ok(())
}
