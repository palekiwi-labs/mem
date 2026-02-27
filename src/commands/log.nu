# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Manage project log

use ../lib/git_utils.nu

export def add [
    --title: string              # Required: short description
    --found: string              # What was discovered (optional)
    --decided: string            # Decision made (optional)
    --open: string               # Open question (optional)
    --commit: string             # Override commit hash (optional)
] {
    # 1. Environment Checks
    let branch = (git_utils check-environment)
    
    # 2. Validation
    if $title == null or ($title | str trim | is-empty) {
        error make {msg: "--title is required"}
    }
    
    # Check if found or decided provided (at least one required)
    if ($found == null or ($found | str trim | is-empty)) and ($decided == null or ($decided | str trim | is-empty)) {
        error make {msg: "At least one of --found or --decided is required"}
    }
    
    # 3. Commit Hash Resolution
    let commit_hash = if $commit != null {
        validate-commit $commit
        $commit
    } else {
        git_utils get-current-commit-short
    }
    
    # 4. Path Construction
    let git_root = (git_utils get-git-root)
    let base_dir = (git_utils get-mem-dir-for-branch $branch)
    let log_path = ($base_dir | path join "spec" "log.md")
    
    # 5. Entry Formatting
    let entry = format-entry $commit_hash $title $found $decided $open
    
    # 6. File Operations
    ensure-log-file $log_path
    append-entry $log_path $entry
    
    # 7. Output
    let relative_path = ($log_path | path relative-to $git_root)
    print $"Added entry to ($relative_path)"
}

# Format a single log entry
def format-entry [
    commit_hash: string
    title: string
    found?: string
    decided?: string
    open?: string
] {
    mut lines = []
    
    # Header
    $lines = ($lines | append $"## [($commit_hash)] ($title)")
    
    # Found
    if $found != null and ($found | str trim | is-not-empty) {
        $lines = ($lines | append $"**Found:** ($found | str trim)")
    }
    
    # Decided
    if $decided != null and ($decided | str trim | is-not-empty) {
        $lines = ($lines | append $"**Decided:** ($decided | str trim)")
    }
    
    # Open
    if $open != null and ($open | str trim | is-not-empty) {
        $lines = ($lines | append $"**Open:** ($open | str trim)")
    }
    
    $lines | str join "\n"
}

# Initialize log.md if it doesn't exist
def ensure-log-file [log_path: string] {
    if not ($log_path | path exists) {
        mkdir ($log_path | path dirname)
        "# Project Log\n\n" | save $log_path
    }
}

# Append entry to log file with proper spacing
def append-entry [log_path: string, entry: string] {
    let current_content = (open $log_path)
    let needs_separator = ($current_content | str trim | is-not-empty) and not ($current_content | str ends-with "\n\n")
    
    let content_to_append = if $needs_separator {
        $"\n($entry)\n"
    } else {
        $"($entry)\n"
    }
    
    $content_to_append | save --append $log_path
}

# Validate commit hash exists
def validate-commit [hash: string] {
    let result = (git rev-parse --verify $hash | complete)
    if $result.exit_code != 0 {
        error make {msg: $"Invalid commit hash: ($hash)"}
    }
}

# List all log entries
export def list [
    --branch(-b): string         # List entries for a specific branch
] {
    # 1. Environment Checks
    let current_branch = (git_utils check-environment)
    let target_branch = if $branch != null { $branch } else { $current_branch }
    
    # 2. Path Construction
    let base_dir = (git_utils get-mem-dir-for-branch $target_branch)
    let log_path = ($base_dir | path join "spec" "log.md")
    
    # 3. Check if log file exists
    if not ($log_path | path exists) {
        let msg = if $branch != null {
            $"No log entries for branch '($branch)'."
        } else {
            "No log entries. Use 'mem log add' to create entries."
        }
        error make {msg: $msg}
    }
    
    # 4. Print file content
    open $log_path | print
}
