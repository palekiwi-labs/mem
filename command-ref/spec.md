---
status: todo
---

# Subcommand: `ref`

Consider pros/cons of creating a separate subcommand for managing files in `ref`.

The ref content could be special because it references other existing information, in a read-only way.

Examples:
- user wants to copy some file from different location on their filesystem
- user wants to clone a git repository
- user wants to download a file or a page from the internet

## Possible implementation

Consider adding a new `ref` command with a syntax inspired by `nix flakes`:

`mem ref github:<org>/<repo>`
`mem ref github:<org>/<repo>/<branch>`
`mem ref github:<org>/<repo>/<commit>`
`mem ref path:<path-to-file>`
