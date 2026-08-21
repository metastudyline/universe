// ✦ NoteBoot Markdown AST, Frontmatter & Granular Block Extractor
use serde_json::Value as JsonValue;

#[derive(Debug, Clone)]
pub struct BlockAnchorInfo {
    pub block_id: String,
    pub snippet: String,
}

#[derive(Debug, Clone)]
pub struct ExtractedNoteInfo {
    pub title: String,
    pub frontmatter_meta: JsonValue,
    pub outbound_links: Vec<(String, Option<String>, String)>, // (target_path, anchor, kind)
    pub block_anchors: Vec<BlockAnchorInfo>,
}

pub struct ParsedDocument<'a> {
    pub frontmatter_str: Option<&'a str>,
    pub body: &'a str,
}

/// 零拷贝流式切分 Frontmatter 与 Markdown 正文
pub fn split_frontmatter<'a>(content: &'a str) -> ParsedDocument<'a> {
    let trimmed = content.trim_start();
    if !trimmed.starts_with("---") {
        return ParsedDocument {
            frontmatter_str: None,
            body: content,
        };
    }

    // 快速定位第二个 `---`
    if let Some(end_idx) = trimmed[3..].find("\n---") {
        let closing_line = &trimmed[3 + end_idx + 1..];
        if let Some(newline_pos) = closing_line.find('\n') {
            let fm_slice = trimmed[3..3 + end_idx].trim();
            let body_slice = &closing_line[newline_pos + 1..];
            return ParsedDocument {
                frontmatter_str: Some(fm_slice),
                body: body_slice,
            };
        }
    }

    ParsedDocument {
        frontmatter_str: None,
        body: content,
    }
}

pub fn parse_markdown_metadata(raw_content: &str, file_name: &str) -> ExtractedNoteInfo {
    let parsed_doc = split_frontmatter(raw_content);

    // 1. 解析 Frontmatter YAML 为 JSON
    let mut frontmatter_meta = serde_json::json!({});
    if let Some(fm_str) = parsed_doc.frontmatter_str {
        if let Ok(yaml_val) = serde_yaml::from_str::<serde_yaml::Value>(fm_str) {
            if let Ok(json_val) = serde_json::to_value(yaml_val) {
                frontmatter_meta = json_val;
            }
        }
    }

    // 2. 确定标题 (优先 Frontmatter title，其次首个 H1，最后文件名)
    let mut title = frontmatter_meta
        .get("title")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| file_name.trim_end_matches(".md").to_string());

    let mut found_h1 = false;
    let mut outbound_links = Vec::new();
    let mut block_anchors = Vec::new();

    for line in parsed_doc.body.lines() {
        let trimmed = line.trim();

        // 提取 H1 标题
        if !found_h1 && trimmed.starts_with("# ") {
            if frontmatter_meta.get("title").is_none() {
                title = trimmed[2..].trim().to_string();
            }
            found_h1 = true;
        }

        // 提取细粒度块级锚点 `^block-id`
        if let Some(pos) = trimmed.rfind(" ^") {
            let candidate = &trimmed[pos + 2..];
            if !candidate.is_empty() && candidate.chars().all(|c| c.is_alphanumeric() || c == '_' || c == '-') {
                let snippet = trimmed[..pos].trim().to_string();
                block_anchors.push(BlockAnchorInfo {
                    block_id: candidate.to_string(),
                    snippet: if snippet.len() > 140 { format!("{}...", &snippet[..137]) } else { snippet },
                });
            }
        }

        // 提取 WikiLink `[[...]]` 与 `![[...]]`
        let mut rest = line;
        while let Some(start) = rest.find("[[") {
            if let Some(end) = rest[start + 2..].find("]]") {
                let link_content = &rest[start + 2..start + 2 + end];
                let is_embed = start > 0 && rest.as_bytes()[start - 1] == b'!';

                let raw_target = if let Some(pipe_pos) = link_content.find('|') {
                    &link_content[..pipe_pos]
                } else {
                    link_content
                };

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
        frontmatter_meta,
        outbound_links,
        block_anchors,
    }
}
