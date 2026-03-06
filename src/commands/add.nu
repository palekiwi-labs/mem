# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

use ../lib/git_utils.nu

# Add a new artifact file to the agent's storage
#
# Artifacts are categorized into directories within the branch-specific storage:
# - spec/ (default): Project specifications, requirements, and design docs.
# - trace/: Execution traces, step-by-step logs of agent activity.
# - tmp/: Temporary files, intermediate thoughts, or scratchpad data.
# - ref/: Static reference materials, documentation, or code snippets.
# - bin/: Executables, scripts, or binary artifacts.
export def main [
    filename: string       # Name of file to create (e.g., 'plan.md')
    content?: string       # Optional string content to write to the file
    --trace                # Save to trace/ subdirectory (uses commit hash and timestamp)
    --tmp                  # Save to tmp/ subdirectory (uses commit hash and timestamp)
    --ref                  # Save to ref/ directory
    --bin                  # Save to bin/ directory
    --commit: string       # Specify commit hash for trace/tmp (defaults to HEAD)
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
        let timestamp = if ($commit != null) {
            git_utils get-commit-timestamp $commit
        } else {
            git_utils get-current-commit-timestamp
        }
        let dir_name = $"($timestamp)-($hash)"
        $base_dir | path join "trace" $dir_name
    } else if $tmp {
        let hash = if ($commit != null) { $commit } else { git_utils get-current-commit-short }
        let timestamp = if ($commit != null) {
            git_utils get-commit-timestamp $commit
        } else {
            git_utils get-current-commit-timestamp
        }
        let dir_name = $"($timestamp)-($hash)"
        $base_dir | path join "tmp" $dir_name
    } else if $ref {
        $base_dir | path join "ref"
    } else if $bin {
        $base_dir | path join "bin"
    } else {
        $base_dir | path join "spec"
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
