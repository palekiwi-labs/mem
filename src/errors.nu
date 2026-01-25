# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

export def pretty-print [error: record] {
    let error_data = $error.json | from json

    let msg = $error_data.msg

    print -e $"Error: ($msg)"

    # Print help text if provided (help field is always present but may be null)
    if $error_data.help != null {
        print -e $error_data.help
    }

    exit 1
}
