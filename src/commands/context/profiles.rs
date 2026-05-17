use crate::commands::context::{context_json_path, load_context_config};
use crate::git::get_current_branch;
use std::path::Path;

pub fn handle(cwd: &Path) -> anyhow::Result<()> {
    let branch = get_current_branch(cwd)?;
    let sanitized_branch = branch.replace("/", "-").replace("\\", "-");
    let config_path = context_json_path(cwd, &sanitized_branch);

    let config = load_context_config(&config_path)?;
    let mut names: Vec<_> = config.keys().collect();
    names.sort();

    for name in names {
        println!("{}", name);
    }

    Ok(())
}
