// ✦ NoteBoot Markdown AST & WikiLink Extractor

#[derive(Debug, Clone)]
pub struct ExtractedNoteInfo {
    pub title: String,
    pub outbound_links: Vec<(String, Option<String>, String)>, // (target_path, anchor, kind)
    pub block_ids: Vec<String>,
}

pub fn parse_markdown_metadata(content: &str, file_name: &str) -> ExtractedNoteInfo {
    let mut title = file_name.trim_end_matches(".md").to_string();
    let mut outbound_links = Vec::new();
    let mut block_ids = Vec::new();

    let mut found_first_heading = false;

    for line in content.lines() {
        let trimmed = line.trim();

        // 1. 提取 H1 标题
        if !found_first_heading && trimmed.starts_with("# ") {
            title = trimmed[2..].trim().to_string();
            found_first_heading = true;
        }

        // 2. 提取细粒度块级锚点 `^block-id`
        if let Some(pos) = trimmed.rfind(" ^") {
            let candidate = &trimmed[pos + 2..];
            if !candidate.is_empty() && candidate.chars().all(|c| c.is_alphanumeric() || c == '_' || c == '-') {
                block_ids.push(candidate.to_string());
            }
        }

        // 3. 提取 WikiLink `[[...]]`
        let mut rest = line;
        while let Some(start) = rest.find("[[") {
            if let Some(end) = rest[start + 2..].find("]]") {
                let link_content = &rest[start + 2..start + 2 + end];
                let is_embed = start > 0 && rest.as_bytes()[start - 1] == b'!';

                // 处理管道符别名 `[[path|alias]]`
                let raw_target = if let Some(pipe_pos) = link_content.find('|') {
                    &link_content[..pipe_pos]
                } else {
                    link_content
                };

                // 处理锚点 `[[path#anchor]]`
                let (target, anchor) = if let Some(hash_pos) = raw_target.find('#') {
                    (
                        raw_target[..hash_pos].trim().to_string(),
                        Some(raw_target[hash_pos + 1..].trim().to_string()),
                    )
                } else {
                    (raw_target.trim().to_string(), None)
                };

                if !target.is_empty() {
                    outbound_links.push((
                        target,
                        anchor,
                        if is_embed { "embed".to_string() } else { "wiki".to_string() },
                    ));
                }

                rest = &rest[start + 2 + end + 2..];
            } else {
                break;
            }
        }
    }

    ExtractedNoteInfo {
        title,
        outbound_links,
        block_ids,
    }
}
