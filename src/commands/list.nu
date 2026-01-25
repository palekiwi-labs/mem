# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# List artifact files

use ../lib/git_utils.nu

export def main [
    --trace                # Include files in trace/ subdirectories
    --tmp                  # Include files in tmp/ subdirectories
    --ref                  # Include files in ref/ subdirectory
    --all(-a)              # Include all artifacts (trace, tmp, ref)
    --depth: int = 1       # Limit depth for ref/ (default: 1, 0 = unlimited)
    --json(-j)             # Output in JSON format
] {
    # 1. Environment Checks
    let branch = (git_utils check-environment)
    
    # 2. Path Setup
    let git_root = (git_utils get-git-root)
    let base_dir = (git_utils get-mem-dir-for-branch $branch)
    
    if not ($base_dir | path exists) {
        return
    }

    mut files = []

    # 3. Root Files (always included)
    # Only files directly in base_dir
    let root_paths = (glob $"($base_dir)/*" --no-dir)
    let root_ls = if ($root_paths | is-empty) { [] } else { ls ...$root_paths }
    
    if not ($root_ls | is-empty) {
        $files = ($files | append ($root_ls | insert category "root" | insert hash null))
    }

    # 4. Trace Files
    if ($trace or $all) {
        let trace_dir = ($base_dir | path join "trace")
        if ($trace_dir | path exists) {
            let trace_paths = (glob $"($trace_dir)/**/*" --no-dir)
            let trace_ls = if ($trace_paths | is-empty) { [] } else { ls ...$trace_paths }
            
            if not ($trace_ls | is-empty) {
                # Extract hash from path: .../trace/<hash>/filename
                let processed = ($trace_ls | each {|f| 
                    let relative = ($f.name | path relative-to $trace_dir)
                    let components = ($relative | path split)
                    let hash = if ($components | length) > 1 { $components | first } else { null }
                    
                    $f | insert category "trace" | insert hash $hash
                })
                $files = ($files | append $processed)
            }
        }
    }

    # 5. Tmp Files
    if ($tmp or $all) {
        let tmp_dir = ($base_dir | path join "tmp")
        if ($tmp_dir | path exists) {
            let tmp_paths = (glob $"($tmp_dir)/**/*" --no-dir)
            let tmp_ls = if ($tmp_paths | is-empty) { [] } else { ls ...$tmp_paths }
            
            if not ($tmp_ls | is-empty) {
                let processed = ($tmp_ls | each {|f| 
                    let relative = ($f.name | path relative-to $tmp_dir)
                    let components = ($relative | path split)
                    let hash = if ($components | length) > 1 { $components | first } else { null }
                    
                    $f | insert category "tmp" | insert hash $hash
                })
                $files = ($files | append $processed)
            }
        }
    }

    # 6. Ref Files
    if ($ref or $all) {
        let ref_dir = ($base_dir | path join "ref")
        if ($ref_dir | path exists) {
            # Handle depth logic using glob
            let ref_paths = if $depth == 0 {
                glob $"($ref_dir)/**/*" --no-dir
            } else {
                glob $"($ref_dir)/**/*" --depth $depth --no-dir
            }
            
            let ref_ls = if ($ref_paths | is-empty) { [] } else { ls ...$ref_paths }
            
            if not ($ref_ls | is-empty) {
                $files = ($files | append ($ref_ls | insert category "ref" | insert hash null))
            }
        }
    }

    # 7. Output
    if ($files | is-empty) {
        return
    }

    # Common post-processing
    let result = ($files | each {|f|
        let rel_path = ($f.name | path relative-to $git_root)
        {
            path: $rel_path
            name: ($f.name | path basename)
            category: $f.category
            hash: $f.hash
            branch: $branch
            size: $f.size
            modified: $f.modified
            modified_ts: ($f.modified | into int)
        }
    } | sort-by modified -r)

    if $json {
        $result | to json
    } else {
        $result | get path | each { |it| print $it }
    }
}
