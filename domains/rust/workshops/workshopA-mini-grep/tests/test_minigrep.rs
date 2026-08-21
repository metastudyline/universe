use workshopA_mini_grep::{Config, search, search_case_insensitive, highlight_match};

#[test]
fn test_step1_config_build() {
    let args = vec![
        "minigrep".to_string(),
        "ownership".to_string(),
        "poem.txt".to_string(),
        "--ignore-case".to_string(),
    ];
    let config = Config::build(&args).expect("Config build failed");
    assert_eq!(config.query, "ownership");
    assert_eq!(config.file_path, "poem.txt");
    assert!(config.ignore_case);
}

#[test]
fn test_step2_search_zero_copy() {
    let contents = "\
Rust:
safe, fast, productive.
Pick three.
Duct tape.";
    let results = search("duct", contents);
    assert_eq!(results, vec!["safe, fast, productive."]);
}

#[test]
fn test_step3_search_case_insensitive() {
    let contents = "\
Rust:
safe, fast, productive.
Trust me.";
    let results = search_case_insensitive("rUsT", contents);
    assert_eq!(results, vec!["Rust:", "Trust me."]);
}

#[test]
fn test_step4_highlight_match() {
    let line = "Rust is fast";
    let hl = highlight_match(line, "fast");
    assert!(hl.contains("\x1b[1;33mfast\x1b[0m"));
}
