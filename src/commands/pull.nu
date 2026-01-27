# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Pull mem branch from remote

use ../lib/git_utils.nu
use ../lib/config load

export def main [
    --remote: string = "origin"  # Remote to pull from (default: origin)
] {
    # 1. Environment Checks
    git_utils check-environment
    
    let config = (load)
    let mem_branch_name = $config.branch_name
    let mem_dir_name = $config.dir_name
    
    # 2. Verify remote exists
    if not (git_utils remote-exists $remote) {
        let remotes = (git remote | lines | str join ", ")
        let help_text = if ($remotes | is-empty) {
            "No remotes configured. Add one with: git remote add origin <url>"
        } else {
            $"Available remotes: ($remotes)"
        }
        
        error make {
            msg: $"Remote '($remote)' does not exist"
            help: $help_text
        }
    }
    
    # 3. Safety check - warn about uncommitted changes
    if (git_utils has-uncommitted-changes) {
        print "⚠ Warning: You have uncommitted changes in .mem/"
        print "  These may conflict with incoming changes."
        print ""
        
        let response = (input "Continue with pull? (y/N): ")
        
        if ($response | str downcase) != "y" {
            print "Pull cancelled."
            exit 130  # User cancelled
        }
    }
    
    # 4. Fetch to check if there are updates
    let git_root = (git_utils get-git-root)
    let mem_path = ($git_root | path join $mem_dir_name)
    
    cd $mem_path
    
    print $"Fetching from ($remote)/($mem_branch_name)..."
    let fetch_result = (do { git fetch $remote $mem_branch_name } | complete)
    
    if $fetch_result.exit_code != 0 {
        error make {
            msg: $"Failed to fetch from ($remote)"
            help: $fetch_result.stderr
        }
    }
    
    # 5. Check if behind
    if not (git_utils is-behind-remote $remote) {
        print $"✓ Already up to date with ($remote)/($mem_branch_name)"
        return
    }
    
    # 6. Pull changes
    print $"Pulling from ($remote)/($mem_branch_name)..."
    let pull_result = (do { git pull $remote $mem_branch_name } | complete)
    
    if $pull_result.exit_code != 0 {
        error make {
            msg: $"Failed to pull from ($remote)"
            help: $"($pull_result.stderr)\n\nYou may have merge conflicts. Resolve them in ($mem_dir_name)/ and commit."
        }
    }
    
    print $"✓ Successfully pulled from ($remote)/($mem_branch_name)"
}
