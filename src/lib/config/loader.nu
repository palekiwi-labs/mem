# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Configuration loading functions

use defaults.nu [MEM_DIR_NAME, MEM_BRANCH_NAME]

# Get config file path
def get-config-file-path [] {
    $env.HOME | path join ".config" "mem" "mem.json"
}

# Load and parse JSON config file
def load-config-file [] {
    let config_path = (get-config-file-path)
    
    if not ($config_path | path exists) {
        return null
    }
    
    try {
        open $config_path
    } catch { |err|
        error make {
            msg: $"Failed to load config file: ($config_path)"
            help: $"Please check that the file has correct permissions and contains valid JSON.\nError details: ($err.msg)"
        }
    }
}

# Load config value with priority: env var > config file > default
def load-value [
    env_var: string       # Environment variable name (e.g., "MEM_BRANCH_NAME")
    config_key: string    # Key in JSON config file
    default: string       # Default value
] {
    # Priority 1: Environment variable
    if $env_var in $env {
        return ($env | get $env_var)
    }
    
    # Priority 2: Config file
    let config = (load-config-file)
    if $config != null and $config_key in $config {
        return ($config | get $config_key)
    }
    
    # Priority 3: Default
    $default
}

# Get config source for a value
def get-source [
    env_var: string       # Environment variable name
    config_key: string    # Key in JSON config file
]: nothing -> string {
    # Check environment variable
    if $env_var in $env {
        return "environment"
    }
    
    # Check config file
    let config = (load-config-file)
    if $config != null and $config_key in $config {
        return "config file"
    }
    
    # Default
    "default"
}

# Main load function - returns config values
export def load [] {
    {
        branch_name: (load-value "MEM_BRANCH_NAME" "branch_name" $MEM_BRANCH_NAME)
        dir_name: (load-value "MEM_DIR_NAME" "dir_name" $MEM_DIR_NAME)
    }
}

# Get config with source information
export def get-with-sources [] {
    let config = (load)
    let config_path = (get-config-file-path)
    let config_exists = ($config_path | path exists)
    
    # Get sources
    let branch_source = (get-source "MEM_BRANCH_NAME" "branch_name")
    let dir_source = (get-source "MEM_DIR_NAME" "dir_name")
    
    # Get active environment variables
    let env_vars = (
        []
        | if "MEM_BRANCH_NAME" in $env { append $"MEM_BRANCH_NAME=($env.MEM_BRANCH_NAME)" } else { $in }
        | if "MEM_DIR_NAME" in $env { append $"MEM_DIR_NAME=($env.MEM_DIR_NAME)" } else { $in }
    )
    
    {
        config: $config
        sources: {
            branch_name: $branch_source
            dir_name: $dir_source
        }
        config_file: {
            path: $config_path
            exists: $config_exists
        }
        env_vars: $env_vars
    }
}

# Get config file path (for display)
export def get-path [] {
    get-config-file-path
}

# Check if config file exists
export def file-exists [] {
    (get-config-file-path) | path exists
}
