#[cfg(test)]
mod tests {
    use crate::commands::context::*;
    use serde_json::json;

    #[test]
    fn test_deserialize_full_schema() {
        let data = json!({
            "default": {
                "artifacts": ["./spec/index.md"],
                "diff": "main...HEAD",
                "include": ["@other-branch"]
            },
            "brief": {
                "artifacts": ["./spec/index.md"]
            }
        });
        let config: ContextConfig = serde_json::from_value(data).unwrap();

        assert_eq!(config.len(), 2);
        assert_eq!(config["default"].artifacts, vec!["./spec/index.md"]);
        assert_eq!(config["default"].diff, Some("main...HEAD".to_string()));
        assert_eq!(config["default"].include, vec!["@other-branch"]);
        assert_eq!(config["brief"].artifacts, vec!["./spec/index.md"]);
        assert_eq!(config["brief"].diff, None);
        assert_eq!(config["brief"].include, Vec::<String>::new());
    }

    #[test]
    fn test_deserialize_partial_schema() {
        let data = json!({
            "default": {
                "artifacts": ["./spec/index.md"]
            }
        });
        let config: ContextConfig = serde_json::from_value(data).unwrap();
        assert_eq!(config["default"].artifacts, vec!["./spec/index.md"]);
        assert_eq!(config["default"].diff, None);
        assert_eq!(config["default"].include, Vec::<String>::new());
    }

    #[test]
    fn test_deserialize_unknown_fields_tolerated() {
        let data = json!({
            "default": {
                "artifacts": [],
                "future_field": "ignore me"
            }
        });
        let config: ContextConfig = serde_json::from_value(data).unwrap();
        assert!(config.contains_key("default"));
    }

    #[test]
    fn test_parse_artifact_path() {
        let root = Path::new("/repo");
        let current = "feat-ctx";

        // Current branch
        let path = parse_artifact_path("./spec/index.md", current, root).unwrap();
        assert_eq!(path, root.join(".mem").join(current).join("spec/index.md"));

        // Cross branch
        let path = parse_artifact_path("@other:spec/plan.md", current, root).unwrap();
        assert_eq!(path, root.join(".mem").join("other").join("spec/plan.md"));

        // Failures
        assert!(parse_artifact_path("../outside.md", current, root).is_err());
        assert!(parse_artifact_path("/absolute.md", current, root).is_err());
        assert!(parse_artifact_path("@branch_with/slash:spec.md", current, root).is_err());
        assert!(parse_artifact_path("no_prefix.md", current, root).is_err());
    }

    #[test]
    fn test_resolve_profile_cycle() {
        let temp = tempfile::tempdir().unwrap();
        let root = temp.path();

        // Setup Cycle: A -> B -> A
        let branch_a = root.join(".mem").join("A");
        let branch_b = root.join(".mem").join("B");
        std::fs::create_dir_all(&branch_a).unwrap();
        std::fs::create_dir_all(&branch_b).unwrap();

        std::fs::write(
            branch_a.join("context.json"),
            r#"{"default": {"include": ["@B"]}}"#,
        )
        .unwrap();
        std::fs::write(
            branch_b.join("context.json"),
            r#"{"default": {"include": ["@A"]}}"#,
        )
        .unwrap();

        let mut visited = std::collections::HashSet::new();
        let res = resolve_profile("A", "default", root, &mut visited);
        assert!(res.is_err());
        assert!(res.unwrap_err().to_string().contains("Cycle detected"));
    }
}
