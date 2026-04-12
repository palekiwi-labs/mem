# Learning Materials

This directory contains exploration and learning code that is NOT part of the test suite.

## `gix_exploration.rs`

Exploratory tests for understanding the `gix` API. These are interactive experiments to learn Git's internals through Rust.

**To run these experiments:**

```bash
# Copy back to tests/ temporarily
cp docs/learning/gix_exploration.rs tests/gix_learning.rs

# Run the tests
cargo test --test gix_learning -- --nocapture

# Clean up
rm tests/gix_learning.rs
```

Or just read the code as reference material.
