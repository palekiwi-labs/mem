# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Main configuration module - public API

use lib/config/mod.nu

# Get memory directory name
export def get-mem-dir-name [] {
    (mod load).dir_name
}

# Get memory branch name
export def get-mem-branch-name [] {
    (mod load).branch_name
}

# Re-export functions needed by config command
export def get-config-path [] {
    mod get-path
}

export def config-file-exists [] {
    mod file-exists
}

export def get-config-source [
    env_var: string
    config_key: string
]: nothing -> string {
    let data = (mod get-with-sources)
    
    if $config_key == "branch_name" {
        $data.sources.branch_name
    } else if $config_key == "dir_name" {
        $data.sources.dir_name
    } else {
        "unknown"
    }
}
