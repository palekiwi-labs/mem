# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

export def pretty-print [error: record] {
    if "MEM_DEBUG" in $env and ($env.MEM_DEBUG == "1") {
        print $error.rendered
        exit 1
    }

    let error_data = $error.json | from json

    let msg = $error_data.msg

    print -e $"Error: ($msg)"

    # Print help text if provided (help field is always present but may be null)
    if $error_data.help != null {
        print -e $error_data.help
    }

    exit 1
}
