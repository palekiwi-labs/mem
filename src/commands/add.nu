# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Add a new artifact file

use ../lib/git_utils.nu

export def main [
    filename: string       # Name of file to create
    content?: string       # Content to write to file
    --trace                # Save to trace/ directory
    --tmp                  # Save to tmp/ directory
    --ref                  # Save to ref/ directory
    --commit: string       # Specify commit hash (requires --trace or --tmp)
    --force(-f)            # Overwrite existing file
] {
    # 1. Environment Checks
    let branch = (git_utils check-environment)
    
    # 2. Argument Validation
    if ($commit != null) and not ($trace or $tmp) {
        error make {msg: "--commit requires --trace or --tmp"}
    }
    
    # 3. Path Construction
    let git_root = (git_utils get-git-root)
    let base_dir = (git_utils get-mem-dir-for-branch $branch)
    
    let target_dir = if $trace {
        let hash = if ($commit != null) { $commit } else { git_utils get-current-commit-short }
        $base_dir | path join "trace" $hash
    } else if $tmp {
        let hash = if ($commit != null) { $commit } else { git_utils get-current-commit-short }
        $base_dir | path join "tmp" $hash
    } else if $ref {
        $base_dir | path join "ref"
    } else {
        $base_dir
    }
    
    let target_path = ($target_dir | path join $filename)
    let relative_path = ($target_path | path relative-to $git_root)
    
    # 4. File Operation
    if ($target_path | path exists) and not $force {
        error make {msg: $"File exists: ($relative_path). Use --force to overwrite."}
    }
    
    # Ensure parent directory exists
    mkdir ($target_path | path dirname)
    
    if ($content | is-empty) {
        touch $target_path
    } else {
        $content | save --force $target_path
    }
    
    print $relative_path
}
