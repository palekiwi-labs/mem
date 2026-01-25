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

# Ensure worktree exists at .mem/, creating branch if needed
export def ensure-worktree [] {
    let git_root = get-git-root
    let mem_path = ($git_root | path join ".mem")
    
    # Ensure .mem directory doesn't already exist
    if ($mem_path | path exists) {
        error make {msg: $".mem directory already exists at ($mem_path)"}
    }
    
    if (mem-branch-exists) {
        # Just attach the existing branch
        git worktree add $mem_path mem
    } else {
        # Create orphan branch with worktree in one step
        git worktree add --orphan -b mem $mem_path
        
        # Change to .mem directory to create initial commit
        cd $mem_path
        
        # Create initial commit with .gitignore
        let gitignore_content = "*/tmp/\n*/refs/\n"
        $gitignore_content | save --force .gitignore
        
        git add .gitignore
        git commit -m "Initialize mem branch"
    }
}

# Check if worktree exists at .mem/
export def worktree-exists [] {
    let git_root = get-git-root
    let mem_path = ($git_root | path join ".mem")
    let worktrees = (git worktree list --porcelain | parse "{key} {value}")
    
    $worktrees | any {|w| $w.key == "worktree" and ($w.value | str trim) == $mem_path}
}
