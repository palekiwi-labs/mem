# mem - Directory Structure Specification

**Date:** 2026-01-25  
**Status:** Finalized

## Overview

The `mem` tool organizes artifacts in a `.mem/` directory using a branch-first structure with clear separation between git-tracked and untracked files.

**Configuration:**
- Default directory name: `.mem` (configurable via YAML config)
- Default orphan branch name: `mem` (configurable via YAML config)
- Implementation: Git orphan branch + worktree

---

## Directory Structure

```
.mem/
├── .gitignore                              # Ignores: */tmp/, */refs/
│
└── <branch>/                               # e.g., "dev", "feature/login" -> "feature-login"
    ├── spec.md                             # Git-tracked, evolving documents
    ├── plan.md                             # Git-tracked, evolving documents
    ├── *.md / *.* (any files)              # Git-tracked, freeform
    ├── subdirs/ (optional)                 # Git-tracked, user-created subdirectories
    │
    ├── refs/                               # NOT tracked, reference materials
    │   ├── some-repo/                      # Cloned repos on specific branches
    │   └── user-config.json                # Config files, etc.
    │
    ├── tmp/                                # NOT tracked, commit-specific temporary files
    │   └── <commit-hash>/                  # Short hash (7 chars)
    │       ├── ci-action.log               # Raw logs
    │       ├── debug-dump.txt              # Temporary outputs
    │       └── scratch-*.txt               # Ephemeral files
    │
    └── trace/                              # Git-tracked, commit-specific snapshots
        └── <commit-hash>/                  # Short hash (7 chars)
            ├── log-analysis.md             # Analysis of CI logs
            ├── review.md                   # Code review snapshots
            └── findings.md                 # Any tracked snapshots
```

---

## Git Tracking

**Tracked in `mem` orphan branch:**
- ✅ `<branch>/*.md` and all files at branch root
- ✅ `<branch>/**/` (any user-created subdirectories)
- ✅ `<branch>/trace/<commit>/` (all files)

**NOT tracked (via `.mem/.gitignore`):**
- ❌ `<branch>/refs/` (reference materials)
- ❌ `<branch>/tmp/` (temporary files)

**`.mem/.gitignore` contents:**
```gitignore
# Not tracked
*/tmp/
*/refs/
```

---

## Design Principles

### 1. Branch-First Organization
- Everything is organized under `<branch>/` first
- Branch names with slashes are converted (e.g., `feature/login` → `feature-login`)
- Each feature branch gets isolated artifact storage

### 2. Tracked vs Untracked Separation
- **Tracked (git-versioned):**
  - Evolving documents at branch root (spec.md, plan.md, etc.)
  - Commit-specific snapshots in `trace/<commit>/`
  - Purpose: Share across teams/hosts, preserve history
  
- **Untracked (local-only):**
  - Reference materials in `refs/`
  - Temporary files in `tmp/<commit>/`
  - Purpose: Local context, large files, ephemeral data

### 3. Commit-Specific vs Evolving
- **Branch root:** Evolving documents that change over time
  - `spec.md` always shows current expectations
  - `plan.md` reflects latest implementation approach
  
- **`trace/<commit>/`:** Immutable snapshots tied to specific commits
  - Code reviews describing state at that commit
  - Analyses that don't evolve
  
- **`tmp/<commit>/`:** Temporary data tied to specific commits
  - CI logs, debug dumps
  - Not worth preserving long-term

### 4. Freeform vs Structured
- **Freeform allowed:**
  - Any file extension at branch root
  - User-created subdirectories for organization
  - No predefined file naming restrictions
  
- **Structured areas:**
  - `refs/` for reference materials
  - `tmp/<commit>/` for temporary, commit-tied files
  - `trace/<commit>/` for tracked, commit-tied snapshots

### 5. No Latest Symlinks
- Previous system used `latest/` symlinks to most recent commit
- New system: Commands compute "latest" dynamically from filesystem
- Simpler, no symlink management overhead

---

## File Type Examples

### Evolving Documents (Branch Root, Tracked)
- `spec.md` - Feature requirements and acceptance criteria
- `plan.md` - Implementation plan generated from spec
- `notes.md` - Ongoing notes and discussion points
- `design-decisions.md` - ADRs (Architecture Decision Records)
- `diagram.png` - Visual diagrams
- `data.json` - Structured data
- Any user-created files/directories

### Commit-Specific Tracked (trace/)
- `review.md` - Code review at specific commit
- `log-analysis.md` - Analysis of CI failures
- `findings.md` - Security/performance findings
- Purpose: Immutable snapshots worth preserving and sharing

### Commit-Specific Untracked (tmp/)
- `ci-action.log` - Raw CI output
- `debug-dump.txt` - Debug session output
- `scratch-notes.txt` - Temporary working files
- Purpose: Context during development, not worth long-term storage

### Reference Materials (refs/, Untracked)
- `peer-service-repo/` - Cloned repos (on specific branches)
- `user-config.json` - User configuration files
- `api-docs.pdf` - Reference documentation
- Purpose: Context materials, potentially large, branch-specific

---

## Commit Hash Format

**Short hash (7 characters)** is used for directory names:
- Example: `abc123d` (not full 40-char hash)
- Matches git's default short hash format
- More readable in file paths

---

## Branch Name Conversion

Branch names with special characters are converted for filesystem compatibility:

| Git Branch Name | Directory Name |
|-----------------|----------------|
| `dev` | `dev` |
| `main` | `main` |
| `feature/login` | `feature-login` |
| `bugfix/api-error` | `bugfix-api-error` |

**Conversion rule:** Replace `/` with `-`

---

## Example Usage Scenario

Working on `feature/oauth` branch at commit `a1b2c3d`:

```
.mem/
└── feature-oauth/
    ├── spec.md                          # Requirements (tracked, evolving)
    ├── plan.md                          # Implementation plan (tracked, evolving)
    ├── architecture.md                  # Architecture notes (tracked, evolving)
    │
    ├── refs/
    │   ├── auth-service/                # Cloned repo for reference (not tracked)
    │   └── oauth-rfc.pdf                # Reference docs (not tracked)
    │
    ├── tmp/
    │   ├── a1b2c3d/                     # Current commit
    │   │   ├── ci-failure.log           # CI log (not tracked)
    │   │   └── debug-session.txt        # Debug output (not tracked)
    │   └── xyz9876/                     # Previous commit
    │       └── test-output.log
    │
    └── trace/
        ├── a1b2c3d/                     # Current commit
        │   ├── review.md                # Code review (tracked)
        │   └── ci-analysis.md           # Failure analysis (tracked)
        └── xyz9876/                     # Previous commit
            └── review.md                # Previous review (tracked)
```

**What gets synced to remote:**
- ✅ `spec.md`, `plan.md`, `architecture.md`
- ✅ `trace/a1b2c3d/review.md`, `trace/a1b2c3d/ci-analysis.md`
- ✅ `trace/xyz9876/review.md`

**What stays local:**
- ❌ Everything in `refs/`
- ❌ Everything in `tmp/`

---

## Design Evolution from Current System

**Current system:**
```
.agents/<branch>/<commit>/<files>
.agents/<branch>/latest/<symlinks>
```

**Pain points addressed:**
1. ✅ **Hard to find files** - Now organized by tier (root, trace, tmp, refs)
2. ✅ **Important mixed with unimportant** - Separation via trace/ vs tmp/
3. ✅ **Local-only** - Git tracking via orphan branch enables sync
4. ✅ **Symlink management** - Eliminated, computed via commands

---

## Future Considerations

### Shared Resources
Currently not implemented, but could add:
```
.mem/shared/
└── repos/
    └── common-library/
```

For resources useful across all branches. To be added if use case emerges.

### Manifest/Index
Currently not implemented. Directory structure is self-documenting. Could add manifest later if needed for:
- Rich metadata (tags, descriptions)
- Cross-references between artifacts
- Search/discovery features

---

## Configuration

Future YAML config file (location TBD) will support:

```yaml
mem:
  directory: .mem          # Default, can be changed to .agents, etc.
  branch: mem              # Orphan branch name
  
  # Future options:
  # commit_hash_length: 7
  # branch_name_separator: "-"
```

---

## Status

✅ **Structure finalized** - Ready for implementation  
⏳ **Next step:** Define `mem` command scope and interface
