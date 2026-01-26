# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Prune temporary and reference files

use ../lib/git_utils.nu

# Get list of all branch directories in .agents/
def get-all-branch-dirs [] {
    let git_root = (git_utils get-git-root)
    let mem_dir = ($git_root | path join (git_utils get-mem-dir-name))
    
    if not ($mem_dir | path exists) {
        return []
    }
    
    ls $mem_dir 
    | where type == dir 
    | where name != ".git"
    | get name 
    | path basename
}

# Prompt user for confirmation
def confirm-deletion [message: string] {
    print $message
    let response = (input "")
    $response in ["y", "Y", "yes", "Yes", "YES"]
}

# Delete tmp/ and ref/ for a given branch
def delete-branch-artifacts [branch: string, git_root: string] {
    let branch_dir = (git_utils get-mem-dir-for-branch $branch)
    mut deleted = []
    
    for subdir in ["tmp", "ref"] {
        let target = ($branch_dir | path join $subdir)
        if ($target | path exists) {
            try {
                rm -rf $target
                $deleted = ($deleted | append ($target | path relative-to $git_root))
            } catch { |err|
                # Continue on error, but could log it
                # For now, silently continue
            }
        }
    }
    
    $deleted
}

export def main [
    --all(-a)              # Delete for all branches
    --force(-f)            # Skip confirmation
] {
    # 1. Environment Checks
    let current_branch = (git_utils check-environment)
    let git_root = (git_utils get-git-root)
    
    # 2. Determine Target Branches
    let branches = if $all {
        get-all-branch-dirs
    } else {
        [$current_branch]
    }
    
    if ($branches | is-empty) {
        return
    }
    
    # 3. Confirmation Prompt (unless --force)
    if not $force {
        let message = if $all {
            "Delete tmp/ and ref/ for ALL branches? This cannot be undone. [y/N]"
        } else {
            $"Delete tmp/ and ref/ for branch '($current_branch)'? [y/N]"
        }
        
        if not (confirm-deletion $message) {
            print "Aborted"
            return
        }
    }
    
    # 4. Delete artifacts for each branch
    mut all_deleted = []
    for branch in $branches {
        let deleted = (delete-branch-artifacts $branch $git_root)
        $all_deleted = ($all_deleted | append $deleted)
    }
    
    # 5. Output results
    if ($all_deleted | is-empty) {
        print "Nothing to delete"
    } else {
        for path in $all_deleted {
            print $"Deleted: ($path)"
        }
    }
}
