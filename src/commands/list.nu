# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# List artifact files

use ../lib/git_utils.nu
use ../lib/config load

export def main [
    --all(-a)              # List files for all branches
    --depth: int = 0       # Limit depth (default: 0 = unlimited)
    --json(-j)             # Output in JSON format
    --include-ignored(-i)  # Include gitignored tmp/ and ref/ files
] {
    # 1. Environment Checks
    let current_branch = git_utils check-environment
    let config = load
    
    # 2. Path Setup
    let git_root = git_utils get-git-root
    let mem_dir = $git_root | path join $config.dir_name

    cd $mem_dir
    
    mut fd_flags = ["--type", "f", "--hidden", "--exclude", ".git" ]

    if $include_ignored {
        $fd_flags = ($fd_flags | append [ "--no-ignore"])
    }

    let search_path = if $all { ["."] } else { ["." $current_branch] }

    let files = run-external "fd" ...$search_path ...$fd_flags 
    | lines
    | each {|p| parse-artifact-path $p $git_root } | compact
    
    # Apply depth filter if specified
    let depth_filtered = if $depth > 0 {
        $files | where depth <= $depth
    } else {
        $files
    }
    
    if ($depth_filtered | is-empty) {
        return
    }

    # Enrich with commit metadata
    cd $git_root  # Switch to main repo context
    
    let branches_to_query = if $all {
        $depth_filtered | get branch | uniq
    } else {
        [$current_branch]
    }
    
    let enriched = enrich-with-commit-data $depth_filtered $branches_to_query
    
    # 8. Output
    let output = $enriched | select path name branch category hash commit_hash commit_timestamp
    
    if $json {
        $output | to json
    } else {
        $output | get path | str join "\n"
    }
}

# Enrich files with commit metadata
def enrich-with-commit-data [
    files: list
    branches: list
] {
    # Get HEAD commits for branches (for root/ref files)
    let branch_heads = ($branches | each {|b|
        git_utils get-branch-head-info $b
    })
    
    # Collect files needing git queries (legacy trace/tmp or root/ref)
    let files_with_timestamp = ($files | where {|f|
        $f.category in ["trace", "tmp"] and $f.timestamp != null
    })
    
    let files_needing_query = ($files | where {|f|
        not ($f.category in ["trace", "tmp"] and $f.timestamp != null)
    })
    
    # Get explicit commits from files needing queries
    let explicit_hashes = ($files_needing_query | where hash != null | get hash | uniq)
    let commit_data = if ($explicit_hashes | is-empty) {
        []
    } else {
        git_utils get-commit-info-batch $explicit_hashes
    }
    
    # Process files with embedded timestamps (no git query needed)
    let enriched_with_ts = ($files_with_timestamp | each {|file|
        $file
        | insert commit_hash $file.hash
        | insert commit_timestamp $file.timestamp
    })
    
    # Process files needing git queries
    let enriched_needs_query = ($files_needing_query | each {|file|
        if $file.hash != null {
            # File has explicit commit (legacy trace/tmp)
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
    })
    
    # Combine results
    $enriched_with_ts | append $enriched_needs_query
}

# Get relative name relative to category directory
def get-relative-name [rel_path: string, category: string] {
    let components = $rel_path | path split
    let skip_count = match $category {
        "spec" | "ref" => 2
        "trace" | "tmp" => 3
    }
    $components | skip $skip_count | path join
}

# Parse artifact path to extract metadata
# Path format: <branch>/<category>/<hash?>/<file>
# Examples:
#   dev/trace/1738195200-abc123f/log.txt -> {branch: dev, category: trace, hash: abc123f, ...}
#   dev/ref/doc.md -> {branch: dev, category: ref, hash: null, ...}
#   dev/spec/plan.md -> {branch: dev, category: spec, hash: null, ...}
def parse-artifact-path [
    rel_path: string
    git_root: string
] {
    let parts = $rel_path | path split

    if ($parts | length) < 2 {
        return null
    }

    let branch = $parts | get 0
    let category = $parts | get 1

    # Validate category
    if $category not-in ["spec", "trace", "tmp", "ref"] {
        return null
    }

    # Determine hash and timestamp based on category
    let category_info = match $category {
        "spec" | "ref" => {
            category: $category
            hash: null
            timestamp: null
            depth: ($parts | length)
        }
        "trace" | "tmp" => {
            if ($parts | length) < 3 {
                return null
            }
            let hash_part = ($parts | get 2)

            # Parse timestamp-hash or legacy hash-only format
            let hash_info = if ($hash_part | str contains "-") {
                # New format: <timestamp>-<hash>
                let hash_parts = ($hash_part | split row "-")
                if ($hash_parts | length) >= 2 {
                    {
                        hash: ($hash_parts | get 1),
                        timestamp: ($hash_parts | get 0 | into int)
                    }
                } else {
                    # Malformed, treat as legacy
                    {hash: $hash_part, timestamp: null}
                }
            } else {
                # Legacy format: hash only
                {hash: $hash_part, timestamp: null}
            }

            {
                category: $category
                hash: $hash_info.hash
                timestamp: $hash_info.timestamp
                depth: ($parts | length)
            }
        }
    }

    let mem_dir_name = (load).dir_name

    {
        path: $"($mem_dir_name)/($rel_path)"
        name: (get-relative-name $rel_path $category)
        branch: $branch
        category: $category_info.category
        hash: $category_info.hash
        timestamp: $category_info.timestamp
        depth: $category_info.depth
    }
}
