# mem

CLI tool for managing shared context and artifacts between humans and AI in git repositories.

## Overview

mem provides a structured way to store and manage context, documentation, and artifacts shared between humans and AI agents within your git workflow. While it can store agent-generated content, it is primarily designed to help humans provide structured context (plans, references, trace logs) to AI agents without cluttering the main codebase. It uses git worktrees to create an isolated storage environment that maintains full version control side-by-side with your code.

## Features

- Git-based context storage using worktrees and orphan branches
- Branch-aware context organization (content tracked per git branch)
- Multiple content categories: spec, bin, trace, tmp, ref
- Reference material management (clone GitHub repos, copy local files)
- Automatic .gitignore for temporary files
- Git integration (status, diff, push, pull)
- Nushell-based implementation

## Installation

### Using Nix

```bash
nix run github:palekiwi-labs/mem
```

## Configuration

mem can be customized through configuration files or environment variables.

### Configuration File

Create a JSON file at `~/.config/mem/mem.json`:

Example `mem.json`:
```json
{
  "branch_name": "context",
  "dir_name": ".mem"
}
```

### Environment Variables

Environment variables override config file values:
- `MEM_BRANCH_NAME` - Git branch name (default: "mem")
- `MEM_DIR_NAME` - Directory name (default: ".mem")

Example:
```bash
export MEM_BRANCH_NAME=ai-context
export MEM_DIR_NAME=.context
mem init
```

### Configuration Priority

1. Environment variables (highest)
2. Config file
3. Hardcoded defaults (lowest)

### Viewing Configuration

```bash
mem config
```

## Directory Structure

This structure is automatically managed by the `mem` CLI. You do not need to create these directories manually.

```
.mem/
├── .gitignore           # Ignores */tmp/ and */ref/
├── <branch-name>/       # Per-branch directories
│   ├── spec/            # Specifications (tracked)
│   │   ├── plan.md
│   │   └── tickets/
│   │       └── JIRA-123.md
│   ├── bin/             # Executable scripts (tracked)
│   │   ├── deploy.sh
│   │   └── scripts/
│   │       └── build.sh
│   ├── trace/           # Commit-tied logs (tracked)
│   │   └── <timestamp>-<commit>/
│   │       └── log.txt
│   ├── tmp/             # Temporary content (ignored)
│   │   └── <timestamp>-<commit>/
│   │       └── cache.json
│   └── ref/             # Reference materials (ignored)
│       ├── config.yaml
│       └── repos/
│           └── octocat/
│               └── hello-world/
```

**Tracked vs Untracked Content:**
- **Spec files** (e.g., `.mem/dev/spec/plan.md`): **Git-tracked** specifications that drive development (plans, tickets, designs, requirements).
- **Bin files** (e.g., `.mem/dev/bin/deploy.sh`): **Git-tracked** executable scripts (shell scripts, Python scripts, automation tools).
- **Trace files** (e.g., `.mem/dev/trace/1738195200-abc123f/analysis.md`): **Git-tracked** logs and analysis tied to specific commits (e.g., AI analysis of a failure).
- **Tmp files** (e.g., `.mem/dev/tmp/1738195200-abc123f/error.log`): **Git-ignored** throw-away artifacts (e.g., raw CI logs, error logs) corresponding to a specific commit state.
- **Ref files** (e.g., `.mem/dev/ref/config.yaml`): **Git-ignored** reference material that provides context not inferable from the repo itself.
- **Ref repos** (e.g., `.mem/dev/ref/repos/octocat/hello-world/`): **Git-ignored** cloned git repositories (always excluded from `list` output even with `--include-ignored`).

## Usage

### Initialize

Initialize mem in your git repository:

```bash
mem init
```

This creates:
- `.mem/` directory as a git worktree
- `mem` orphan branch
- Initial `.gitignore` in the worktree

### Add Context/Artifacts

Create context files in various categories:

```bash
# Create file in spec/ directory
mem add plan.md

# Create nested spec file
mem add tickets/JIRA-123.md

# Create file with content
mem add plan.md "# Project Plan"

# Create executable script in bin/ directory
mem add deploy.sh --bin

# Create nested bin script
mem add scripts/build.sh --bin

# Create bin file with content (with shebang)
mem add run.sh '#!/usr/bin/env bash

echo "Hello"' --bin

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

# Clone private repository via SSH
mem ref add github:myorg/private-repo --ssh

# Combine SSH with other flags
mem ref add github:myorg/private-repo --ssh --depth 1

# Copy local file or directory
mem ref add path:/etc/config.yaml
mem ref add path:~/Documents/api-docs/

# Overwrite existing reference
mem ref add github:octocat/hello-world --force
```

#### Using SSH for Private Repositories

For private repositories, use the `--ssh` flag to clone via SSH:

```bash
mem ref add github:myorg/private-repo --ssh
```

**Prerequisites:**
- SSH key configured with GitHub
- Test SSH access: `ssh -T git@github.com`

**Alternative:** Configure git to use SSH globally:
```bash
git config --global url."git@github.com:".insteadOf "https://github.com/"
```
With this configuration, `mem` will automatically use SSH even without the `--ssh` flag.

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
    "path": ".mem/dev/spec/plan.md",
    "name": "plan.md",
    "branch": "dev",
    "category": "spec",
    "hash": null,
    "commit_hash": "a11f8b2",
    "commit_timestamp": 1769499452
  },
  {
    "path": ".mem/dev/spec/tickets/JIRA-123.md",
    "name": "tickets/JIRA-123.md",
    "branch": "dev",
    "category": "spec",
    "hash": null,
    "commit_hash": "a11f8b2",
    "commit_timestamp": 1769499452
  }
]
```

**Field Descriptions:**
- `path`: Full relative path from repository root
- `name`: Filename or path relative to category directory (includes subdirectories)
- `branch`: Branch name
- `category`: File category (spec, trace, tmp, ref)
- `hash`: Commit hash if file is in trace/tmp/ subdirectory (null for spec/ref)
- `commit_hash`: Git commit hash (branch HEAD for spec/ref files, explicit commit for trace/tmp)
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

### Upgrading from v1.x

Version 2.0 introduces a breaking change: files that were previously at the branch root now live in the `spec/` directory.

#### Manual Migration

If you have existing `.mem/` data with the old structure:

**Option A: Migrate existing files**
```bash
cd .mem/<branch>
mkdir spec
mv *.md spec/
mv <any-other-dirs> spec/
git add .
git commit -m "Migrate to spec/ structure"
```

**Option B: Start fresh**
```bash
# Remove old structure
git worktree remove .mem
git branch -D mem

# Reinitialize
mem init
```

### Configuration

```bash
# Show current configuration and sources
mem config
```

### Version

```bash
mem --version
mem version
```

## How It Works

mem uses git worktrees to create an isolated environment for storing shared context and artifacts:

1. **Orphan Branch**: Creates a `mem` branch with no history
2. **Worktree Mount**: Mounts the orphan branch at `.mem/`
3. **Branch Isolation**: Context is organized by git branch
4. **Git Tracking**: All files are tracked via git, respecting .gitignore
5. **Remote Sync**: Push/pull operations sync the mem branch

## License

MIT

## Copyright

Copyright (c) 2026 Palekiwi Labs
