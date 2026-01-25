# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Git helper functions for mem

use ../config.nu [MEM_DIR_NAME, MEM_BRANCH_NAME]

export def is-git-repo [] {
    (do { git rev-parse --git-dir } | complete).exit_code == 0
}

export def get-git-root [] {
    git rev-parse --show-toplevel | str trim
}

export def mem-dir-exists [] {
    let git_root = get-git-root
    let mem_path = ($git_root | path join $MEM_DIR_NAME)
    $mem_path | path exists
}

export def mem-branch-exists [] {
    (do { git rev-parse --verify $MEM_BRANCH_NAME } | complete).exit_code == 0
}

export def mem-branch-exists-on-remote [remote: string = "origin"] {
    (do { git ls-remote --heads $remote $MEM_BRANCH_NAME } | complete).stdout | str trim | is-not-empty
}

export def ensure-worktree [] {
    let git_root = get-git-root
    let mem_path = ($git_root | path join $MEM_DIR_NAME)
    
    if ($mem_path | path exists) {
        error make {msg: $"($MEM_DIR_NAME) directory already exists at ($mem_path)"}
    }
    
    if (mem-branch-exists) {
        # Case 1: Local branch exists - attach it
        git worktree add $mem_path $MEM_BRANCH_NAME
    } else if (mem-branch-exists-on-remote) {
        # Case 2: Branch exists on remote but not locally - fetch and checkout
        print $"Found ($MEM_BRANCH_NAME) branch on remote, fetching..."
        git fetch origin $"($MEM_BRANCH_NAME):($MEM_BRANCH_NAME)"
        git worktree add $mem_path $MEM_BRANCH_NAME
    } else {
        # Case 3: Branch doesn't exist anywhere - create new orphan branch
        git worktree add --orphan -b $MEM_BRANCH_NAME $mem_path
        
        # Change to worktree directory to create initial commit
        cd $mem_path
        
        # Create initial commit with .gitignore
        let gitignore_content = "*/tmp/\n*/ref/\n"
        $gitignore_content | save --force .gitignore
        
        git add .gitignore
        git commit -m $"Initialize ($MEM_BRANCH_NAME) branch"
    }
}

# Check if worktree exists at agent artifacts directory
export def worktree-exists [] {
    let git_root = get-git-root
    let mem_path = ($git_root | path join $MEM_DIR_NAME)
    let worktrees = (git worktree list --porcelain | parse "{key} {value}")
    
    $worktrees | any {|w| $w.key == "worktree" and ($w.value | str trim) == $mem_path}
}

export def get-current-branch [] {
    # Returns empty string if detached head
    (do { git branch --show-current } | complete).stdout | str trim
}

export def get-current-commit-short [] {
    git rev-parse --short HEAD | str trim
}

export def sanitize-branch-name [name: string] {
    $name | str replace --all "/" "-"
}

export def get-mem-dir-for-branch [branch: string] {
    let git_root = get-git-root
    let sanitized = (sanitize-branch-name $branch)
    $git_root | path join $MEM_DIR_NAME $sanitized
}

export def check-environment [] {
    if not (is-git-repo) {
        error make {msg: "Not in a git repository"}
    }
    
    if not (mem-dir-exists) {
        error make {msg: "Run 'mem init' first"}
    }
    
    let branch = (get-current-branch)
    if ($branch | is-empty) {
        error make {msg: "Not on a branch (detached HEAD)"}
    }
    
    $branch
}

export def get-mem-dir-name [] {
    $MEM_DIR_NAME
}
