#!/usr/bin/env nu
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# mem - CLI tool for managing AI agent artifacts in git repositories

use errors.nu
use commands/init.nu
use commands/add.nu
use commands/list.nu

# Initialize .mem directory structure
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
    --commit: string       # Specify commit hash (requires --trace or --tmp)
    --force(-f)            # Overwrite existing file
] {
    try {
        add $filename $content --trace=$trace --tmp=$tmp --ref=$ref --commit=$commit --force=$force
    } catch { |err|
        errors pretty-print $err
    }
}

# List artifact files
def "main list" [
    --trace                # Include files in trace/ subdirectories
    --tmp                  # Include files in tmp/ subdirectories
    --ref                  # Include files in ref/ subdirectory
    --depth: int = 1       # Limit depth for ref/ (default: 1, 0 = unlimited)
] {
    try {
        list --trace=$trace --tmp=$tmp --ref=$ref --depth=$depth
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

def help [] {
    print_help
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

def print_help [] {
    print "mem - CLI tool for managing AI agent artifacts in git repositories

USAGE:
    mem <SUBCOMMAND> [OPTIONS]

SUBCOMMANDS:
    init       Initialize .mem directory structure
    add        Create a new artifact file
    list       List artifacts for current branch
    version    Show version information
    help       Show this help message

OPTIONS:
    -v, --version  Show version
    -h, --help     Show this help

EXAMPLES:
    mem init       # Initialize .mem in current git repository
    mem add spec.md # Create a file
    mem add note.txt "content" # Create a file with content
    mem list --trace # List files including trace directory
    mem version    # Show version
    mem help       # Show help
"
}
