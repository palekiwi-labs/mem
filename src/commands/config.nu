# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Show current configuration and sources

use ../lib/config/mod.nu

export def main [] {
    let data = (mod get-with-sources)
    
    # Helper to format source (omit if default)
    let format_source = {|source| if $source == "default" { "" } else { $" \(($source)\)" }}
    
    print "Configuration:"
    print (["  branch_name: \"" $data.config.branch_name "\"" (do $format_source $data.sources.branch_name)] | str join "")
    print (["  dir_name: \"" $data.config.dir_name "\"" (do $format_source $data.sources.dir_name)] | str join "")
    print ""
    
    let status = if $data.config_file.exists { "found" } else { "not found" }
    print (["Config file: " $data.config_file.path " (" $status ")"] | str join "")
    
    # Show environment variables if set
    if ($data.env_vars | is-empty) {
        print "Environment variables: (none set)"
    } else {
        print "Environment variables:"
        for var in $data.env_vars {
            print $"  ($var)"
        }
    }
}
