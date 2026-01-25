# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Initialize .mem directory structure

use ../lib/git.nu

# Initialize the .mem directory with orphan branch and worktree
export def main [] {
    # 1. Check if we're in a git repository
    if not (git is-git-repo) {
        print -e "Error: Not in a git repository"
        exit 1
    }
    
    # 2. Check if .mem/ already exists
    if (git mem-dir-exists) {
        print ".mem/ directory already exists. Already initialized?"
        exit 0
    }
    
    # 3. Check if worktree already exists (edge case)
    if (git worktree-exists) {
        print -e "Error: .mem worktree already exists"
        exit 1
    }
    
    # 4. Create or use existing 'mem' branch
    if not (git mem-branch-exists) {
        print "Creating orphan branch 'mem'..."
        git create-orphan-branch
    } else {
        print "Using existing 'mem' branch..."
    }
    
    # 5. Add worktree at .mem/
    print "Setting up worktree at .mem/..."
    git add-worktree
    
    # 6. Success message
    print ""
    print "✓ Initialized .mem/ directory"
    print "✓ Orphan branch 'mem' ready"
    print "✓ Worktree mounted at .mem/"
}
