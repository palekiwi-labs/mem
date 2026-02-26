#!/usr/bin/env nu
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# mem - CLI tool for managing AI agent artifacts in git repositories

use commands/add.nu
use commands/config.nu
use commands/diff.nu
use commands/init.nu
use commands/list.nu
use commands/log.nu
use commands/prune.nu
use commands/pull.nu
use commands/push.nu
use commands/ref.nu
use commands/status.nu
use errors.nu

# Initialize agent artifacts directory structure
def "main init" [] {
    try {
        init
    } catch { |err|
        errors pretty-print $err
    }
}

# Create a new artifact file
def "main add" [
    filename: string       # Name of file to create
    content?: string       # Content to write to file
    --trace                # Save to trace/ directory
    --tmp                  # Save to tmp/ directory
    --ref                  # Save to ref/ directory
    --bin                  # Save to bin/ directory
    --commit: string       # Specify commit hash (requires --trace or --tmp)
    --force(-f)            # Overwrite existing file
] {
    try {
        add $filename $content --trace=$trace --tmp=$tmp --ref=$ref --bin=$bin --commit=$commit --force=$force
    } catch { |err|
        errors pretty-print $err
    }
}

# List artifact files
def "main list" [
    --all(-a)              # List files for all branches
    --depth: int = 0       # Limit depth (default: 0 = unlimited)
    --json(-j)             # Output in JSON format
    --include-ignored(-i)  # Include gitignored tmp/ and ref/ files
] {
    try {
        list --all=$all --depth=$depth --json=$json --include-ignored=$include_ignored
    } catch { |err|
        errors pretty-print $err
    }
}

# Show git status of mem directory
def "main status" [] {
    try {
        status
    } catch { |err|
        errors pretty-print $err
    }
}

# Show git diff of changes in mem directory
def "main diff" [
    path?: string              # Optional path to specific file or directory
] {
    try {
        diff $path
    } catch { |err|
        errors pretty-print $err
    }
}

# Push mem branch to remote
def "main push" [
    --remote: string = "origin"  # Remote to push to
] {
    try {
        push --remote=$remote
    } catch { |err|
        errors pretty-print $err
    }
}

# Pull mem branch from remote
def "main pull" [
    --remote: string = "origin"  # Remote to pull from
] {
    try {
        pull --remote=$remote
    } catch { |err|
        errors pretty-print $err
    }
}

# Manage reference materials
def "main ref" [] {
    print "Usage: mem ref add <source> [OPTIONS]
    
Add reference materials to .mem/<branch>/ref/

SOURCES:
    github:<org>/<repo>           Clone GitHub repo (default branch)
    github:<org>/<repo>/<branch>  Clone specific branch
    github:<org>/<repo>@<commit>  Clone at specific commit
    path:<filepath>               Copy local file or directory

OPTIONS:
    --ssh                         Use SSH protocol (git@github.com:org/repo.git)
    --depth <N>                   Shallow clone with specified depth
    --force, -f                   Overwrite existing reference

EXAMPLES:
    mem ref add github:octocat/hello-world
    mem ref add github:palekiwi/mem/develop
    mem ref add github:org/repo@abc123d
    mem ref add github:myorg/private-repo --ssh
    mem ref add path:/etc/config.yaml
    mem ref add path:~/Documents/api-docs/
"
}

# Add a reference
def "main ref add" [
    source: string         # Source identifier (github:org/repo, path:/file/path)
    --force(-f)            # Overwrite existing reference
    --depth: int           # Shallow clone depth for git repositories
    --ssh                  # Use SSH protocol for GitHub repos
] {
    try {
        ref add $source --force=$force --depth=$depth --ssh=$ssh
    } catch { |err|
        errors pretty-print $err
    }
}

# Delete temporary and reference files (cleanup)
def "main prune" [
    --all(-a)              # Delete for all branches
    --force(-f)            # Skip confirmation
] {
    try {
        prune --all=$all --force=$force
    } catch { |err|
        errors pretty-print $err
    }
}

# Manage project log
def "main log" [] {
    print "mem log - Manage project log

USAGE:
    mem log add [OPTIONS]

SUBCOMMANDS:
    add        Add an entry to the project log

OPTIONS:
    --title <string>         Short description (required)
    --found <string>         What was discovered
    --decided <string>       Decision made
    --open <string>          Open question
    --commit <hash>          Override commit hash (default: current HEAD)

EXAMPLES:
    # Simple entry
    mem log add --title \"Fixed parser bug\" \\
      --found \"Null pointer in edge case.\" \\
      --decided \"Added null check.\"

    # With open questions
    mem log add --title \"Performance investigation\" \\
      --found \"Query takes 2s on large datasets.\" \\
      --decided \"Add caching layer.\" \\
      --open \"Need benchmark suite?\"

    # Custom commit
    mem log add --title \"Bug analysis\" \\
      --found \"Root cause identified.\" \\
      --decided \"Apply hotfix.\" \\
      --commit abc1234

For more information, see: https://github.com/palekiwi-labs/mem
"
}

# Add a log entry
def "main log add" [
    --title: string              # Short description (required)
    --found: string              # What was discovered
    --decided: string            # Newline-separated decisions
    --open: string               # Newline-separated open questions
    --commit: string             # Override commit hash
] {
    try {
        log add --title=$title --found=$found --decided=$decided --open=$open --commit=$commit
    } catch { |err|
        errors pretty-print $err
    }
}

# Show current configuration
def "main config" [--json] {
    try {
        config --json=$json
    } catch { |err|
        errors pretty-print $err
    }
}

# Show version information
def "main version" [] {
    try {
        open ($env.FILE_PWD | path join "VERSION") | str trim
    } catch { |err|
        errors pretty-print $err
    }
}

# Show help message
def "main help" [] {
    try {
        print_help
    } catch { |err|
        errors pretty-print $err
    }
}

def main [--version(-v)] {
    try {
        if $version {
            open ($env.FILE_PWD | path join "VERSION") | str trim
        } else {
            print_help
        }
    } catch { |err|
        errors pretty-print $err
    }
}

# Override built-in help to show custom help for main script
# This intercepts the --help flag before Nushell's auto-generated help
def help [...rest] {
    print_help
}

def print_help [] {
    print "mem - CLI tool for managing AI agent artifacts in git repositories

USAGE:
    mem <SUBCOMMAND> [OPTIONS]

SUBCOMMANDS:
    init       Initialize agent artifacts directory structure
    add        Create a new artifact file
    ref        Manage reference materials (clone repos, copy files)
    list       List artifacts (respects .gitignore)
    log        Manage project log (add entries)
    prune      Delete temporary and reference files (cleanup)
    status     Show git status of mem directory
    diff       Show git diff of changes in mem directory
    push       Push mem branch to remote
    pull       Pull mem branch from remote
    config     Show current configuration and sources
    version    Show version information
    help       Show this help message

OPTIONS:
    -v, --version  Show version
    -h, --help     Show this help

CONFIGURATION:
    mem can be customized via config file or environment variables:
    
    Config file: ~/.config/mem/mem.json
    Example:
        {
          \"branch_name\": \"context\",
          \"dir_name\": \".mem\"
        }
    
    Environment variables (override config file):
        MEM_BRANCH_NAME    Git branch name (default: \"mem\")
        MEM_DIR_NAME       Directory name (default: ".mem")
    
    View current config: mem config

EXAMPLES:
    mem init                               # Initialize in current git repository
    mem add spec.md                        # Create a file
    mem add note.txt 'content'             # Create a file with content
    mem ref add github:octocat/hello-world # Clone GitHub repo
    mem ref add path:~/config.yaml         # Copy local file
    mem list                               # List files for current branch
    mem list --all                         # List files for all branches
    mem list --include-ignored             # Include tmp/ and ref/ files
    mem list -ai --json                    # All branches, with ignored files, JSON output
    mem log add --title \"Fixed bug\" --found \"Root cause\" --decided \"Applied fix\"
    mem prune                              # Delete tmp/ and ref/ for current branch
    mem prune --all                        # Delete for all branches (with confirmation)
    mem prune --force                      # Skip confirmation prompt
    mem prune -af                          # Delete for all branches, no confirmation
    mem status                             # Show git status
    mem diff                               # Show all changes in .mem/
    mem diff spec.md                       # Show changes for specific file
    mem diff trace/abc123d/                # Show changes for specific path
    mem push                               # Push to origin/mem
    mem push --remote upstream             # Push to upstream/mem
    mem pull                               # Pull from origin/mem
    mem pull --remote upstream             # Pull from upstream/mem
    mem config                             # Show configuration
    mem version                            # Show version
"
}
