mod helpers;

use assert_cmd::Command;
use predicates::prelude::*;
use std::fs;
use tempfile::TempDir;

#[test]
fn test_context_show_and_profiles() -> anyhow::Result<()> {
    let temp = TempDir::new()?;
    helpers::setup_git_repo(temp.path());

    // Initialize mem
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path()).arg("init").assert().success();

    let context_json = temp.path().join(".mem").join("main").join("context.json");
    fs::create_dir_all(context_json.parent().unwrap())?;
    fs::write(
        &context_json,
        r#"{
        "default": { "artifacts": ["./spec/index.md"] },
        "brief": { "artifacts": [] }
    }"#,
    )?;

    // Test show
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .arg("context")
        .arg("show")
        .assert()
        .success()
        .stdout(predicate::str::contains(r#""artifacts": ["#))
        .stdout(predicate::str::contains("default"))
        .stdout(predicate::str::contains("brief"));

    // Test profiles
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .arg("context")
        .arg("profiles")
        .assert()
        .success()
        .stdout("brief\ndefault\n");

    Ok(())
}

#[test]
fn test_context_missing_file_errors() -> anyhow::Result<()> {
    let temp = TempDir::new()?;
    helpers::setup_git_repo(temp.path());

    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .arg("context")
        .arg("show")
        .assert()
        .failure()
        .stderr(predicate::str::contains("Context file not found"));

    Ok(())
}
