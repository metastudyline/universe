use jsonschema::JSONSchema;
use serde_json::Value;
use std::fs;
use std::path::Path;
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
