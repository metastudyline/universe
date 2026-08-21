#![allow(clippy::too_many_arguments, clippy::type_complexity)]

use crate::parser::BlockAnchorInfo;
use rusqlite::{params, Connection, Result};
use std::path::Path;

pub struct Database {
    conn: Connection,
}

#[derive(Debug, serde::Serialize)]
pub struct BacklinkItem {
    pub source_id: String,
    pub source_vault: String,
    pub source_path: String,
    pub source_title: String,
    pub anchor: Option<String>,
    pub kind: String,
    pub snippet: Option<String>,
}

impl Database {
    pub fn open<P: AsRef<Path>>(path: P) -> Result<Self> {
        let conn = Connection::open(path)?;
        let db = Self { conn };
        db.init_tables()?;
        Ok(db)
    }

    fn init_tables(&self) -> Result<()> {
        self.conn.execute_batch(
            r#"
            -- 1. 知识节点表 (多命名空间与只读挂载)
            CREATE TABLE IF NOT EXISTS notes (
                id TEXT PRIMARY KEY,
                vault TEXT NOT NULL DEFAULT '@local',
                path TEXT UNIQUE NOT NULL,
                local_path TEXT NOT NULL,
                title TEXT NOT NULL,
                is_readonly INTEGER NOT NULL DEFAULT 0,
                mtime INTEGER NOT NULL,
                meta JSON NOT NULL DEFAULT '{}'
            );

            CREATE INDEX IF NOT EXISTS idx_notes_vault ON notes(vault);
            CREATE INDEX IF NOT EXISTS idx_notes_path ON notes(path);
            CREATE INDEX IF NOT EXISTS idx_notes_meta_status ON notes(json_extract(meta, '$.status'));
            CREATE INDEX IF NOT EXISTS idx_notes_meta_priority ON notes(json_extract(meta, '$.priority'));

            -- 2. 细粒度块级锚点表
            CREATE TABLE IF NOT EXISTS block_anchors (
                note_id TEXT NOT NULL,
                note_path TEXT NOT NULL,
                block_id TEXT NOT NULL,
                snippet TEXT,
                PRIMARY KEY (note_id, block_id),
                FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_block_anchors_id ON block_anchors(block_id);

            -- 3. 双向链接拓扑边表
            CREATE TABLE IF NOT EXISTS edges (
                source_id TEXT NOT NULL,
                source_path TEXT NOT NULL,
                target_path TEXT NOT NULL,
                anchor TEXT,
                kind TEXT NOT NULL DEFAULT 'wiki',
                PRIMARY KEY (source_id, target_path, anchor),
                FOREIGN KEY(source_id) REFERENCES notes(id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_edges_target ON edges(target_path, anchor);
            CREATE INDEX IF NOT EXISTS idx_edges_source ON edges(source_path);

            -- 4. 全文倒排索引 (FTS5)
            CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
                id UNINDEXED,
                vault UNINDEXED,
                path UNINDEXED,
                title,
                content,
                tokenize='unicode61'
            );

            -- 5. Bento 常用动态视图
            CREATE VIEW IF NOT EXISTS v_tasks AS
            SELECT
                id,
                vault,
                path,
                title,
                json_extract(meta, '$.status') AS status,
                json_extract(meta, '$.priority') AS priority,
                json_extract(meta, '$.due') AS due,
                mtime
            FROM notes
            WHERE json_extract(meta, '$.status') IS NOT NULL;
            "#
        )?;
        Ok(())
    }

    pub fn upsert_note(
        &mut self,
        id: &str,
        vault: &str,
        canonical_path: &str,
        local_path: &str,
        title: &str,
        content: &str,
        mtime: i64,
        is_readonly: bool,
        meta_json: &serde_json::Value,
        outbound_links: &[(String, Option<String>, String)],
        block_anchors: &[BlockAnchorInfo],
    ) -> Result<()> {
        let tx = self.conn.transaction()?;
        let meta_str = serde_json::to_string(meta_json).unwrap_or_else(|_| "{}".to_string());

        tx.execute(
            "INSERT INTO notes (id, vault, path, local_path, title, is_readonly, mtime, meta) 
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
             ON CONFLICT(path) DO UPDATE SET 
                title=?5, is_readonly=?6, mtime=?7, meta=?8",
            params![
                id,
                vault,
                canonical_path,
                local_path,
                title,
                if is_readonly { 1 } else { 0 },
                mtime,
                meta_str
            ],
        )?;

        // 清理旧边与旧锚点
        tx.execute("DELETE FROM edges WHERE source_id = ?1", params![id])?;
        tx.execute("DELETE FROM block_anchors WHERE note_id = ?1", params![id])?;

        // 插入细粒度块级锚点
        for b in block_anchors {
            let _ = tx.execute(
                "INSERT OR REPLACE INTO block_anchors (note_id, note_path, block_id, snippet) VALUES (?1, ?2, ?3, ?4)",
                params![id, canonical_path, b.block_id, b.snippet],
            );
        }

        // 插入新边
        for (target, anchor, kind) in outbound_links {
            let _ = tx.execute(
                "INSERT OR IGNORE INTO edges (source_id, source_path, target_path, anchor, kind) VALUES (?1, ?2, ?3, ?4, ?5)",
                params![id, canonical_path, target, anchor, kind],
            );
        }

        // 更新 FTS5 全文索引
        tx.execute("DELETE FROM notes_fts WHERE id = ?1", params![id])?;
        tx.execute(
            "INSERT INTO notes_fts (id, vault, path, title, content) VALUES (?1, ?2, ?3, ?4, ?5)",
            params![id, vault, canonical_path, title, content],
        )?;

        tx.commit()?;
        Ok(())
    }

    pub fn get_backlinks(&self, target_query: &str) -> Result<Vec<BacklinkItem>> {
        let clean_target = target_query.trim_start_matches('@');
        let like_param = format!("%{}", clean_target);

        let mut stmt = self.conn.prepare(
            "SELECT 
                n.id, n.vault, n.path, n.title, e.anchor, e.kind, b.snippet
             FROM edges e
             JOIN notes n ON e.source_id = n.id
             LEFT JOIN block_anchors b ON b.note_id = e.source_id AND (b.block_id = TRIM(e.anchor, '^') OR b.block_id = e.anchor)
             WHERE e.target_path = ?1 OR e.target_path LIKE ?2 OR e.target_path LIKE ?3
             ORDER BY n.mtime DESC",
        )?;

        let rows = stmt.query_map(params![target_query, like_param, format!("@{}", clean_target)], |row| {
            Ok(BacklinkItem {
                source_id: row.get(0)?,
                source_vault: row.get(1)?,
                source_path: row.get(2)?,
                source_title: row.get(3)?,
                anchor: row.get(4)?,
                kind: row.get(5)?,
                snippet: row.get(6)?,
            })
        })?;

        let mut results = Vec::new();
        for r in rows {
            results.push(r?);
        }
        Ok(results)
    }

    pub fn execute_raw_query(&self, sql: &str) -> Result<(Vec<String>, Vec<Vec<String>>)> {
        let mut stmt = self.conn.prepare(sql)?;
        let column_count = stmt.column_count();
        let column_names: Vec<String> = stmt.column_names().into_iter().map(|s| s.to_string()).collect();

        let mut rows_out = Vec::new();
        let mut rows = stmt.query([])?;

        while let Some(row) = rows.next()? {
            let mut row_vals = Vec::new();
            for i in 0..column_count {
                let val: String = match row.get_ref(i)? {
                    rusqlite::types::ValueRef::Null => "NULL".to_string(),
                    rusqlite::types::ValueRef::Integer(i) => i.to_string(),
                    rusqlite::types::ValueRef::Real(r) => r.to_string(),
                    rusqlite::types::ValueRef::Text(t) => String::from_utf8_lossy(t).to_string(),
                    rusqlite::types::ValueRef::Blob(_) => "[BLOB]".to_string(),
                };
                row_vals.push(val);
            }
            rows_out.push(row_vals);
        }

        Ok((column_names, rows_out))
    }

    pub fn get_stats(&self) -> Result<(usize, usize, usize, Vec<(String, usize)>)> {
        let note_count: usize = self.conn.query_row("SELECT COUNT(*) FROM notes", [], |r| r.get(0))?;
        let edge_count: usize = self.conn.query_row("SELECT COUNT(*) FROM edges", [], |r| r.get(0))?;
        let block_count: usize = self.conn.query_row("SELECT COUNT(*) FROM block_anchors", [], |r| r.get(0))?;

        let mut stmt = self.conn.prepare("SELECT vault, COUNT(*) FROM notes GROUP BY vault ORDER BY COUNT(*) DESC")?;
        let vault_rows = stmt.query_map([], |r| Ok((r.get(0)?, r.get(1)?)))?;

        let mut vaults = Vec::new();
        for v in vault_rows {
            vaults.push(v?);
        }

        Ok((note_count, edge_count, block_count, vaults))
    }
}
