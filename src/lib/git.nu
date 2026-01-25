# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Git helper functions for mem

# Check if current directory is in a git repository
export def is-git-repo [] {
    (do { git rev-parse --git-dir } | complete).exit_code == 0
}

# Get the git root directory
export def get-git-root [] {
    git rev-parse --show-toplevel | str trim
}

# Check if .mem/ directory exists
export def mem-dir-exists [] {
    let git_root = get-git-root
    let mem_path = ($git_root | path join ".mem")
    $mem_path | path exists
}

# Check if 'mem' branch exists
export def mem-branch-exists [] {
    (do { git rev-parse --verify mem } | complete).exit_code == 0
}

# Create orphan branch 'mem'
export def create-orphan-branch [] {
    # Save current branch/commit to return to later
    let current_ref = (git symbolic-ref --short HEAD | complete | get stdout | str trim)
    
    # Create orphan branch
    git checkout --orphan mem
    
    # Clear staging area
    git rm -rf . | complete | ignore
    
    # Create initial commit with .gitignore
    let gitignore_content = "*/tmp/\n*/refs/\n"
    $gitignore_content | save --force .gitignore
    
    git add .gitignore
    git commit -m "Initialize mem branch"
    
    # Return to original branch
    if $current_ref != "" {
        git checkout $current_ref
    }
}

# Add worktree at .mem/ for 'mem' branch
export def add-worktree [] {
    let git_root = get-git-root
    let mem_path = ($git_root | path join ".mem")
    git worktree add $mem_path mem
}

# Check if worktree exists at .mem/
export def worktree-exists [] {
    let git_root = get-git-root
    let mem_path = ($git_root | path join ".mem")
    let worktrees = (git worktree list --porcelain | parse "{key} {value}")
    
    $worktrees | any {|w| $w.key == "worktree" and ($w.value | str trim) == $mem_path}
}
