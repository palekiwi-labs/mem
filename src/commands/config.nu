# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Palekiwi Labs

# Show current configuration and sources

use ../lib/config [show-sources]

export def main [--json] {
    show-sources --json=$json
}
