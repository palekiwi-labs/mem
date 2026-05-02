mod helpers;

use assert_cmd::Command;
use tempfile::TempDir;

#[test]
fn test_list_empty_repo() -> anyhow::Result<()> {
    let temp = TempDir::new()?;
    helpers::setup_git_repo(temp.path());

    // 1. Initialize mem
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("init");
    cmd.assert().success();

    // 2. List (should be empty)
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("list");

    let output = cmd.assert().success().get_output().stdout.clone();
    assert!(output.is_empty());

    Ok(())
}

#[test]
fn test_list_not_a_git_repo() -> anyhow::Result<()> {
    let temp = TempDir::new()?;

    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path()).arg("list");

    cmd.assert()
        .failure()
        .stderr(predicates::str::contains("Not in a git repository"));

    Ok(())
}

#[test]
fn test_list_ignores_shallow_paths() -> anyhow::Result<()> {
    let temp = TempDir::new()?;
    helpers::setup_git_repo(temp.path());

    // 1. Initialize
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("init");
    cmd.assert().success();

    // 2. Create a file directly under the branch dir (invalid depth)
    let branch_dir = temp.path().join(".test-mem/main");
    std::fs::create_dir_all(&branch_dir)?;
    let invalid_file = branch_dir.join("README.md");
    std::fs::write(invalid_file, "invalid")?;

    // 3. Add a valid file
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("add")
        .arg("index.md")
        .arg("content");
    cmd.assert().success();

    // 4. List
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("list");

    let output = String::from_utf8(cmd.assert().success().get_output().stdout.clone())?;
    assert!(output.contains("index.md"));
    assert!(!output.contains("README.md"));

    Ok(())
}

#[test]
fn test_list_excludes_tmp_and_ref() -> anyhow::Result<()> {
    let temp = TempDir::new()?;
    helpers::setup_git_repo(temp.path());

    // 1. Initialize
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("init");
    cmd.assert().success();

    // 2. Add spec, tmp, and ref files
    // Spec
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("add")
        .arg("spec.md")
        .arg("content");
    cmd.assert().success();

    // Tmp
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("add")
        .arg("-t")
        .arg("tmp")
        .arg("tmp.log")
        .arg("content");
    cmd.assert().success();

    // Ref
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("add")
        .arg("-t")
        .arg("ref")
        .arg("ref.md")
        .arg("content");
    cmd.assert().success();

    // 3. List
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("list");

    let output = String::from_utf8(cmd.assert().success().get_output().stdout.clone())?;
    let lines: Vec<&str> = output.trim().lines().collect();

    // Should only contain spec.md (and potentially other spec files if created by init, but init only creates .gitignore/.rgignore which are NOT in spec/)
    // Wait, add command puts things in .test-mem/main/spec/
    // Let's check exactly what's there.
    assert_eq!(lines.len(), 1);
    assert!(lines[0].contains("spec.md"));
    assert!(!output.contains("tmp.log"));
    assert!(!output.contains("ref.md"));

    Ok(())
}

#[test]
fn test_list_includes_trace() -> anyhow::Result<()> {
    let temp = TempDir::new()?;
    helpers::setup_git_repo(temp.path());

    // 1. Initialize
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("init");
    cmd.assert().success();

    // 2. Add trace file
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("add")
        .arg("-t")
        .arg("trace")
        .arg("trace.log")
        .arg("trace content");
    cmd.assert().success();

    // 3. List
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("list");

    let output = String::from_utf8(cmd.assert().success().get_output().stdout.clone())?;
    assert!(output.contains("trace.log"));
    assert!(output.contains("/trace/"));

    Ok(())
}

#[test]
fn test_list_include_gitignored() -> anyhow::Result<()> {
    let temp = TempDir::new()?;
    helpers::setup_git_repo(temp.path());

    // 1. Initialize
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("init");
    cmd.assert().success();

    // 2. Add spec and tmp files
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("add")
        .arg("spec.md")
        .arg("content");
    cmd.assert().success();

    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("add")
        .arg("-t")
        .arg("tmp")
        .arg("tmp.log")
        .arg("content");
    cmd.assert().success();

    // 3. List with -i
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("list")
        .arg("-i");

    let output = String::from_utf8(cmd.assert().success().get_output().stdout.clone())?;
    assert!(output.contains("spec.md"));
    assert!(output.contains("tmp.log"));

    Ok(())
}

#[test]
fn test_list_json_spec() -> anyhow::Result<()> {
    let temp = TempDir::new()?;
    helpers::setup_git_repo(temp.path());

    // 1. Initialize
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("init");
    cmd.assert().success();

    // 2. Add spec file
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("add")
        .arg("index.md")
        .arg("content");
    cmd.assert().success();

    // 3. List with --json
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("list")
        .arg("--json");

    let output = String::from_utf8(cmd.assert().success().get_output().stdout.clone())?;
    let json: serde_json::Value = serde_json::from_str(&output)?;

    assert!(json.is_array());
    let arr = json.as_array().unwrap();
    assert_eq!(arr.len(), 1);

    let item = &arr[0];
    assert_eq!(item["name"], "index.md");
    assert_eq!(item["category"], "spec");
    assert_eq!(item["branch"], "main"); // default git branch in setup_git_repo is main
    assert!(item["hash"].is_null());
    assert!(item["commit_hash"].is_null());
    assert_eq!(item["commit_timestamp"], 0);

    Ok(())
}

#[test]
fn test_list_json_trace() -> anyhow::Result<()> {
    let temp = TempDir::new()?;
    helpers::setup_git_repo(temp.path());

    // 1. Initialize
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("init");
    cmd.assert().success();

    // 2. Add trace file
    // The add command will create a ts-hash directory automatically for trace type
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("add")
        .arg("-t")
        .arg("trace")
        .arg("trace.log")
        .arg("trace content");
    cmd.assert().success();

    // 3. List with --json
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("list")
        .arg("--json");

    let output = String::from_utf8(cmd.assert().success().get_output().stdout.clone())?;
    let json: serde_json::Value = serde_json::from_str(&output)?;

    let arr = json.as_array().unwrap();
    assert_eq!(arr.len(), 1);

    let item = &arr[0];
    assert_eq!(item["name"], "trace.log");
    assert_eq!(item["category"], "trace");

    // Should have non-null hash and non-zero timestamp
    assert!(item["hash"].is_string());
    assert!(item["commit_hash"].is_string());
    assert!(item["commit_timestamp"].as_u64().unwrap() > 0);

    Ok(())
}

#[test]
fn test_list_branch_flag() -> anyhow::Result<()> {
    let temp = TempDir::new()?;
    helpers::setup_git_repo(temp.path());

    // 1. Initialize
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("init");
    cmd.assert().success();

    // 2. Add file to current branch (main)
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("add")
        .arg("main.md")
        .arg("content");
    cmd.assert().success();

    // 3. Create another branch and add file
    std::process::Command::new("git")
        .args(["checkout", "-b", "other"])
        .current_dir(temp.path())
        .output()?;

    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("add")
        .arg("other.md")
        .arg("content");
    cmd.assert().success();

    // 4. List current branch (other)
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("list");
    let output = String::from_utf8(cmd.assert().success().get_output().stdout.clone())?;
    assert!(output.contains("other.md"));
    assert!(!output.contains("main.md"));

    // 5. List main branch via --branch
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("list")
        .arg("--branch")
        .arg("main");
    let output = String::from_utf8(cmd.assert().success().get_output().stdout.clone())?;
    assert!(output.contains("main.md"));
    assert!(!output.contains("other.md"));

    Ok(())
}

#[test]
fn test_list_all_branches() -> anyhow::Result<()> {
    let temp = TempDir::new()?;
    helpers::setup_git_repo(temp.path());

    // 1. Initialize
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("init");
    cmd.assert().success();

    // 2. Add file to main
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("add")
        .arg("main.md")
        .arg("content");
    cmd.assert().success();

    // 3. Add file to other (manually create dir to simulate other branch having data)
    let other_spec_dir = temp.path().join(".test-mem/other/spec");
    std::fs::create_dir_all(&other_spec_dir)?;
    std::fs::write(other_spec_dir.join("other.md"), "content")?;

    // 4. List --all
    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path())
        .env("MEM_BRANCH_NAME", "test-mem")
        .env("MEM_DIR_NAME", ".test-mem")
        .arg("list")
        .arg("--all");

    let output = String::from_utf8(cmd.assert().success().get_output().stdout.clone())?;
    assert!(output.contains("main.md"));
    assert!(output.contains("other.md"));

    Ok(())
}

#[test]
fn test_list_not_initialized() -> anyhow::Result<()> {
    let temp = TempDir::new()?;
    helpers::setup_git_repo(temp.path());

    let mut cmd = Command::cargo_bin("mem")?;
    cmd.current_dir(temp.path()).arg("list");

    cmd.assert().failure().stderr(predicates::str::contains(
        "directory does not exist. Run `mem init` first.",
    ));

    Ok(())
}
