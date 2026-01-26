# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Push mem branch to remote

use ../lib/git_utils.nu
use ../config.nu [MEM_BRANCH_NAME, MEM_DIR_NAME]

export def main [
    --remote: string = "origin"  # Remote to push to (default: origin)
] {
    # 1. Environment Checks
    git_utils check-environment
    
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
    
    # 3. Safety check - warn if no new commits to push
    let commits_ahead = (git_utils get-commits-ahead $remote)
    
    if $commits_ahead == 0 {
        print $"⚠ No new commits to push to ($remote)/($MEM_BRANCH_NAME)"
        return
    }
    
    # 4. Show what will be pushed
    print $"Pushing ($commits_ahead) commit\(s\) to ($remote)/($MEM_BRANCH_NAME)..."
    
    # 5. Change to mem directory and push
    let git_root = (git_utils get-git-root)
    let mem_path = ($git_root | path join $MEM_DIR_NAME)
    
    cd $mem_path
    
    # Execute push with error handling
    let result = (do { git push $remote $MEM_BRANCH_NAME } | complete)
    
    if $result.exit_code != 0 {
        error make {
            msg: $"Failed to push to ($remote)"
            help: $result.stderr
        }
    }
    
    print $"✓ Successfully pushed to ($remote)/($MEM_BRANCH_NAME)"
}
