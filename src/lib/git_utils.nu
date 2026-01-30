# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Git helper functions for mem

use ../lib/config load

export def is-git-repo [] {
    (do { git rev-parse --git-dir } | complete).exit_code == 0
}

export def get-git-root [] {
    git rev-parse --show-toplevel | str trim
}

export def mem-dir-exists [] {
    let git_root = get-git-root
    let mem_path = ($git_root | path join (load).dir_name)
    $mem_path | path exists
}

export def mem-branch-exists [] {
    (do { git rev-parse --verify (load).branch_name } | complete).exit_code == 0
}

export def mem-branch-exists-on-remote [remote: string = "origin"] {
    (do { git ls-remote --heads $remote (load).branch_name } | complete).stdout | str trim | is-not-empty
}

export def ensure-worktree [] {
    let git_root = get-git-root
    let config = (load)
    let mem_dir_name = $config.dir_name
    let mem_branch_name = $config.branch_name
    let mem_path = ($git_root | path join $mem_dir_name)
    
    if ($mem_path | path exists) {
        error make {msg: $"($mem_dir_name) directory already exists at ($mem_path)"}
    }
    
    if (mem-branch-exists) {
        # Case 1: Local branch exists - attach it
        git worktree add $mem_path $mem_branch_name
    } else if (mem-branch-exists-on-remote) {
        # Case 2: Branch exists on remote but not locally - fetch and checkout
        print $"Found ($mem_branch_name) branch on remote, fetching..."
        git fetch origin $"($mem_branch_name):($mem_branch_name)"
        git worktree add $mem_path $mem_branch_name
    } else {
        # Case 3: Branch doesn't exist anywhere - create new orphan branch
        git worktree add --orphan -b $mem_branch_name $mem_path
        
        # Change to worktree directory to create initial commit
        cd $mem_path
        
        # Create initial commit with .gitignore
        let gitignore_content = "*/tmp/\n*/ref/\n"
        $gitignore_content | save --force .gitignore
        
        git add .gitignore
        git commit -m $"Initialize ($mem_branch_name) branch"
    }
}

# Check if worktree exists at agent artifacts directory
export def worktree-exists [] {
    let git_root = get-git-root
    let mem_path = ($git_root | path join (load).dir_name)
    let worktrees = (git worktree list --porcelain | parse "{key} {value}")
    
    $worktrees | any {|w| $w.key == "worktree" and ($w.value | str trim) == $mem_path}
}

export def get-current-branch [] {
    # Returns empty string if detached head
    (do { git branch --show-current } | complete).stdout | str trim
}

export def get-current-commit-short [] {
    git rev-parse --short HEAD | str trim
}

export def get-current-commit-timestamp [] {
    git log -1 --format='%ct' HEAD | str trim | into int
}

export def get-commit-timestamp [hash: string] {
    let result = (git log -1 --format='%ct' $hash | complete)
    if $result.exit_code == 0 {
        $result.stdout | str trim | into int
    } else {
        error make {msg: $"Failed to get timestamp for commit ($hash)"}
    }
}

export def sanitize-branch-name [name: string] {
    $name | str replace --all "/" "-"
}

export def get-mem-dir-for-branch [branch: string] {
    let git_root = get-git-root
    let sanitized = (sanitize-branch-name $branch)
    $git_root | path join (load).dir_name $sanitized
}

export def check-environment [] {
    if not (is-git-repo) {
        error make {msg: "Not in a git repository"}
    }
    
    if not (mem-dir-exists) {
        error make {msg: "Run 'mem init' first"}
    }
    
    let branch = (get-current-branch)
    if ($branch | is-empty) {
        error make {msg: "Not on a branch (detached HEAD)"}
    }
    
    $branch
}



# Check if remote exists
export def remote-exists [remote: string = "origin"] {
    (do { git remote get-url $remote } | complete).exit_code == 0
}

# Check if there are uncommitted changes in mem worktree
export def has-uncommitted-changes [] {
    let git_root = get-git-root
    let mem_path = ($git_root | path join (load).dir_name)
    
    cd $mem_path
    let status = (git status --porcelain | str trim)
    not ($status | is-empty)
}

# Check if local branch is ahead of remote
export def is-ahead-of-remote [remote: string = "origin"] {
    let mem_branch_name = (load).branch_name
    let result = (do { 
        git rev-list --count $"($remote)/($mem_branch_name)..($mem_branch_name)" 
    } | complete)
    
    if $result.exit_code != 0 {
        return null
    }
    
    ($result.stdout | str trim | into int) > 0
}

# Check if local branch is behind remote
export def is-behind-remote [remote: string = "origin"] {
    let mem_branch_name = (load).branch_name
    let result = (do { 
        git rev-list --count $"($mem_branch_name)..($remote)/($mem_branch_name)" 
    } | complete)
    
    if $result.exit_code != 0 {
        return null
    }
    
    ($result.stdout | str trim | into int) > 0
}

# Get commit count ahead of remote
export def get-commits-ahead [remote: string = "origin"] {
    let mem_branch_name = (load).branch_name
    let result = (do { 
        git rev-list --count $"($remote)/($mem_branch_name)..($mem_branch_name)" 
    } | complete)
    
    if $result.exit_code == 0 {
        $result.stdout | str trim | into int
    } else {
        0
    }
}

# Get HEAD commit info for a branch (from main repo context)
export def get-branch-head-info [branch: string] {
    # Try local branch first
    let local_result = (git log -1 --format='%h|%ct' $branch | complete)
    
    if $local_result.exit_code == 0 {
        let parts = ($local_result.stdout | str trim | split column '|' hash timestamp)
        if ($parts | length) > 0 {
            let row = ($parts | first)
            return {
                branch: $branch, 
                hash: $row.hash, 
                timestamp: ($row.timestamp | into int)
            }
        }
    }
    
    # Try origin/{branch} if local doesn't exist
    let remote_result = (git log -1 --format='%h|%ct' $"origin/($branch)" | complete)
    
    if $remote_result.exit_code == 0 {
        let parts = ($remote_result.stdout | str trim | split column '|' hash timestamp)
        if ($parts | length) > 0 {
            let row = ($parts | first)
            return {
                branch: $branch,
                hash: $row.hash,
                timestamp: ($row.timestamp | into int)
            }
        }
    }
    
    # Branch not found
    {
        branch: $branch,
        hash: null,
        timestamp: 0
    }
}

# Batch query for commit info (from main repo context)
export def get-commit-info-batch [hashes: list] {
    if ($hashes | is-empty) {
        return []
    }
    
    # Use git cat-file --batch-check for efficient targeted commit lookups
    # This only queries the specific commits we need instead of scanning all history
    let batch_input = ($hashes | str join "\n")
    
    let cat_result = ($batch_input | git cat-file --batch-check | complete)
    
    if $cat_result.exit_code != 0 {
        return []
    }
    
    # Parse output: <full-hash> <type> <size>
    # Filter to only valid commits and get their timestamps
    $cat_result.stdout
    | lines
    | parse "{full_hash} {type} {size}"
    | where type == "commit"
    | each {|row|
        # Get short hash and timestamp
        let short_hash = ($row.full_hash | str substring 0..6)
        let ts_result = (git log -1 --format='%ct' $row.full_hash | complete)
        let timestamp = if $ts_result.exit_code == 0 {
            $ts_result.stdout | str trim | into int
        } else {
            0
        }
        {
            hash: $short_hash,
            timestamp: $timestamp
        }
    }
}
