use std::path::Path;
use std::process::Command;

pub fn setup_git_repo(dir: &Path) {
    Command::new("git")
        .args(["init", "-b", "main"])
        .current_dir(dir)
        .output()
        .expect("Failed to init git repo");

    Command::new("git")
        .args(["config", "user.email", "test@example.com"])
        .current_dir(dir)
        .output()
        .expect("Failed to config git user email");

    Command::new("git")
        .args(["config", "user.name", "Test User"])
        .current_dir(dir)
        .output()
        .expect("Failed to config git user name");

    Command::new("git")
        .args(["config", "commit.gpgsign", "false"])
        .current_dir(dir)
        .output()
        .expect("Failed to config git commit.gpgsign");

    std::fs::write(dir.join("initial.txt"), "hello").expect("Failed to write initial.txt");

    Command::new("git")
        .args(["add", "initial.txt"])
        .current_dir(dir)
        .output()
        .expect("Failed to git add");

    Command::new("git")
        .args(["commit", "-m", "initial commit"])
        .current_dir(dir)
        .output()
        .expect("Failed to git commit");
}

pub fn setup_remote(local: &Path, remote: &Path) {
    Command::new("git")
        .args(["init", "--bare"])
        .current_dir(remote)
        .output()
        .expect("Failed to init bare remote");

    Command::new("git")
        .args(["remote", "add", "origin", remote.to_str().unwrap()])
        .current_dir(local)
        .output()
        .expect("Failed to add remote origin");
}
