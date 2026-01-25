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
    $files = ($files | append (scan-dir $base_dir "*" "root" false 0))

    # 4. Trace Files
    if ($trace or $all) {
        let trace_dir = ($base_dir | path join "trace")
        $files = ($files | append (scan-dir $trace_dir "**/*" "trace" true 0))
    }

    # 5. Tmp Files
    if ($tmp or $all) {
        let tmp_dir = ($base_dir | path join "tmp")
        $files = ($files | append (scan-dir $tmp_dir "**/*" "tmp" true 0))
    }

    # 6. Ref Files
    if ($ref or $all) {
        let ref_dir = ($base_dir | path join "ref")
        $files = ($files | append (scan-dir $ref_dir "**/*" "ref" false $depth))
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

# Helper to glob and process files
def scan-dir [
    dir: string
    pattern: string
    category: string
    extract_hash: bool
    max_depth: int # 0 for unlimited
] {
    if not ($dir | path exists) {
        return []
    }

    let paths = if $max_depth > 0 {
        glob ($dir | path join $pattern) --depth $max_depth --no-dir
    } else {
        glob ($dir | path join $pattern) --no-dir
    }
    
    if ($paths | is-empty) {
        return []
    }
    
    ls ...$paths | each {|f|
        let hash = if $extract_hash {
            let relative = ($f.name | path relative-to $dir)
            let parts = ($relative | path split)
            if ($parts | length) > 1 { $parts | first } else { null }
        } else {
            null
        }
        
        $f | insert category $category | insert hash $hash
    }
}
