# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# List artifact files

use ../lib/git_utils.nu

export def main [
    --all(-a)              # List files for all branches
    --depth: int = 0       # Limit depth (default: 0 = unlimited)
    --json(-j)             # Output in JSON format
] {
    # 1. Environment Checks
    let current_branch = (git_utils check-environment)
    
    # 2. Path Setup
    let git_root = (git_utils get-git-root)
    let mem_dir = ($git_root | path join (git_utils get-mem-dir-name))
    
    if not ($mem_dir | path exists) {
        return
    }

    # 3. Get files from git
    cd $mem_dir
    
    let tracked = (git ls-files | lines)
    let untracked = (git ls-files --others --exclude-standard | lines)
    let all_paths = ($tracked | append $untracked)
    
    if ($all_paths | is-empty) {
        return
    }

    # 4. Parse and filter paths
    let files = ($all_paths | each {|p|
        parse-artifact-path $p $git_root
    } | compact)
    
    # 5. Filter by branch if not --all
    let filtered = if $all {
        $files
    } else {
        $files | where branch == $current_branch
    }
    
    # 6. Apply depth filter if specified
    let result = if $depth > 0 {
        $filtered | where depth <= $depth
    } else {
        $filtered
    }
    
    if ($result | is-empty) {
        return
    }

    # 7. Output
    let output = ($result | select path name branch category hash)
    
    if $json {
        $output | to json
    } else {
        $output | get path
    }
}

# Parse artifact path to extract metadata
# Path format: <branch>/<category>/<hash?>/<file>
# Examples:
#   dev/trace/abc123/log.txt -> {branch: dev, category: trace, hash: abc123, ...}
#   dev/ref/doc.md -> {branch: dev, category: ref, hash: null, ...}
#   dev/plan.md -> {branch: dev, category: root, hash: null, ...}
def parse-artifact-path [
    rel_path: string
    git_root: string
] {
    let parts = ($rel_path | path split)
    
    if ($parts | length) < 2 {
        return null
    }
    
    let branch = ($parts | first)
    let rest = ($parts | skip 1)
    
    # Determine category and hash
    let category_info = if ($rest | length) == 1 {
        # Root file: dev/plan.md
        {category: "root", hash: null, depth: 1}
    } else {
        let first_component = ($rest | first)
        if $first_component in ["trace", "tmp", "ref"] {
            # Categorized file
            if ($rest | length) == 2 {
                # No hash: dev/ref/doc.md
                {category: $first_component, hash: null, depth: 2}
            } else {
                # With hash: dev/trace/abc123/log.txt
                {category: $first_component, hash: ($rest | get 1), depth: ($rest | length)}
            }
        } else {
            # Unknown structure, treat as root
            {category: "root", hash: null, depth: ($rest | length)}
        }
    }
    
    let full_path = ($git_root | path join ".mem" $rel_path)
    
    {
        path: $".mem/($rel_path)"
        name: ($rel_path | path basename)
        branch: $branch
        category: $category_info.category
        hash: $category_info.hash
        depth: $category_info.depth
    }
}
