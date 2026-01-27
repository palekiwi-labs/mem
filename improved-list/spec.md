---
status: todo
---

# Improved `list`

I would like to be able to optionally list all the files, including files in 
the `tmp` and `ref` directories.

Investigate a possibility of `list` command optionally also including files
in the `tmp` and `ref` directories. Currently, `list` relies on `git ls-files`
to list the files efficiently but that excludes gitignored tmp and ref.
This command is faster but it does not give us some possibly useful metadata
that we could use for sorting, such as modification times.


One issue is that `ref` may contain entire repos cloned for reference. Perhaps
we should reconsider where we store the cloned repos and if there is a way to separate
the cloned repos from the rest of the code so we can avoid listing files in repos?
