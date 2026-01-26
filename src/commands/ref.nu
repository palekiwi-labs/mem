# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Manage reference materials

use ../lib/git_utils.nu

# Add a reference by cloning a git repository or copying a file/directory
export def add [
    source: string         # Source identifier (github:org/repo, path:/file/path)
    --force(-f)            # Overwrite existing reference
    --depth: int           # Shallow clone depth for git repositories
] {
    # 1. Environment Checks
    let branch = (git_utils check-environment)
    
    # 2. Parse source
    let source_parts = ($source | parse "{type}:{location}")
    
    if ($source_parts | is-empty) {
        error make {msg: "Invalid source format. Expected github:<org>/<repo> or path:<filepath>"}
    }
    
    let source_type = ($source_parts | first | get type)
    let source_location = ($source_parts | first | get location)
    
    # 3. Path Construction
    let git_root = (git_utils get-git-root)
    let base_dir = (git_utils get-mem-dir-for-branch $branch)
    let ref_dir = ($base_dir | path join "ref")
    
    # 4. Handle different source types
    if $source_type == "github" {
        handle-github $source_location $ref_dir $git_root $force $depth
    } else if $source_type == "path" {
        handle-path $source_location $ref_dir $git_root $force
    } else {
        error make {msg: $"Unsupported source type: ($source_type). Use 'github:' or 'path:'"}
    }
}

# Handle GitHub repository cloning
def handle-github [
    location: string       # org/repo or org/repo/branch or org/repo@commit
    ref_dir: string        # Base ref directory
    git_root: string       # Git root for relative paths
    force: bool            # Overwrite existing reference
    depth?: int            # Shallow clone depth (optional)
] {
    # Parse location (org/repo, org/repo/branch, org/repo@commit)
    let has_commit = ($location | str contains "@")
    let has_branch = ($location | str contains "/") and (($location | split row "/" | length) > 2)
    
    let parts = if $has_commit {
        let split = ($location | split row "@")
        {
            repo_path: ($split | first),
            commit: ($split | last)
        }
    } else if $has_branch {
        let split = ($location | split row "/")
        {
            repo_path: ($split | first 2 | str join "/"),
            branch: ($split | skip 2 | str join "/")
        }
    } else {
        {
            repo_path: $location
        }
    }
    
    # Extract org and repo name
    let repo_parts = ($parts.repo_path | split row "/")
    if ($repo_parts | length) != 2 {
        error make {msg: "Invalid GitHub path. Expected org/repo format"}
    }
    
    let org = ($repo_parts | first)
    let repo = ($repo_parts | last)
    let target_name = $"($org)-($repo)"
    let target_path = ($ref_dir | path join $target_name)
    
    # Check if already exists
    if ($target_path | path exists) {
        if $force {
            rm -rf $target_path
        } else {
            error make {msg: $"Reference already exists: ref/($target_name)/"}
        }
    }
    
    # Create ref directory if needed
    mkdir $ref_dir
    
    # Clone repository
    print $"Cloning github:($location)..."
    
    let clone_url = $"https://github.com/($parts.repo_path).git"
    
    # Build clone command with optional depth
    let depth_args = if $depth == null {
        []
    } else {
        ["--depth" ($depth | into string)]
    }
    
    if "branch" in $parts {
        run-external "git" "clone" ...$depth_args "-b" $parts.branch $clone_url $target_path
    } else {
        run-external "git" "clone" ...$depth_args $clone_url $target_path
        if "commit" in $parts {
            cd $target_path
            run-external "git" "checkout" $parts.commit
        }
    }
    
    let relative_path = ($target_path | path relative-to $git_root)
    print $"Created: ($relative_path)/"
}

# Handle local file/directory copying
def handle-path [
    location: string       # File or directory path
    ref_dir: string        # Base ref directory
    git_root: string       # Git root for relative paths
    force: bool            # Overwrite existing reference
] {
    # Get basename from original location (before expansion to avoid Nix store hashes)
    let target_name = ($location | path basename)
    
    # Expand ~ to home directory and resolve absolute path for operations
    let expanded_path = ($location | path expand)
    
    # Check if source exists
    if not ($expanded_path | path exists) {
        error make {msg: $"Source not found: ($expanded_path)"}
    }
    let target_path = ($ref_dir | path join $target_name)
    
    # Check if already exists
    if ($target_path | path exists) {
        if $force {
            rm -rf $target_path
        } else {
            error make {msg: $"Reference already exists: ref/($target_name)"}
        }
    }
    
    # Create ref directory if needed
    mkdir $ref_dir
    
    # Copy file or directory
    print $"Copying path:($location)..."
    
    if ($expanded_path | path type) == "dir" {
        cp -r $expanded_path $target_path
    } else {
        cp $expanded_path $target_path
    }
    
    let relative_path = ($target_path | path relative-to $git_root)
    print $"Created: ($relative_path)"
}
