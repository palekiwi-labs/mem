# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Initialize .mem directory structure

use ../config.nu [MEM_DIR_NAME, MEM_BRANCH_NAME]
use ../lib/git_utils.nu

# Initialize the .mem directory with orphan branch and worktree
export def main [] {
    # 1. Check if we're in a git repository
    if not (git_utils is-git-repo) {
        error make {msg: "Not in a git repository"}
    }
    
    # 2. Check if .mem/ already exists
    if (git_utils mem-dir-exists) {
        print $"($MEM_DIR_NAME)/ directory already exists. Already initialized?"
        exit 0
    }
    
    # 3. Check if worktree already exists (edge case)
    if (git_utils worktree-exists) {
        error make {msg: $"($MEM_DIR_NAME) worktree already exists"}
    }

    git_utils ensure-worktree
    
    print ""
    print $"✓ Initialized ($MEM_DIR_NAME)/ directory"
    print $"✓ Orphan branch '($MEM_BRANCH_NAME)' ready"
    print $"✓ Worktree mounted at ($MEM_DIR_NAME)/"
}
