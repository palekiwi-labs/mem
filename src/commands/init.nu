# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Initialize .mem directory structure

use ../lib/git_utils.nu

# Initialize the .mem directory with orphan branch and worktree
export def main [] {
    # 1. Check if we're in a git repository
    if not (git_utils is-git-repo) {
        error make {msg: "Not in a git repository"}
    }
    
    # 2. Check if .mem/ already exists
    if (git_utils mem-dir-exists) {
        print ".mem/ directory already exists. Already initialized?"
        exit 0
    }
    
    # 3. Check if worktree already exists (edge case)
    if (git_utils worktree-exists) {
        error make {msg: ".mem worktree already exists"}
    }

    git_utils ensure-worktree
    
    print ""
    print "✓ Initialized .mem/ directory"
    print "✓ Orphan branch 'mem' ready"
    print "✓ Worktree mounted at .mem/"
}
