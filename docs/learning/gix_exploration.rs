/// Exploratory tests for learning the `gix` API.
///
/// These are NOT tests of our application logic - they are interactive experiments
/// to understand how gix models Git concepts: repositories, objects, references, and worktrees.
///
/// Everything is accessed through the `gix` crate umbrella re-exports:
///   gix::actor   = gix_actor  (Signature, SignatureRef, ...)
///   gix::objs    = gix_object (Commit, Tree, Blob, ...)
///   gix::hash    = gix_hash   (ObjectId, ...)
///   gix::date    = gix_date   (Time, ...)
///   gix::refs    = gix_ref    (PreviousValue, ...)
///
/// Run with: cargo test --test gix_learning -- --nocapture
use gix::objs::tree::EntryKind;
use gix::refs::transaction::PreviousValue;
use tempfile::tempdir;

/// Helper: a fake author/committer signature for use in tests.
///
/// We use the owned `gix::actor::Signature` (not `SignatureRef`) because
/// `SignatureRef::time` is a raw `&str` slice from a parsed buffer, which is
/// awkward to construct from scratch. `Signature::time` is a `gix::date::Time`
/// struct - much easier to build in tests.
fn test_signature() -> gix::actor::Signature {
    gix::actor::Signature {
        name: "Test User".into(),
        email: "test@example.com".into(),
        time: gix::date::Time {
            seconds: 0,
            offset: 0,
        },
    }
}

/// Helper: create a minimal commit on a branch in a repo.
/// Returns the commit's ObjectId.
///
/// This encapsulates the three steps always needed to get a commit into the object db:
///   1. Write a blob (file contents)
///   2. Write a tree (directory listing referencing the blob)
///   3. Write a commit (pointing to the tree, with optional parents)
///
/// Note: we build the `gix::objs::Commit` directly and call `write_object()`
/// rather than using `repo.commit()`, because `repo.commit()` reads author/committer
/// from git config - which won't be set in our isolated temporary directories.
fn create_commit(
    repo: &gix::Repository,
    branch: &str,
    message: &str,
    parents: &[gix::ObjectId],
) -> gix::ObjectId {
    let sig = test_signature();

    // Step 1: blob
    let blob_id = repo.write_blob(b"hello").unwrap().detach();

    // Step 2: tree (one entry pointing at the blob)
    let tree = gix::objs::Tree {
        entries: vec![gix::objs::tree::Entry {
            mode: EntryKind::Blob.into(),
            filename: "hello.txt".into(),
            oid: blob_id,
        }],
    };
    let tree_id = repo.write_object(&tree).unwrap().detach();

    // Step 3: commit (empty parents = orphan root)
    let commit = gix::objs::Commit {
        message: message.into(),
        tree: tree_id,
        author: sig.clone(),
        committer: sig,
        encoding: None,
        parents: parents.iter().copied().collect(),
        extra_headers: Default::default(),
    };
    let commit_id = repo.write_object(&commit).unwrap().detach();

    // Point the branch reference at our new commit.
    // PreviousValue::Any means we can overwrite an existing ref (useful in the
    // multi-commit tests where we advance the branch pointer).
    repo.reference(branch, commit_id, PreviousValue::Any, "learning commit")
        .unwrap();

    commit_id
}

// ---------------------------------------------------------------------------
// Experiment 1: Initialize a repository
// ---------------------------------------------------------------------------

/// Learn: how do we create a fresh git repository using gix?
#[test]
fn learn_gix_init() {
    let dir = tempdir().unwrap();

    let repo = gix::init(dir.path()).unwrap();

    // The .git directory should now exist on disk
    assert!(dir.path().join(".git").exists());

    // We can ask the repo where its git dir and work dir live
    println!("git_dir:  {:?}", repo.git_dir());
    println!("work_dir: {:?}", repo.workdir());
}

/// Learn: a freshly initialised repo has no commits and no references.
#[test]
fn learn_fresh_repo_has_no_references() {
    let dir = tempdir().unwrap();
    let repo = gix::init(dir.path()).unwrap();

    // try_find_reference returns Ok(None) for a missing ref - no panic, no error
    let found = repo.try_find_reference("refs/heads/main").unwrap();
    assert!(found.is_none());
    println!("No 'main' reference found - as expected in a fresh repo.");
}

// ---------------------------------------------------------------------------
// Experiment 2: Writing objects (blob, tree, commit)
// ---------------------------------------------------------------------------

/// Learn: write a blob object into the object database.
#[test]
fn learn_write_blob() {
    let dir = tempdir().unwrap();
    let repo = gix::init(dir.path()).unwrap();

    let id = repo.write_blob(b"Hello, gix!").unwrap();

    // The Id type implements Display as a hex SHA-1
    println!("blob id: {id}");

    // We can verify the object now exists in the odb
    assert!(repo.has_object(id));
}

/// Learn: write a tree object that references a blob.
#[test]
fn learn_write_tree() {
    let dir = tempdir().unwrap();
    let repo = gix::init(dir.path()).unwrap();

    let blob_id = repo.write_blob(b"content").unwrap().detach();

    let tree = gix::objs::Tree {
        entries: vec![gix::objs::tree::Entry {
            mode: EntryKind::Blob.into(),
            filename: "file.txt".into(),
            oid: blob_id,
        }],
    };
    let tree_id = repo.write_object(&tree).unwrap();

    println!("tree id: {tree_id}");
    assert!(repo.has_object(tree_id));
}

/// Learn: write a commit object manually (without updating any reference).
///
/// This is the lowest-level approach: build the object, hash it, store it.
/// No branch is created or updated here.
#[test]
fn learn_write_commit_object_without_updating_ref() {
    let dir = tempdir().unwrap();
    let repo = gix::init(dir.path()).unwrap();

    let blob_id = repo.write_blob(b"content").unwrap().detach();
    let tree = gix::objs::Tree {
        entries: vec![gix::objs::tree::Entry {
            mode: EntryKind::Blob.into(),
            filename: "file.txt".into(),
            oid: blob_id,
        }],
    };
    let tree_id = repo.write_object(&tree).unwrap().detach();

    let sig = test_signature();
    let commit = gix::objs::Commit {
        message: "initial commit".into(),
        tree: tree_id,
        author: sig.clone(),
        committer: sig,
        encoding: None,
        parents: Default::default(), // empty parents = orphan
        extra_headers: Default::default(),
    };
    let commit_id = repo.write_object(&commit).unwrap();

    println!("commit id: {commit_id}");
    assert!(repo.has_object(commit_id));

    // Note: no reference points to this commit yet.
    // repo.find_reference("refs/heads/main") would fail at this point.
}

// ---------------------------------------------------------------------------
// Experiment 3: References (branches)
// ---------------------------------------------------------------------------

/// Learn: create a branch reference pointing to a commit.
#[test]
fn learn_create_reference() {
    let dir = tempdir().unwrap();
    let repo = gix::init(dir.path()).unwrap();

    let commit_id = create_commit(&repo, "refs/heads/main", "first commit", &[]);

    // Now find the reference we created
    let reference = repo.find_reference("refs/heads/main").unwrap();
    println!("reference name:   {}", reference.name().as_bstr());
    println!("reference target: {:?}", reference.target());

    // Confirm it points at our commit
    let target_id = reference.target().try_id().unwrap().to_owned();
    assert_eq!(target_id, commit_id);
}

/// Learn: find a reference by short name (without the refs/heads/ prefix).
/// gix resolves short names automatically, just like git does.
#[test]
fn learn_find_reference_by_short_name() {
    let dir = tempdir().unwrap();
    let repo = gix::init(dir.path()).unwrap();

    create_commit(&repo, "refs/heads/my-branch", "first commit", &[]);

    let reference = repo.find_reference("my-branch").unwrap();
    println!("found by short name: {}", reference.name().as_bstr());
}

// ---------------------------------------------------------------------------
// Experiment 4: Orphan branch
// ---------------------------------------------------------------------------

/// Learn: what makes a branch "orphan"?
///
/// An orphan branch is simply a branch whose tip commit has NO parents.
/// This is how `git checkout --orphan` works under the hood - there is no
/// special data structure for it; it's just a commit with an empty parents list.
#[test]
fn learn_orphan_branch_has_no_parent_commits() {
    let dir = tempdir().unwrap();
    let repo = gix::init(dir.path()).unwrap();

    // Create a commit with no parents on a dedicated branch
    create_commit(&repo, "refs/heads/mem", "orphan root commit", &[]);

    // Peel the reference to its commit and inspect the parents list
    let mut reference = repo.find_reference("refs/heads/mem").unwrap();
    let commit = reference.peel_to_commit().unwrap();
    let commit_data = commit.decode().unwrap();

    println!("commit message:    {}", commit_data.message);
    println!("number of parents: {}", commit_data.parents.len());

    assert_eq!(
        commit_data.parents.len(),
        0,
        "An orphan commit must have zero parents"
    );
}

/// Learn: a normal (non-orphan) commit DOES have a parent.
/// This contrast makes the orphan property more concrete.
#[test]
fn learn_normal_commit_has_parent() {
    let dir = tempdir().unwrap();
    let repo = gix::init(dir.path()).unwrap();

    // First commit is an orphan root
    let first_id = create_commit(&repo, "refs/heads/main", "root commit", &[]);

    // Second commit has the first as its parent
    let second_id = create_commit(&repo, "refs/heads/main", "second commit", &[first_id]);

    let mut reference = repo.find_reference("refs/heads/main").unwrap();
    let commit = reference.peel_to_commit().unwrap();
    let commit_data = commit.decode().unwrap();

    println!("second commit id: {second_id}");
    println!("parents:          {:?}", commit_data.parents);

    assert_eq!(commit_data.parents.len(), 1);
    // parents in CommitRef are raw hex &BStr slices - convert to ObjectId to compare
    let parent_id = gix::ObjectId::from_hex(commit_data.parents[0]).unwrap();
    assert_eq!(parent_id, first_id);
}

/// Learn: two branches can coexist in the same repo and be completely independent.
///
/// This models exactly what `mem init` will do: the project branch (e.g. `main`)
/// and the mem branch live in the same `.git` object database but share no history.
#[test]
fn learn_two_independent_orphan_branches_in_one_repo() {
    let dir = tempdir().unwrap();
    let repo = gix::init(dir.path()).unwrap();

    // Project branch
    let project_commit = create_commit(&repo, "refs/heads/main", "project root", &[]);

    // Mem branch - orphan, no relation to main
    let mem_commit = create_commit(&repo, "refs/heads/mem", "mem root", &[]);

    println!("main commit: {project_commit}");
    println!("mem  commit: {mem_commit}");

    // They are different objects (different messages → different SHA hashes)
    assert_ne!(project_commit, mem_commit);

    // Confirm mem branch is orphan
    let mut mem_ref = repo.find_reference("refs/heads/mem").unwrap();
    let mem_tip = mem_ref.peel_to_commit().unwrap();
    assert_eq!(mem_tip.decode().unwrap().parents.len(), 0);

    // Confirm main branch is also orphan at its root
    let mut main_ref = repo.find_reference("refs/heads/main").unwrap();
    let main_tip = main_ref.peel_to_commit().unwrap();
    assert_eq!(main_tip.decode().unwrap().parents.len(), 0);
}
