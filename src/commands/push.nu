# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Push mem branch to remote

use ../lib/git_utils.nu
use ../config.nu [get-mem-branch-name, get-mem-dir-name]

export def main [
    --remote: string = "origin"  # Remote to push to (default: origin)
] {
    # 1. Environment Checks
    git_utils check-environment
    
    let mem_branch_name = (get-mem-branch-name)
    let mem_dir_name = (get-mem-dir-name)
    
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
        print $"⚠ No new commits to push to ($remote)/($mem_branch_name)"
        return
    }
    
    # 4. Show what will be pushed
    print $"Pushing ($commits_ahead) commit\(s\) to ($remote)/($mem_branch_name)..."
    
    # 5. Change to mem directory and push
    let git_root = (git_utils get-git-root)
    let mem_path = ($git_root | path join $mem_dir_name)
    
    cd $mem_path
    
    # Execute push with error handling
    let result = (do { git push $remote $mem_branch_name } | complete)
    
    if $result.exit_code != 0 {
        error make {
            msg: $"Failed to push to ($remote)"
            help: $result.stderr
        }
    }
    
    print $"✓ Successfully pushed to ($remote)/($mem_branch_name)"
}
