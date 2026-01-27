# mem

CLI tool for managing shared context and artifacts between humans and AI in git repositories.

## Overview

mem provides a structured way to store and manage context, documentation, and artifacts shared between humans and AI agents within your git workflow. While it can store agent-generated content, it is primarily designed to help humans provide structured context (plans, references, trace logs) to AI agents without cluttering the main codebase. It uses git worktrees to create an isolated storage environment that maintains full version control side-by-side with your code.

## Features

- Git-based context storage using worktrees and orphan branches
- Branch-aware context organization (content tracked per git branch)
- Multiple content categories: root, trace, tmp, ref
- Reference material management (clone GitHub repos, copy local files)
- Automatic .gitignore for temporary files
- Git integration (status, diff, push, pull)
- Nushell-based implementation

## Installation

### Using Nix

```bash
nix run github:palekiwi-labs/mem
```

## Directory Structure

This structure is automatically managed by the `mem` CLI. You do not need to create these directories manually.

```
.agents/
├── .gitignore           # Ignores */tmp/ and */ref/
├── <branch-name>/       # Per-branch directories
│   ├── plan.md          # Root-level context
│   ├── trace/           # Commit-tied logs
│   │   └── <commit>/    # Specific commit hash
│   │       └── log.txt
│   ├── tmp/             # Temporary content (git-ignored)
│   │   └── <commit>/
│   │       └── cache.json
│   └── ref/             # Reference materials (git-ignored)
│       ├── config.yaml  # Individual reference files
│       └── repos/       # Cloned git repositories (excluded from listings)
│           └── hello-world/
```

**Tracked vs Untracked Content:**
- **Root files** (e.g., `.agents/dev/plan.md`): **Git-tracked** long-lived context that persists across commits.
- **Trace files** (e.g., `.agents/dev/trace/abc123/analysis.md`): **Git-tracked** logs and analysis tied to specific commits (e.g., AI analysis of a failure).
- **Tmp files** (e.g., `.agents/dev/tmp/abc123/error.log`): **Git-ignored** throw-away artifacts (e.g., raw CI logs, error logs) corresponding to a specific commit state.
- **Ref files** (e.g., `.agents/dev/ref/config.yaml`): **Git-ignored** reference material that provides context not inferable from the repo itself.
- **Ref repos** (e.g., `.agents/dev/ref/repos/hello-world/`): **Git-ignored** cloned git repositories (always excluded from `list` output even with `--include-ignored`).

## Usage

### Initialize

Initialize mem in your git repository:

```bash
mem init
```

This creates:
- `.agents/` directory as a git worktree
- `mem` orphan branch
- Initial `.gitignore` in the worktree

### Add Context/Artifacts

Create context files in various categories:

```bash
# Create file in root of current branch
mem add plan.md

# Create file with content
mem add note.txt "Important information"

# Create file in trace/ directory with current commit hash
mem add log.txt --trace

# Create file in tmp/ directory
mem add cache.json --tmp

# Create file in ref/ directory
mem add doc.md --ref

# Specify commit hash manually
mem add analysis.txt --trace --commit abc1234

# Overwrite existing file
mem add plan.md --force
```

### Manage References

Add reference materials for AI agents:

```bash
# Clone GitHub repository
mem ref add github:octocat/hello-world

# Clone specific branch
mem ref add github:octocat/hello-world/develop

# Clone at specific commit
mem ref add github:octocat/hello-world@abc1234

# Shallow clone
mem ref add github:octocat/hello-world --depth 1

# Copy local file or directory
mem ref add path:/etc/config.yaml
mem ref add path:~/Documents/api-docs/

# Overwrite existing reference
mem ref add github:octocat/hello-world --force
```

### List Context/Artifacts

List tracked content:

```bash
# List files for current branch
mem list

# List files for all branches
mem list --all

# Include gitignored tmp/ and ref/ files (excludes cloned repos in ref/repos/)
mem list --include-ignored

# List files with depth limit
mem list --depth 2

# Output in JSON format with commit metadata
mem list --json

# All branches, with ignored files, JSON output
mem list --all --include-ignored --json
```

**JSON Output Format:**
```json
[
  {
    "path": ".agents/dev/plan.md",
    "name": "plan.md",
    "branch": "dev",
    "category": "root",
    "hash": null,
    "commit_hash": "a11f8b2",
    "commit_timestamp": 1769499452
  }
]
```

**Field Descriptions:**
- `path`: Full relative path from repository root
- `name`: Filename
- `branch`: Branch name
- `category`: File category (root, trace, tmp, ref)
- `hash`: Commit hash if file is in trace/tmp/ subdirectory (null for root/ref)
- `commit_hash`: Git commit hash (branch HEAD for root/ref files, explicit commit for trace/tmp)
- `commit_timestamp`: Unix timestamp of the commit (useful for sorting chronologically)

### Cleanup

Remove temporary and reference files:

```bash
# Delete tmp/ and ref/ for current branch
mem prune

# Delete for all branches (with confirmation)
mem prune --all

# Skip confirmation
mem prune --force

# Delete for all branches, no confirmation
mem prune -af
```

### Git Operations

View and manage git status:

```bash
# Show git status of mem directory
mem status

# Show all changes
mem diff

# Show changes for specific file
mem diff spec.md

# Show changes for specific path
mem diff trace/abc123d/
```

Sync with remote:

```bash
# Push to origin/mem
mem push

# Push to specific remote
mem push --remote upstream

# Pull from origin/mem
mem pull

# Pull from specific remote
mem pull --remote upstream
```

### Version

```bash
mem --version
mem version
```

## How It Works

mem uses git worktrees to create an isolated environment for storing shared context and artifacts:

1. **Orphan Branch**: Creates a `mem` branch with no history
2. **Worktree Mount**: Mounts the orphan branch at `.agents/`
3. **Branch Isolation**: Context is organized by git branch
4. **Git Tracking**: All files are tracked via git, respecting .gitignore
5. **Remote Sync**: Push/pull operations sync the mem branch

## License

MIT

## Copyright

Copyright (c) 2026 Palekiwi Labs
