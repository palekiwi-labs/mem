mod helpers;

use helpers::TestEnv;
use predicates::prelude::*;
use std::fs;
use std::process::Command;

#[test]
fn test_context_render_with_base_sigil() -> anyhow::Result<()> {
    let env = TestEnv::new();
    helpers::setup_git_repo(env.root());

    // Create a dummy file and commit it on main
    fs::write(env.root().join("file.txt"), "original")?;
    run_git(env.root(), &["add", "file.txt"])?;
    run_git(env.root(), &["commit", "-m", "initial"])?;

    // Create a branch and modify the file
    run_git(env.root(), &["checkout", "-b", "feature"])?;
    fs::write(env.root().join("file.txt"), "modified")?;
    run_git(env.root(), &["add", "file.txt"])?;
    run_git(env.root(), &["commit", "-m", "feature change"])?;

    // Initialize mem
    env.command().arg("init").assert().success();

    // Create context.json with @base sigil
    let context_json = env.root().join(".mem").join("feature").join("context.json");
    fs::create_dir_all(context_json.parent().unwrap())?;
    fs::write(
        &context_json,
        r#"{
        "default": {
            "artifacts": [],
            "diff": "@base...HEAD"
        }
    }"#,
    )?;

    // Run mem context render --base main
    env.command()
        .arg("context")
        .arg("render")
        .arg("--base")
        .arg("main")
        .assert()
        .success()
        .stdout(predicate::str::contains("<diff>"))
        .stdout(predicate::str::contains("+modified"))
        .stdout(predicate::str::contains("-original"));

    // Run without --base should fail
    env.command()
        .arg("context")
        .arg("render")
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "uses '@base' in diff, but no --base branch was provided",
        ));

    Ok(())
}

fn run_git(dir: &std::path::Path, args: &[&str]) -> anyhow::Result<()> {
    let status = Command::new("git").current_dir(dir).args(args).status()?;
    if !status.success() {
        anyhow::bail!("git command failed: {:?}", args);
    }
    Ok(())
}
