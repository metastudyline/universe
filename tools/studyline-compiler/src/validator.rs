use jsonschema::JSONSchema;
use serde_json::Value;
use std::fs;
use std::path::{Path, PathBuf};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ValidationError {
    #[error("Failed to read schema file: {0}")]
    IoError(#[from] std::io::Error),
    #[error("Failed to parse JSON in {0}: {1}")]
    JsonError(String, serde_json::Error),
    #[error("Schema compilation error: {0}")]
    SchemaCompileError(String),
    #[error("Validation failed for {0}: {1}")]
    ValidationFailed(String, String),
}

pub struct SchemaValidator {
    compiled_schemas: std::collections::HashMap<String, JSONSchema>,
}

impl Default for SchemaValidator {
    fn default() -> Self {
        Self::new()
    }
}

impl SchemaValidator {
    pub fn new() -> Self {
        Self {
            compiled_schemas: std::collections::HashMap::new(),
        }
    }

    pub fn load_schema_from_file(&mut self, name: &str, path: &Path) -> Result<(), ValidationError> {
        let content = fs::read_to_string(path)?;
        let json_value: Value = serde_json::from_str(&content)
            .map_err(|e| ValidationError::JsonError(path.display().to_string(), e))?;
        
        let compiled = JSONSchema::compile(&json_value)
            .map_err(|e| ValidationError::SchemaCompileError(e.to_string()))?;

        self.compiled_schemas.insert(name.to_string(), compiled);
        Ok(())
    }

    pub fn validate_json(&self, schema_name: &str, data: &Value, target_label: &str) -> Result<(), ValidationError> {
        let schema = self
            .compiled_schemas
            .get(schema_name)
            .ok_or_else(|| ValidationError::SchemaCompileError(format!("Schema '{}' not loaded", schema_name)))?;

        if let Err(errors) = schema.validate(data) {
            let error_msgs: Vec<String> = errors.map(|e| e.to_string()).collect();
            return Err(ValidationError::ValidationFailed(
                target_label.to_string(),
                error_msgs.join("; "),
            ));
        }
        Ok(())
    }
}

#[derive(Debug, Clone)]
pub struct PageBundleViolation {
    pub path: PathBuf,
    pub rule: &'static str,
    pub message: String,
    pub line: Option<usize>,
}

pub struct PageBundleValidator;

impl PageBundleValidator {
    /// 检查指定 Markdown 内容是否保持 100% 绝对纯净（代码块外 0 HTML 注释、0 自定义 XML 标签）
    pub fn check_clean_markdown(file_path: &Path, content: &str) -> Vec<PageBundleViolation> {
        let mut violations = Vec::new();
        let mut in_code_fence = false;

        for (line_idx, line) in content.lines().enumerate() {
            let trimmed = line.trim();

            // 识别围栏代码块切换 (``` 或 ~~~)
            if trimmed.starts_with("```") || trimmed.starts_with("~~~") {
                in_code_fence = !in_code_fence;
                continue;
            }

            if in_code_fence {
                continue;
            }

            // 规则 A: 禁止 HTML/XML 注释
            if trimmed.contains("<!--") {
                violations.push(PageBundleViolation {
                    path: file_path.to_path_buf(),
                    rule: "MARKDOWN_NO_HTML_COMMENTS",
                    message: format!("发现被禁止的 HTML 注释: '{}'", trimmed),
                    line: Some(line_idx + 1),
                });
            }

            // 规则 B: 禁止在非代码区写自定义 XML/HTML 标签 (如 <Simulator ...>)
            if let Some(pos) = trimmed.find('<') {
                let after = &trimmed[pos..];
                if let Some(end_pos) = after.find('>') {
                    let tag = &after[..=end_pos];
                    // 排除合法的 HTML URL 链接与 KaTeX inline 符号
                    if !tag.starts_with("<http") && !tag.starts_with("<https") && !tag.starts_with("<mailto") && tag.contains(char::is_alphabetic) {
                        let inner = &tag[1..tag.len() - 1];
                        if inner.starts_with('/') || inner.contains(' ') || inner.chars().all(|c| c.is_alphanumeric() || c == '_' || c == '-') {
                            // 仅拦截真正的自定义组件标签（首字母大写或带中划线组件）
                            let first_char = inner.trim_start_matches('/').chars().next().unwrap_or('a');
                            if first_char.is_uppercase() || inner.contains('-') {
                                violations.push(PageBundleViolation {
                                    path: file_path.to_path_buf(),
                                    rule: "MARKDOWN_NO_CUSTOM_TAGS",
                                    message: format!("发现被禁止的自定义组件标签: '{}' (请改用 node-manifest.yml 外置挂载)", tag),
                                    line: Some(line_idx + 1),
                                });
                            }
                        }
                    }
                }
            }
        }

        violations
    }
}
