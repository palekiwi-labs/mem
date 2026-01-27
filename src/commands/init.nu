# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Initialize agent artifacts directory structure

use ../lib/config load
use ../lib/git_utils.nu

# Initialize the agent artifacts directory with orphan branch and worktree
export def main [] {
    # 1. Check if we're in a git repository
    if not (git_utils is-git-repo) {
        error make {msg: "Not in a git repository"}
    }
    
    let config = (load)
    let mem_dir_name = $config.dir_name
    let mem_branch_name = $config.branch_name
    
    # 2. Check if agent artifacts directory already exists
    if (git_utils mem-dir-exists) {
        print $"($mem_dir_name)/ directory already exists. Already initialized?"
        exit 0
    }
    
    # 3. Check if worktree already exists (edge case)
    if (git_utils worktree-exists) {
        error make {msg: $"($mem_dir_name) worktree already exists"}
    }

    git_utils ensure-worktree
    
    print ""
    print $"✓ Initialized ($mem_dir_name)/ directory"
    print $"✓ Orphan branch '($mem_branch_name)' ready"
    print $"✓ Worktree mounted at ($mem_dir_name)/"
}
