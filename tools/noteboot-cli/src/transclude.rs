// ✦ NoteBoot Markdown Transclusion & Block Embed Engine
#![allow(clippy::too_many_arguments, dead_code)]

use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::path::Path;

use crate::mount::VirtualVaultScanner;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TransclusionTarget {
    pub raw: String,
    pub vault: Option<String>,
    pub note_path: String,
    pub anchor: Option<String>,
    pub alias: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransclusionResult {
    pub target: TransclusionTarget,
    pub content: String,
    pub is_readonly: bool,
    pub is_cycle_warning: bool,
}

pub struct TransclusionContext {
    pub max_depth: usize,
    pub current_depth: usize,
    pub active_stack: Vec<String>,
    pub visited_chain: HashSet<String>,
}

impl Default for TransclusionContext {
    fn default() -> Self {
        Self {
            max_depth: 3,
            current_depth: 0,
            active_stack: Vec::new(),
            visited_chain: HashSet::new(),
        }
    }
}

pub struct TransclusionEngine;

impl TransclusionEngine {
    /// 零拷贝解析 `![[@namespace/path#^block|alias]]` 或 `![[note#^anchor]]`
    pub fn parse_target(raw: &str) -> Option<TransclusionTarget> {
        let trimmed = raw.trim();
        let inner = if trimmed.starts_with("![[") && trimmed.ends_with("]]") {
            &trimmed[3..trimmed.len() - 2]
        } else if trimmed.starts_with("[[") && trimmed.ends_with("]]") {
            &trimmed[2..trimmed.len() - 2]
        } else {
            trimmed
        };

        if inner.is_empty() {
            return None;
        }

        let (main_part, alias) = if let Some(idx) = inner.find('|') {
            (&inner[..idx], Some(inner[idx + 1..].to_string()))
        } else {
            (inner, None)
        };

        let (path_part, anchor) = if let Some(idx) = main_part.find('#') {
            (&main_part[..idx], Some(main_part[idx + 1..].to_string()))
        } else {
            (main_part, None)
        };

        let (vault, note_path) = if path_part.starts_with('@') {
            if let Some(first_slash) = path_part.find('/') {
                (
                    Some(path_part[..first_slash].to_string()),
                    path_part[first_slash + 1..].to_string(),
                )
            } else {
                (Some(path_part.to_string()), String::new())
            }
        } else {
            (None, path_part.to_string())
        };

        Some(TransclusionTarget {
            raw: raw.to_string(),
            vault,
            note_path,
            anchor,
            alias,
        })
    }

    /// 在给定的上下文中展开 Transclusion 目标段落
    pub fn resolve(
        target: &TransclusionTarget,
        vault_dir: &str,
        ctx: &mut TransclusionContext,
    ) -> TransclusionResult {
        let node_key = format!("{}/{}", target.vault.as_deref().unwrap_or("@local"), target.note_path);

        // 1. 循环引用探测
        if ctx.visited_chain.contains(&node_key) {
            return TransclusionResult {
                target: target.clone(),
                content: format!("\n> [!WARNING] 循环引用拦截\n> 检测到环路调用: `{}`, 已阻止递归展开。\n", ctx.active_stack.join(" ➔ ")),
                is_readonly: true,
                is_cycle_warning: true,
            };
        }

        // 2. 递归深度上限截断 (Max Depth = 3)
        if ctx.current_depth >= ctx.max_depth {
            return TransclusionResult {
                target: target.clone(),
                content: format!("\n> [!NOTE] 达到最大嵌入深度 (3层)\n> 点击查看原典: [[{}]]\n", target.raw),
                is_readonly: true,
                is_cycle_warning: false,
            };
        }

        // 3. 扫描虚拟库匹配文档
        let docs = VirtualVaultScanner::scan_all(vault_dir);
        let matched_doc = docs.into_iter().find(|d| {
            if let Some(ref v) = target.vault {
                if !d.vault.eq_ignore_ascii_case(v) && !format!("@{}", d.vault).eq_ignore_ascii_case(v) {
                    return false;
                }
            }
            d.canonical_path == target.note_path
                || d.canonical_path.ends_with(&target.note_path)
                || Path::new(&d.canonical_path).file_stem().is_some_and(|s| s == target.note_path.as_str())
        });

        if let Some(doc) = matched_doc {
            match VirtualVaultScanner::read_document_content(&doc) {
                Ok(raw_content) => {
                    ctx.visited_chain.insert(node_key.clone());
                    ctx.active_stack.push(node_key.clone());
                    ctx.current_depth += 1;

                    let extracted = if let Some(ref anchor) = target.anchor {
                        Self::extract_anchor_block(&raw_content, anchor)
                    } else {
                        raw_content
                    };

                    ctx.current_depth -= 1;
                    ctx.active_stack.pop();
                    ctx.visited_chain.remove(&node_key);

                    let formatted_card = format!(
                        "\n<div class=\"noteboot-embed-card border-l-2 border-amber-500/60 bg-white/5 pl-4 py-2 my-2 rounded-r-lg\">\n  <div class=\"text-[11px] font-mono font-semibold text-amber-400 mb-1 flex items-center gap-1.5\">\n    <span>✦ {}</span>\n    <span class=\"text-[10px] text-neutral-400\">[{}]</span>\n  </div>\n\n{}\n</div>\n",
                        target.note_path,
                        doc.vault,
                        extracted.trim()
                    );

                    TransclusionResult {
                        target: target.clone(),
                        content: formatted_card,
                        is_readonly: doc.is_readonly,
                        is_cycle_warning: false,
                    }
                }
                Err(e) => TransclusionResult {
                    target: target.clone(),
                    content: format!("> [!ERROR] 无法读取嵌入内容: {}", e),
                    is_readonly: true,
                    is_cycle_warning: false,
                },
            }
        } else {
            TransclusionResult {
                target: target.clone(),
                content: format!("> [!CAUTION] 嵌入目标未找到: `{}`", target.raw),
                is_readonly: true,
                is_cycle_warning: false,
            }
        }
    }

    /// 提取带有 `^block-id` 锚点或指定标题的段落块
    fn extract_anchor_block(content: &str, anchor: &str) -> String {
        let clean_anchor = anchor.trim_start_matches('^');
        let mut target_paragraph = Vec::new();
        let mut current_paragraph = Vec::new();
        let mut found = false;

        for line in content.lines() {
            if line.trim().is_empty() {
                if found {
                    break;
                }
                current_paragraph.clear();
            } else {
                current_paragraph.push(line);
                if line.contains(&format!("^{}", clean_anchor)) || line.contains(anchor) {
                    found = true;
                    target_paragraph = current_paragraph.clone();
                }
            }
        }

        if found && !target_paragraph.is_empty() {
            // 过滤掉尾部的 `^anchor` 标记使输出干净
            let joined = target_paragraph.join("\n");
            joined.replace(&format!("^{}", clean_anchor), "").trim().to_string()
        } else {
            // 降级：返回前 10 行预览
            content.lines().take(10).collect::<Vec<_>>().join("\n")
        }
    }

    /// 流式扫描全文，将所有 `![[...]]` 替换为展开卡片
    pub fn expand_full_document(content: &str, vault_dir: &str) -> String {
        let mut result = String::with_capacity(content.len() + 512);
        let mut rest = content;
        let mut ctx = TransclusionContext::default();

        while let Some(start_idx) = rest.find("![[") {
            result.push_str(&rest[..start_idx]);
            let after_start = &rest[start_idx..];
            if let Some(end_idx) = after_start.find("]]") {
                let raw_tag = &after_start[..end_idx + 2];
                if let Some(target) = Self::parse_target(raw_tag) {
                    let trans_res = Self::resolve(&target, vault_dir, &mut ctx);
                    result.push_str(&trans_res.content);
                } else {
                    result.push_str(raw_tag);
                }
                rest = &after_start[end_idx + 2..];
            } else {
                result.push_str(after_start);
                rest = "";
                break;
            }
        }

        result.push_str(rest);
        result
    }
}
