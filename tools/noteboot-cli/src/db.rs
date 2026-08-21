use rusqlite::{params, Connection, Result};
use std::path::Path;

pub struct Database {
    conn: Connection,
}

#[derive(Debug, serde::Serialize)]
pub struct BacklinkItem {
    pub source_id: String,
    pub source_path: String,
    pub source_title: String,
    pub anchor: Option<String>,
    pub kind: String,
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
            CREATE TABLE IF NOT EXISTS notes (
                id TEXT PRIMARY KEY,
                path TEXT UNIQUE NOT NULL,
                title TEXT NOT NULL,
                mtime INTEGER NOT NULL,
                meta JSON NOT NULL DEFAULT '{}'
            );

            CREATE INDEX IF NOT EXISTS idx_notes_path ON notes(path);

            CREATE TABLE IF NOT EXISTS edges (
                source_id TEXT NOT NULL,
                target_path TEXT NOT NULL,
                anchor TEXT,
                kind TEXT NOT NULL DEFAULT 'wiki',
                PRIMARY KEY (source_id, target_path, anchor),
                FOREIGN KEY(source_id) REFERENCES notes(id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_edges_target ON edges(target_path);

            CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
                id UNINDEXED,
                title,
                content,
                tokenize='unicode61'
            );
            "#
        )?;
        Ok(())
    }

    pub fn upsert_note(
        &mut self,
        id: &str,
        path: &str,
        title: &str,
        content: &str,
        mtime: i64,
        outbound_links: &[(String, Option<String>, String)],
    ) -> Result<()> {
        let tx = self.conn.transaction()?;

        tx.execute(
            "INSERT INTO notes (id, path, title, mtime, meta) VALUES (?1, ?2, ?3, ?4, '{}')
             ON CONFLICT(path) DO UPDATE SET title=?3, mtime=?4",
            params![id, path, title, mtime],
        )?;

        // 清理旧边
        tx.execute("DELETE FROM edges WHERE source_id = ?1", params![id])?;

        // 插入新边
        for (target, anchor, kind) in outbound_links {
            let _ = tx.execute(
                "INSERT OR IGNORE INTO edges (source_id, target_path, anchor, kind) VALUES (?1, ?2, ?3, ?4)",
                params![id, target, anchor, kind],
            );
        }

        // 更新 FTS5 全文索引
        tx.execute("DELETE FROM notes_fts WHERE id = ?1", params![id])?;
        tx.execute(
            "INSERT INTO notes_fts (id, title, content) VALUES (?1, ?2, ?3)",
            params![id, title, content],
        )?;

        tx.commit()?;
        Ok(())
    }

    pub fn get_backlinks(&self, target_path: &str) -> Result<Vec<BacklinkItem>> {
        let mut stmt = self.conn.prepare(
            "SELECT n.id, n.path, n.title, e.anchor, e.kind
             FROM edges e
             JOIN notes n ON e.source_id = n.id
             WHERE e.target_path = ?1 OR e.target_path LIKE ?2",
        )?;

        let like_param = format!("%{}", target_path);
        let rows = stmt.query_map(params![target_path, like_param], |row| {
            Ok(BacklinkItem {
                source_id: row.get(0)?,
                source_path: row.get(1)?,
                source_title: row.get(2)?,
                anchor: row.get(3)?,
                kind: row.get(4)?,
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

    pub fn get_stats(&self) -> Result<(usize, usize)> {
        let note_count: usize = self.conn.query_row("SELECT COUNT(*) FROM notes", [], |r| r.get(0))?;
        let edge_count: usize = self.conn.query_row("SELECT COUNT(*) FROM edges", [], |r| r.get(0))?;
        Ok((note_count, edge_count))
    }
}
