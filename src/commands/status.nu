# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Show git status of mem directory

use ../lib/git_utils.nu
use ../lib/config load

export def main [] {
    # 1. Environment Checks
    git_utils check-environment
    
    # 2. Run git status in mem worktree
    let git_root = (git_utils get-git-root)
    let mem_path = ($git_root | path join (load).dir_name)
    
    cd $mem_path
    git status
}
