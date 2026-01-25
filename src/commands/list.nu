# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# List artifact files

use ../lib/git_utils.nu

export def main [
    --trace                # Include files in trace/ subdirectories
    --tmp                  # Include files in tmp/ subdirectories
    --ref                  # Include files in ref/ subdirectory
    --depth: int = 1       # Limit depth for ref/ (default: 1, 0 = unlimited)
] {
    # 1. Environment Checks
    if not (git_utils is-git-repo) {
        error make {msg: "Not in a git repository"}
    }
    
    if not (git_utils mem-dir-exists) {
        error make {msg: "Run 'mem init' first"}
    }
    
    let branch = (git_utils get-current-branch)
    if ($branch | is-empty) {
        error make {msg: "Not on a branch (detached HEAD)"}
    }
    
    # 2. Path Setup
    let git_root = (git_utils get-git-root)
    let base_dir = (git_utils get-mem-dir-for-branch $branch)
    
    if not ($base_dir | path exists) {
        return
    }

    mut files = []

    # 3. Root Files (always included)
    # Only files directly in base_dir
    let root_files = (glob $"($base_dir)/*" --no-dir)
    if not ($root_files | is-empty) {
        $files = ($files | append $root_files)
    }

    # 4. Trace Files
    if $trace {
        let trace_dir = ($base_dir | path join "trace")
        if ($trace_dir | path exists) {
            let trace_files = (glob $"($trace_dir)/**/*" --no-dir)
            if not ($trace_files | is-empty) {
                $files = ($files | append $trace_files)
            }
        }
    }

    # 5. Tmp Files
    if $tmp {
        let tmp_dir = ($base_dir | path join "tmp")
        if ($tmp_dir | path exists) {
            let tmp_files = (glob $"($tmp_dir)/**/*" --no-dir)
            if not ($tmp_files | is-empty) {
                $files = ($files | append $tmp_files)
            }
        }
    }

    # 6. Ref Files
    if $ref {
        let ref_dir = ($base_dir | path join "ref")
        if ($ref_dir | path exists) {
            # Handle depth: 0 = unlimited, >0 = limit depth
            let ref_files = if $depth == 0 {
                glob $"($ref_dir)/**/*" --no-dir
            } else {
                glob $"($ref_dir)/**/*" --depth $depth --no-dir
            }
            if not ($ref_files | is-empty) {
                $files = ($files | append $ref_files)
            }
        }
    }

    # 7. Output
    if not ($files | is-empty) {
        $files | path relative-to $git_root | sort | each { |it| print $it }
        return
    }
}
