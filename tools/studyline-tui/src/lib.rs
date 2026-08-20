// =============================================================================
// StudyLine Terminal User Interface (TUI) Crate
// =============================================================================

pub mod terminal;
pub mod app;

pub use app::TUIApp;
pub use terminal::{setup_terminal, TerminalGuard};
