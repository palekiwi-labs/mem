# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Git helper functions for mem

const MEM_DIR_NAME = ".mem"
const MEM_BRANCH_NAME = "mem"

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

export def ensure-worktree [] {
    let git_root = get-git-root
    let mem_path = ($git_root | path join $MEM_DIR_NAME)
    
    if ($mem_path | path exists) {
        error make {msg: $"($MEM_DIR_NAME) directory already exists at ($mem_path)"}
    }
    
    if (mem-branch-exists) {
        # Just attach the existing branch
        git worktree add $mem_path $MEM_BRANCH_NAME
    } else {
        # Create orphan branch with worktree in one step
        git worktree add --orphan -b $MEM_BRANCH_NAME $mem_path
        
        # Change to worktree directory to create initial commit
        cd $mem_path
        
        # Create initial commit with .gitignore
        let gitignore_content = "*/tmp/\n*/refs/\n"
        $gitignore_content | save --force .gitignore
        
        git add .gitignore
        git commit -m $"Initialize ($MEM_BRANCH_NAME) branch"
    }
}

# Check if worktree exists at .mem/
export def worktree-exists [] {
    let git_root = get-git-root
    let mem_path = ($git_root | path join $MEM_DIR_NAME)
    let worktrees = (git worktree list --porcelain | parse "{key} {value}")
    
    $worktrees | any {|w| $w.key == "worktree" and ($w.value | str trim) == $mem_path}
}
