# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Configuration loading functions

use defaults.nu DEFAULTS
use env.nu [get-env-overrides, apply-env-overrides]

# Get config file path
def get-config-file-path [] {
    $env.HOME | path join ".config" "mem" "mem.json"
}

# Load and parse JSON config file
def load-file [path: string] {
    try {
        open $path
    } catch { |err|
        error make {
            msg: $"Failed to load config file: ($path)"
            label: {
                text: $"Parse error: ($err.msg)"
                span: (metadata $path).span
            }
            help: "Ensure the file contains valid JSON"
        }
    }
}

# Main load function - returns config values
export def load [] {
    let result = get-with-sources
    $result.config
}

# Get config with source information
export def get-with-sources [] {
    # Start with defaults
    mut config = $DEFAULTS
    mut sources = {}
    
    # Track all keys from defaults
    for key in ($DEFAULTS | columns) {
        $sources = ($sources | insert $key "default")
    }
    
    # Merge config file if exists
    let config_path = (get-config-file-path)
    mut config_exists = false
    
    if ($config_path | path exists) {
        let file_config = load-file $config_path
        $config = ($config | merge $file_config)
        $config_exists = true
        
        # Track config file overrides
        for key in ($file_config | columns) {
            let value = ($file_config | get $key)
            if $value != null {
                $sources = ($sources | upsert $key "config file")
            }
        }
    }
    
    # Track environment variable overrides
    let env_overrides = get-env-overrides
    for override in $env_overrides {
        $sources = ($sources | upsert $override.key "environment")
    }
    
    # Apply environment variable overrides
    $config = (apply-env-overrides $config)
    
    # Get active environment variables for display
    let env_vars = (
        []
        | if "MEM_BRANCH_NAME" in $env { append $"MEM_BRANCH_NAME=($env.MEM_BRANCH_NAME)" } else { $in }
        | if "MEM_DIR_NAME" in $env { append $"MEM_DIR_NAME=($env.MEM_DIR_NAME)" } else { $in }
    )
    
    {
        config: $config
        sources: $sources
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
