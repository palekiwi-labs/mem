# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# List artifact files

use ../lib/git_utils.nu
use ../config.nu [MEM_DIR_NAME]

export def main [
    --all(-a)              # List files for all branches
    --depth: int = 0       # Limit depth (default: 0 = unlimited)
    --json(-j)             # Output in JSON format
    --include-ignored(-i)  # Include gitignored tmp/ and ref/ files
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
    
    # Optionally include gitignored files
    let ignored = if $include_ignored {
        discover-ignored-files $mem_dir
    } else {
        []
    }
    
    let all_paths = ($tracked | append $untracked | append $ignored | uniq)
    
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
    let depth_filtered = if $depth > 0 {
        $filtered | where depth <= $depth
    } else {
        $filtered
    }
    
    if ($depth_filtered | is-empty) {
        return
    }

    # 7. Enrich with commit metadata
    cd $git_root  # Switch to main repo context
    
    let branches_to_query = if $all {
        $depth_filtered | get branch | uniq
    } else {
        [$current_branch]
    }
    
    let enriched = (enrich-with-commit-data $depth_filtered $branches_to_query)
    
    # 8. Output
    let output = ($enriched | select path name branch category hash commit_hash commit_timestamp depth)
    
    if $json {
        $output | to json
    } else {
        $output | get path | str join "\n"
    }
}

# Discover gitignored files (tmp/ and ref/), excluding cloned repos in ref/repos/
def discover-ignored-files [mem_dir: string] {
    cd $mem_dir
    
    # Find all files in */tmp/
    let tmp_result = (do { ^find . -path '*/tmp/*' -type f } | complete)
    let tmp_files = if $tmp_result.exit_code == 0 {
        $tmp_result.stdout | lines | each {|line| $line | str replace --regex '^\./' '' } | where {|line| $line != ""}
    } else {
        []
    }
    
    # Find all files in */ref/ but exclude those in repos/ subdirectory
    let ref_result = (do { ^find . -path '*/ref/*' -not -path '*/ref/repos/*' -type f } | complete)
    let ref_files = if $ref_result.exit_code == 0 {
        $ref_result.stdout 
        | lines 
        | each {|line| $line | str replace --regex '^\./' '' }
        | where {|line| $line != ""}
    } else {
        []
    }
    
    $tmp_files | append $ref_files
}

# Enrich files with commit metadata
def enrich-with-commit-data [
    files: list
    branches: list
] {
    # 1. Get HEAD commits for branches
    let branch_heads = ($branches | each {|b|
        git_utils get-branch-head-info $b
    })
    
    # 2. Get explicit commits from trace/tmp
    let explicit_hashes = ($files | where hash != null | get hash | uniq)
    let commit_data = if ($explicit_hashes | is-empty) {
        []
    } else {
        git_utils get-commit-info-batch $explicit_hashes
    }
    
    # 3. Enrich each file
    $files | each {|file|
        if $file.hash != null {
            # File has explicit commit (trace/tmp)
            let matches = ($commit_data | where hash == $file.hash)
            if ($matches | length) > 0 {
                let info = ($matches | first)
                $file 
                | insert commit_hash $info.hash
                | insert commit_timestamp $info.timestamp
            } else {
                $file
                | insert commit_hash $file.hash
                | insert commit_timestamp 0
            }
        } else {
            # File has no explicit commit (root/ref) - use branch HEAD
            let matches = ($branch_heads | where branch == $file.branch)
            if ($matches | length) > 0 {
                let branch_info = ($matches | first)
                $file
                | insert commit_hash $branch_info.hash
                | insert commit_timestamp $branch_info.timestamp
            } else {
                $file
                | insert commit_hash null
                | insert commit_timestamp 0
            }
        }
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
    
    let full_path = ($git_root | path join $MEM_DIR_NAME $rel_path)
    
    {
        path: $"($MEM_DIR_NAME)/($rel_path)"
        name: ($rel_path | path basename)
        branch: $branch
        category: $category_info.category
        hash: $category_info.hash
        depth: $category_info.depth
    }
}
