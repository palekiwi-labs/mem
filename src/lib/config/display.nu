# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Configuration display functions

use loader.nu get-with-sources

# Show current configuration
export def show [
    --json  # Output as JSON only
] {
    let result = get-with-sources
    
    if $json {
        print ($result.config | to json --indent 2)
    } else {
        print "Configuration:"
        let format_source = {|source| if $source == "default" { "" } else { $" \(($source)\)" }}
        
        print (["  branch_name: \"" $result.config.branch_name "\"" (do $format_source $result.sources.branch_name)] | str join "")
        print (["  dir_name: \"" $result.config.dir_name "\"" (do $format_source $result.sources.dir_name)] | str join "")
    }
}

# Show configuration with source information
export def show-sources [
    --json  # Output as JSON only
] {
    let result = get-with-sources
    
    if $json {
        let output = {
            config: $result.config
            sources: $result.sources
            config_file: $result.config_file
            env_vars: $result.env_vars
        }
        print ($output | to json --indent 2)
    } else {
        print "Configuration:"
        let format_source = {|source| if $source == "default" { "" } else { $" \(($source)\)" }}
        
        print (["  branch_name: \"" $result.config.branch_name "\"" (do $format_source $result.sources.branch_name)] | str join "")
        print (["  dir_name: \"" $result.config.dir_name "\"" (do $format_source $result.sources.dir_name)] | str join "")
        print ""
        
        let status = if $result.config_file.exists { "found" } else { "not found" }
        print (["Config file: " $result.config_file.path " (" $status ")"] | str join "")
        
        if ($result.env_vars | is-empty) {
            print "Environment variables: (none set)"
        } else {
            print "Environment variables:"
            for var in $result.env_vars {
                print $"  ($var)"
            }
        }
    }
}
