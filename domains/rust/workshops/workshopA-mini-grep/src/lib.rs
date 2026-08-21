// ✦ StudyLine Workshop A: Mini-Ripgrep Library

/// Step 1: 零拷贝命令行配置
pub struct Config<'a> {
    pub query: &'a str,
    pub file_path: &'a str,
    pub ignore_case: bool,
}

impl<'a> Config<'a> {
    pub fn build(args: &'a [String]) -> Result<Self, &'static str> {
        if args.len() < 3 {
            return Err("Usage: minigrep <query> <file_path> [--ignore-case]");
        }
        let query = &args[1];
        let file_path = &args[2];
        let ignore_case = args.iter().any(|a| a == "--ignore-case" || a == "-i");

        Ok(Self {
            query,
            file_path,
            ignore_case,
        })
    }
}

/// Step 2: 零拷贝生命周期搜索算法
pub fn search<'a>(query: &str, contents: &'a str) -> Vec<&'a str> {
    let mut results = Vec::new();
    for line in contents.lines() {
        if line.contains(query) {
            results.push(line);
        }
    }
    results
}

/// Step 3: 大小写不敏感搜索
pub fn search_case_insensitive<'a>(query: &str, contents: &'a str) -> Vec<&'a str> {
    let q_lower = query.to_lowercase();
    let mut results = Vec::new();
    for line in contents.lines() {
        if line.to_lowercase().contains(&q_lower) {
            results.push(line);
        }
    }
    results
}

/// Step 4: ANSI 终端高亮片段生成
pub fn highlight_match(line: &str, query: &str) -> String {
    line.replace(query, &format!("\x1b[1;33m{}\x1b[0m", query))
}
