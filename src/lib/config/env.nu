# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Environment variable override functions

# Get list of environment variables that are set
export def get-env-overrides [] {
    mut overrides = []
    
    if ($env.MEM_BRANCH_NAME? | default null) != null {
        $overrides = ($overrides | append {key: "branch_name", env_var: "MEM_BRANCH_NAME"})
    }
    if ($env.MEM_DIR_NAME? | default null) != null {
        $overrides = ($overrides | append {key: "dir_name", env_var: "MEM_DIR_NAME"})
    }
    
    $overrides
}

# Apply environment variable overrides to config
export def apply-env-overrides [config: record] {
    mut result = $config
    
    # MEM_BRANCH_NAME
    let branch_env = $env.MEM_BRANCH_NAME? | default null
    if $branch_env != null {
        $result = ($result | upsert branch_name $branch_env)
    }
    
    # MEM_DIR_NAME
    let dir_env = $env.MEM_DIR_NAME? | default null
    if $dir_env != null {
        $result = ($result | upsert dir_name $dir_env)
    }
    
    $result
}
