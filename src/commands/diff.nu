# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Show git diff of changes in mem directory

use ../lib/git_utils.nu
use ../lib/config load

export def main [
    path?: string              # Optional path to specific file or directory
] {
    # 1. Environment Checks
    git_utils check-environment
    
    # 2. Run git diff in mem worktree
    let git_root = (git_utils get-git-root)
    let mem_path = ($git_root | path join (load).dir_name)
    
    cd $mem_path
    
    # 3. Run git diff with optional path
    if $path == null {
        git diff
    } else {
        git diff $path
    }
}
