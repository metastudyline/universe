use std::env;
use workshopA_mini_grep::{Config, search, search_case_insensitive, highlight_match};

fn main() {
    let args: Vec<String> = env::args().collect();
    let config = match Config::build(&args) {
        Ok(c) => c,
        Err(err) => {
            eprintln!("参数错误: {}", err);
            return;
        }
    };

    println!("正在检索关键词: [{}] 在目标文件: [{}]", config.query, config.file_path);
    let sample_text = "Rust 系统级第一性原理\n所有权三大定律与借用检查器\n零拷贝生命周期与 LLVM 优化";
    let matches = if config.ignore_case {
        search_case_insensitive(config.query, sample_text)
    } else {
        search(config.query, sample_text)
    };

    for m in matches {
        println!("  ✔ 匹配项: {}", highlight_match(m, config.query));
    }
}
