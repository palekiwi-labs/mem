# mem - Command Line API Specification

**Version:** 1.0  
**Status:** Complete  
**Date:** 2026-01-25

---

## Overview

The `mem` CLI provides commands to manage artifacts in the `.mem/` directory structure. All commands operate within the context of the current git branch.

**Key Principles:**
- Human-focused CLI (AI agents use direct file operations)
- Simple, composable commands
- Git-aware (tracks current branch and commit)
- Paths shown relative to project root for easy copy/paste

---

## Commands

### `mem init`

Initialize the `.mem` directory structure with orphan branch and worktree.

**Usage:**
```bash
mem init
```

**Behavior:**
- Creates `mem` orphan branch (or checks out if exists)
- Sets up `.mem/` directory as worktree of `mem` branch
- Creates `.mem/.gitignore` with patterns for `*/tmp/` and `*/refs/`
- If `.mem/` already exists, prints message and exits (no overwrite)

**Output:**
```
Initialized .mem/ directory
Created orphan branch 'mem'
Set up worktree at .mem/
```

**Error cases:**
- `.mem/` already exists → Exit with message
- Not in a git repository → Error

---

### `mem add <filename> [flags]`

Create a new artifact file with optional content from stdin.

**Usage:**
```bash
# Create empty file at branch root
mem add spec.md

# Create file with piped content
echo "# Specification" | mem add spec.md

# Create file in trace/ for current commit
mem add review.md --trace

# Create file in trace/ for specific commit
mem add review.md --trace --commit abc123d

# Create file in tmp/ for specific commit
mem add ci.log --tmp --commit abc123d

# Create file in refs/
mem add config.json --ref

# Force overwrite existing file
mem add spec.md --force
```

**Arguments:**
- `<filename>` - Name of file to create (relative path supported for subdirectories)

**Flags:**
- `--trace` - Save to `.mem/<branch>/trace/<commit>/`
- `--tmp` - Save to `.mem/<branch>/tmp/<commit>/`
- `--ref` - Save to `.mem/<branch>/refs/`
- `--commit <hash>` - Specify commit hash (must be combined with `--trace` or `--tmp`)
- `--force, -f` - Overwrite existing file without prompting
- (no flags) - Save to `.mem/<branch>/` (branch root)

**Behavior:**
- Creates a new file with given filename
- If stdin has content (pipe), writes content to file
- If no stdin, creates empty file
- Uses current HEAD commit hash when `--trace` or `--tmp` used without `--commit`
- Converts current branch name (slashes to dashes) for directory structure

**Output:**
```
Created: .mem/dev/spec.md
```

**Error cases:**
- File already exists and no `--force` flag → Error: "File exists, use --force to overwrite"
- `--commit` used without `--trace` or `--tmp` → Error: "--commit requires --trace or --tmp"
- Not in a git repository → Error
- Detached HEAD state → Error: "Not on a branch"

---

### `mem list [flags]`

List artifacts for current branch.

**Usage:**
```bash
# List files at branch root only
mem list

# List branch root + trace/
mem list --trace

# List branch root + tmp/
mem list --tmp

# List branch root + refs/ (depth 1)
mem list --ref

# List refs/ with depth 2
mem list --ref --depth 2

# Combine multiple flags
mem list --trace --tmp --ref
```

**Flags:**
- `--trace` - Include files in `trace/<commit>/` subdirectories
- `--tmp` - Include files in `tmp/<commit>/` subdirectories
- `--ref` - Include files in `refs/` subdirectory
- `--depth <n>` - When `--ref` is used, limit directory depth (default: 1, 0 = unlimited)

**Behavior:**
- Default: Lists only files at `.mem/<branch>/` root (not subdirectories)
- Flags are cumulative (can combine multiple)
- Paths shown relative to project root (e.g., `.mem/dev/spec.md`)
- For refs/, limits depth to avoid printing entire git trees of cloned repos

**Output:**
```
.mem/dev/spec.md
.mem/dev/plan.md
.mem/dev/trace/abc123d/review.md
.mem/dev/trace/xyz9876/analysis.md
.mem/dev/tmp/abc123d/ci.log
.mem/dev/refs/config.json
.mem/dev/refs/peer-service/
```

**Error cases:**
- Not in a git repository → Error
- `.mem/` doesn't exist → Error: "Run 'mem init' first"

---

### `mem show <path>`

Display content of an artifact file.

**Usage:**
```bash
# Show file at branch root (exact path match)
mem show spec.md

# Show file in subdirectory
mem show trace/abc123d/review.md

# Full path also works
mem show .mem/dev/spec.md
```

**Arguments:**
- `<path>` - Path to file (relative to `.mem/<branch>/` or absolute)

**Behavior:**
- Resolves path relative to `.mem/<branch>/`
- Must match exact filename (no extension guessing or fuzzy matching)
- Prints file content to stdout

**Output:**
```
<file contents>
```

**Error cases:**
- File doesn't exist → Error: "File not found: .mem/dev/spec.md"
- Path is a directory → Error: "Path is a directory"
- Not in a git repository → Error
- `.mem/` doesn't exist → Error: "Run 'mem init' first"

---

### `mem rm <path>`

Remove an artifact file.

**Usage:**
```bash
# Remove file at branch root
mem rm spec.md

# Remove file in subdirectory
mem rm trace/abc123d/review.md

# Remove directory and contents
mem rm trace/abc123d/
```

**Arguments:**
- `<path>` - Path to file or directory (relative to `.mem/<branch>/`)

**Behavior:**
- Resolves path relative to `.mem/<branch>/`
- Removes file or directory (recursive for directories)
- No confirmation prompt (use with caution)

**Output:**
```
Removed: .mem/dev/spec.md
```

**Error cases:**
- Path doesn't exist → Error: "File not found: .mem/dev/spec.md"
- Not in a git repository → Error
- `.mem/` doesn't exist → Error: "Run 'mem init' first"

---

### `mem prune [flags]`

Delete temporary and reference files (cleanup).

**Usage:**
```bash
# Delete tmp/ and ref/ for current branch
mem prune

# Delete for all branches
mem prune --all

# Skip confirmation
mem prune --force

# Delete for all branches, skip confirmation
mem prune --all --force
```

**Flags:**
- `--all, -a` - Delete for all branches (requires confirmation)
- `--force, -f` - Skip confirmation prompt

**Behavior:**
- Default: Deletes `.agents/<branch>/tmp/` and `.agents/<branch>/ref/`
- With `--all`: Deletes tmp/ and ref/ for all branches
- Always prompts for confirmation unless `--force` is specified
- Confirmation prompt (without --all): "Delete tmp/ and ref/ for branch '<branch>'? (y/N)"
- Confirmation prompt (with --all): "Delete tmp/ and ref/ for ALL branches? This cannot be undone. (y/N)"
- Only displays paths that were actually deleted (silent about non-existent directories)
- `trace/` directory is never deleted by prune

**Output:**
```
Deleted: .agents/dev/tmp/
Deleted: .agents/dev/ref/
```

Or if nothing to delete:
```
Nothing to delete
```

**Error cases:**
- Not in a git repository → Error
- `.agents/` doesn't exist → Error: "Run 'mem init' first"
- User declines confirmation → Exit with message "Aborted"
- Permission denied → Error with details

---

### `mem commit [flags]`

Create a git commit in the `mem` branch with auto-generated message.

**Usage:**
```bash
# Commit with custom message
mem commit -m "Add code review for login feature"

# Commit message format: <project-commit-hash>: <message>
# Result: "abc123d: Add code review for login feature"
```

**Flags:**
- `--message, -m <msg>` - Commit message (required)

**Behavior:**
- Stages all changes in `.mem/` (equivalent to `git add .` in `.mem/`)
- Creates commit in `mem` orphan branch
- Auto-generates commit message format: `<project-repo-commit-hash>: <message>`
  - `<project-repo-commit-hash>` = current HEAD commit hash (short) in main project repo
  - `<message>` = user-provided message from `--message` flag
- Correlates mem commits with project repo commits for traceability

**Output:**
```
[mem abc123d] abc123d: Add code review for login feature
 2 files changed, 45 insertions(+)
```

**Error cases:**
- No `--message` flag → Error: "--message is required"
- Not in a git repository → Error
- `.mem/` doesn't exist → Error: "Run 'mem init' first"
- No changes to commit → Message: "Nothing to commit"

---

### `mem push`

Push `mem` branch to remote.

**Usage:**
```bash
mem push
```

**Behavior:**
- Wrapper around `git push origin mem`
- Pushes `mem` orphan branch to remote repository

**Output:**
```
Pushing to origin/mem...
<git push output>
```

**Error cases:**
- No remote configured → Error from git
- Not in a git repository → Error
- `.mem/` doesn't exist → Error: "Run 'mem init' first"

---

### `mem pull`

Pull `mem` branch from remote.

**Usage:**
```bash
mem pull
```

**Behavior:**
- Wrapper around `git pull origin mem`
- Pulls latest changes from `mem` branch on remote

**Output:**
```
Pulling from origin/mem...
<git pull output>
```

**Error cases:**
- No remote configured → Error from git
- Merge conflicts → Standard git merge conflict handling
- Not in a git repository → Error
- `.mem/` doesn't exist → Error: "Run 'mem init' first"

---

### `mem status`

Show git status of `.mem/` directory.

**Usage:**
```bash
mem status
```

**Behavior:**
- Wrapper around `git status` run inside `.mem/` worktree
- Shows tracked/untracked files, changes, etc.

**Output:**
```
<git status output from .mem/ worktree>
```

**Error cases:**
- Not in a git repository → Error
- `.mem/` doesn't exist → Error: "Run 'mem init' first"

---

### `mem diff [<path>]`

Show git diff of changes in `.mem/` directory.

**Usage:**
```bash
# Show all changes in .mem/
mem diff

# Show changes for specific file
mem diff spec.md

# Show changes for specific path
mem diff trace/abc123d/
```

**Arguments:**
- `<path>` - Optional path to specific file or directory (relative to `.mem/<branch>/`)

**Behavior:**
- Wrapper around `git diff` run inside `.mem/` worktree
- If path provided, shows diff for that specific path
- Otherwise shows all changes

**Output:**
```
<git diff output>
```

**Error cases:**
- Not in a git repository → Error
- `.mem/` doesn't exist → Error: "Run 'mem init' first"

---

### `mem config [key] [value]`

View or edit `mem` configuration.

**Usage:**
```bash
# Show all configuration
mem config

# Get specific config value
mem config mem.directory

# Set config value
mem config mem.directory .agents
```

**Arguments:**
- `[key]` - Configuration key (optional)
- `[value]` - Configuration value (optional, requires key)

**Behavior:**
- No arguments: Display all configuration
- Key only: Display value for that key
- Key + value: Set configuration value
- Configuration stored in `.mem/.memconfig.yaml` (or project-level config TBD)

**Configuration keys:**
- `mem.directory` - Directory name (default: `.mem`)
- `mem.branch` - Orphan branch name (default: `mem`)

**Output:**
```
# mem config
mem.directory = .mem
mem.branch = mem

# mem config mem.directory
.mem

# mem config mem.directory .agents
Updated: mem.directory = .agents
```

**Error cases:**
- Invalid key → Error: "Unknown config key"
- `.mem/` doesn't exist → Error: "Run 'mem init' first"

---

## Command Combinations & Workflows

### Typical workflow for creating a new feature

```bash
# 1. Initialize mem (first time only)
mem init

# 2. Create initial spec
echo "# Login Feature" | mem add spec.md

# 3. Create implementation plan
mem add plan.md
# ... edit plan.md manually ...

# 4. After code review at commit abc123d
mem add review.md --trace --commit abc123d

# 5. CI fails, save log and analysis
cat ci-output.log | mem add ci-failure.log --tmp --commit abc123d
mem add ci-analysis.md --trace --commit abc123d

# 6. View current artifacts
mem list --trace --tmp

# 7. Commit artifacts to mem branch
mem commit -m "Add feature spec, plan, and initial review"

# 8. Push to remote
mem push

# 9. Clean up temp files when done
mem prune
```

### Working across machines

```bash
# On machine A
mem commit -m "Add spec and plan"
mem push

# On machine B (after git clone of project repo)
mem init                    # Sets up worktree from existing mem branch
mem pull                   # Pull latest artifacts
mem list                   # See what's available
```

---

## Global Flags & Options

**Common flags (to be implemented if needed):**
- `--help, -h` - Show help for command
- `--version, -v` - Show mem version
- `--branch <name>` - Operate on specific branch (instead of current)
- `--verbose` - Verbose output for debugging

---

## Exit Codes

- `0` - Success
- `1` - General error
- `2` - Invalid arguments/usage
- `130` - User cancelled (Ctrl+C, declined confirmation)

---

## Notes for Implementation

**Priority for MVP:**
1. ✅ `init` - Essential for setup
2. ✅ `add` - Primary artifact creation
3. ✅ `list` - Discovery
4. ✅ `show` - Viewing content
5. ✅ `commit` - Syncing to git
6. ✅ `push/pull` - Remote sync
7. ⏸️ `rm` - Nice to have (can use regular rm)
8. ⏸️ `prune` - Cleanup (can use regular rm -rf)
9. ⏸️ `status` - Nice to have (can use git status)
10. ⏸️ `diff` - Nice to have (can use git diff)
11. ⏸️ `config` - Can be hardcoded initially

**Implementation language:** Nushell (for rapid prototyping and iteration)

**Future considerations:**
- Rust port for production deployment in containers
- Tab completion support
- Interactive prompts for safer destructive operations
- Search/query functionality beyond basic list
- Branch management commands (`mem branches`, `mem archive-branch`, etc.)
