#!/usr/bin/env nu
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# mem - CLI tool for managing AI agent artifacts in git repositories

use errors.nu
use commands/init.nu

# Initialize .mem directory structure
def "main init" [] {
    try {
        init
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
    version    Show version information
    help       Show this help message

OPTIONS:
    -v, --version  Show version
    -h, --help     Show this help

EXAMPLES:
    mem init       # Initialize .mem in current git repository
    mem version    # Show version
    mem help       # Show help
"
}
