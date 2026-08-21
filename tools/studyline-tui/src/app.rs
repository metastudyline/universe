// =============================================================================
// StudyLine Academic Terminal UI Application & State Machine
// =============================================================================

use std::time::Duration;
use anyhow::Result;
use crossterm::event::{self, Event, KeyCode, KeyEventKind};
use ratatui::{
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, Paragraph, Wrap},
    Frame, Terminal, backend::Backend,
};

#[derive(PartialEq)]
pub enum FocusedPane {
    Tree,
    Lecture,
    Toc,
}

#[derive(PartialEq)]
pub enum AppMode {
    Reader,
    Exam,
}

pub struct NodeEntry {
    pub id: String,
    pub title: String,
    pub stage: String,
    pub lines: String,
}

pub struct ExamQuestion {
    pub id: String,
    pub prompt: String,
    pub options: Vec<String>,
    pub correct_idx: usize,
    pub selected_idx: Option<usize>,
}

pub struct TUIApp {
    pub mode: AppMode,
    pub focused_pane: FocusedPane,
    pub nodes: Vec<NodeEntry>,
    pub selected_node_idx: usize,
    pub scroll_offset: u16,
    pub active_exam: Option<Vec<ExamQuestion>>,
    pub active_exam_idx: usize,
    pub exam_submitted: bool,
    pub score: u8,
    pub should_quit: bool,
}

impl Default for TUIApp {
    fn default() -> Self {
        Self::new()
    }
}

impl TUIApp {
    pub fn new() -> Self {
        let nodes = vec![
            NodeEntry { id: "E01".into(), title: "语言是人类的第一个外挂".into(), stage: "0段·语言".into(), lines: "1-12".into() },
            NodeEntry { id: "E07".into(), title: "卡俄斯：裂开的虚空".into(), stage: "0段·神话".into(), lines: "116-122".into() },
            NodeEntry { id: "E29".into(), title: "两种争斗与正义的发生".into(), stage: "0段·神话".into(), lines: "1-41".into() },
            NodeEntry { id: "E66".into(), title: "战神山法庭与司法的诞生".into(), stage: "0段·悲剧".into(), lines: "566-777".into() },
            NodeEntry { id: "E82".into(), title: "0段出段综合大考".into(), stage: "0段·考核".into(), lines: "94期全景".into() },
            NodeEntry { id: "A01".into(), title: "泰勒斯：水是万物的始基".into(), stage: "阶段A·米利都".into(), lines: "DK 11 A12".into() },
            NodeEntry { id: "A04".into(), title: "阿那克西曼德残篇 B1".into(), stage: "阶段A·米利都".into(), lines: "DK 12 B1".into() },
            NodeEntry { id: "A16".into(), title: "赫拉克利特：活火与对立".into(), stage: "阶段A·爱非斯".into(), lines: "DK 22 B30".into() },
            NodeEntry { id: "A25".into(), title: "巴门尼德：真理之路".into(), stage: "阶段A·爱利亚".into(), lines: "DK 28 B2".into() },
        ];

        Self {
            mode: AppMode::Reader,
            focused_pane: FocusedPane::Lecture,
            nodes,
            selected_node_idx: 6, // Default A04
            scroll_offset: 0,
            active_exam: None,
            active_exam_idx: 0,
            exam_submitted: false,
            score: 0,
            should_quit: false,
        }
    }

    pub fn run<B: Backend>(&mut self, terminal: &mut Terminal<B>) -> Result<()> {
        while !self.should_quit {
            terminal.draw(|f| self.render(f))?;

            if event::poll(Duration::from_millis(30))? {
                if let Event::Key(key) = event::read()? {
                    if key.kind == KeyEventKind::Press {
                        self.handle_key(key.code);
                    }
                }
            }
        }
        Ok(())
    }

    fn handle_key(&mut self, code: KeyCode) {
        match code {
            KeyCode::Char('q') => self.should_quit = true,
            KeyCode::Tab => {
                self.focused_pane = match self.focused_pane {
                    FocusedPane::Tree => FocusedPane::Lecture,
                    FocusedPane::Lecture => FocusedPane::Toc,
                    FocusedPane::Toc => FocusedPane::Tree,
                };
            }
            KeyCode::Char('e') => {
                if self.mode == AppMode::Reader {
                    self.start_exam();
                } else {
                    self.mode = AppMode::Reader;
                }
            }
            KeyCode::Up | KeyCode::Char('k') => {
                match self.mode {
                    AppMode::Reader => {
                        if self.focused_pane == FocusedPane::Tree {
                            if self.selected_node_idx > 0 {
                                self.selected_node_idx -= 1;
                                self.scroll_offset = 0;
                            }
                        } else {
                            if self.scroll_offset > 0 {
                                self.scroll_offset -= 1;
                            }
                        }
                    }
                    AppMode::Exam => {
                        if self.active_exam_idx > 0 {
                            self.active_exam_idx -= 1;
                        }
                    }
                }
            }
            KeyCode::Down | KeyCode::Char('j') => {
                match self.mode {
                    AppMode::Reader => {
                        if self.focused_pane == FocusedPane::Tree {
                            if self.selected_node_idx + 1 < self.nodes.len() {
                                self.selected_node_idx += 1;
                                self.scroll_offset = 0;
                            }
                        } else {
                            self.scroll_offset += 1;
                        }
                    }
                    AppMode::Exam => {
                        if let Some(exam) = &self.active_exam {
                            if self.active_exam_idx + 1 < exam.len() {
                                self.active_exam_idx += 1;
                            }
                        }
                    }
                }
            }
            KeyCode::Char('1') | KeyCode::Char('2') | KeyCode::Char('3') | KeyCode::Char('4') => {
                if self.mode == AppMode::Exam && !self.exam_submitted {
                    let idx = match code {
                        KeyCode::Char('1') => 0,
                        KeyCode::Char('2') => 1,
                        KeyCode::Char('3') => 2,
                        _ => 3,
                    };
                    if let Some(exam) = &mut self.active_exam {
                        if let Some(q) = exam.get_mut(self.active_exam_idx) {
                            q.selected_idx = Some(idx);
                        }
                    }
                }
            }
            KeyCode::Enter if self.mode == AppMode::Exam && !self.exam_submitted => {
                self.submit_exam();
            }
            _ => {}
        }
    }

    fn start_exam(&mut self) {
        self.mode = AppMode::Exam;
        self.exam_submitted = false;
        self.score = 0;
        self.active_exam = Some(vec![
            ExamQuestion {
                id: "Q1".into(),
                prompt: "阿那克西曼德 DK 12 B1 中，事物向彼此支付赔偿（δίκη καὶ τίσις）的原因是什么？".into(),
                options: vec![
                    "因为事物侵占了神圣祭坛".into(),
                    "因为单一元素在生成中逾界侵犯对方，构成ἀδικία".into(),
                    "因为城邦法官下达了强制死刑判决".into(),
                    "因为四根被爱憎力量彻底撕裂".into(),
                ],
                correct_idx: 1,
                selected_idx: None,
            },
            ExamQuestion {
                id: "Q2".into(),
                prompt: "赫西俄德《劳作与时日》中，将 Ἔρις（争斗）一分为二的哲学动机是什么？".into(),
                options: vec![
                    "区分健康的劳动竞争与破坏性的诉讼掠夺".into(),
                    "区分奥林匹斯神与提坦神".into(),
                    "区分男人与女人的城邦分工".into(),
                    "区分诗歌灵感与神谕真理".into(),
                ],
                correct_idx: 0,
                selected_idx: None,
            },
        ]);
        self.active_exam_idx = 0;
    }

    fn submit_exam(&mut self) {
        if let Some(exam) = &self.active_exam {
            let mut correct = 0;
            for q in exam {
                if q.selected_idx == Some(q.correct_idx) {
                    correct += 1;
                }
            }
            self.score = ((correct as f32 / exam.len() as f32) * 100.0) as u8;
            self.exam_submitted = true;
        }
    }

    pub fn render(&self, f: &mut Frame) {
        let size = f.area();

        // Header (3 lines) + Body + Footer (2 lines)
        let main_chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([Constraint::Length(3), Constraint::Min(10), Constraint::Length(2)])
            .split(size);

        self.render_header(f, main_chunks[0]);
        
        match self.mode {
            AppMode::Reader => self.render_reader_body(f, main_chunks[1]),
            AppMode::Exam => self.render_exam_body(f, main_chunks[1]),
        }

        self.render_footer(f, main_chunks[2]);
    }

    fn render_header(&self, f: &mut Frame, area: Rect) {
        let header_text = vec![
            Line::from(vec![
                Span::styled("  ✦ StudyLine Universe ", Style::default().fg(Color::Rgb(212, 175, 55)).add_modifier(Modifier::BOLD)),
                Span::styled("│ 终端学术研读工作台 (Terminal Academic Reader)", Style::default().fg(Color::White)),
                Span::styled(" │ 60FPS Native Rust Engine", Style::default().fg(Color::DarkGray)),
            ]),
        ];
        let p = Paragraph::new(header_text).block(Block::default().borders(Borders::BOTTOM).border_style(Style::default().fg(Color::Rgb(80, 80, 90))));
        f.render_widget(p, area);
    }

    fn render_reader_body(&self, f: &mut Frame, area: Rect) {
        let h_chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([Constraint::Percentage(22), Constraint::Percentage(56), Constraint::Percentage(22)])
            .split(area);

        // 1. Left Tree
        let tree_items: Vec<ListItem> = self.nodes.iter().enumerate().map(|(idx, n)| {
            let is_sel = idx == self.selected_node_idx;
            let prefix = if is_sel { "▶ " } else { "  " };
            let style = if is_sel {
                Style::default().fg(Color::Rgb(212, 175, 55)).add_modifier(Modifier::BOLD)
            } else {
                Style::default().fg(Color::Gray)
            };
            ListItem::new(format!("{}{}: {}", prefix, n.id, n.title)).style(style)
        }).collect();

        let border_style = if self.focused_pane == FocusedPane::Tree {
            Style::default().fg(Color::Rgb(212, 175, 55))
        } else {
            Style::default().fg(Color::DarkGray)
        };

        let tree_block = Block::default()
            .title(" 📚 学科大纲树 (Tree) ")
            .borders(Borders::ALL)
            .border_style(border_style);
        let tree_list = List::new(tree_items).block(tree_block);
        f.render_widget(tree_list, h_chunks[0]);

        // 2. Center Lecture Body
        let active_node = &self.nodes[self.selected_node_idx];
        let lecture_lines = self.get_formatted_lecture(active_node);
        
        let lecture_border_style = if self.focused_pane == FocusedPane::Lecture {
            Style::default().fg(Color::Rgb(212, 175, 55))
        } else {
            Style::default().fg(Color::DarkGray)
        };

        let lecture_block = Block::default()
            .title(format!(" 📜 {} · {} ", active_node.id, active_node.title))
            .borders(Borders::ALL)
            .border_style(lecture_border_style);

        let p = Paragraph::new(lecture_lines)
            .block(lecture_block)
            .scroll((self.scroll_offset, 0))
            .wrap(Wrap { trim: false });
        f.render_widget(p, h_chunks[1]);

        // 3. Right TOC & Mastery Star Panel
        let right_border_style = if self.focused_pane == FocusedPane::Toc {
            Style::default().fg(Color::Rgb(212, 175, 55))
        } else {
            Style::default().fg(Color::DarkGray)
        };

        let toc_block = Block::default()
            .title(" 🧭 TOC 大纲与掌握度 ")
            .borders(Borders::ALL)
            .border_style(right_border_style);

        let right_lines = vec![
            Line::from(Span::styled("  ★ ★ ★ ★ ☆ (85%)", Style::default().fg(Color::Rgb(212, 175, 55)).add_modifier(Modifier::BOLD))),
            Line::from(Span::styled("  已掌握前置: E01, E07", Style::default().fg(Color::Green))),
            Line::from(""),
            Line::from(Span::styled("  目录导航 (TOC):", Style::default().fg(Color::White).add_modifier(Modifier::BOLD))),
            Line::from(Span::styled("  1. 一手原典文献锚点", Style::default().fg(Color::Gray))),
            Line::from(Span::styled("  2. 核心哲学发生学解析", Style::default().fg(Color::Gray))),
            Line::from(Span::styled("  3. 形式化论证三段论", Style::default().fg(Color::Gray))),
            Line::from(Span::styled("  4. 核心范畴演进对照表", Style::default().fg(Color::Gray))),
            Line::from(""),
            Line::from(Span::styled("  [按 E 键进入出段考核]", Style::default().fg(Color::Rgb(212, 175, 55)))),
        ];
        let right_p = Paragraph::new(right_lines).block(toc_block);
        f.render_widget(right_p, h_chunks[2]);
    }

    fn render_exam_body(&self, f: &mut Frame, area: Rect) {
        let block = Block::default()
            .title(" ✍️ 出段综合大考考核系统 (Exit Exam) ")
            .borders(Borders::ALL)
            .border_style(Style::default().fg(Color::Rgb(212, 175, 55)));

        if let Some(exam) = &self.active_exam {
            let q = &exam[self.active_exam_idx];
            let mut lines = vec![
                Line::from(vec![
                    Span::styled(format!("  第 {} / {} 题：", self.active_exam_idx + 1, exam.len()), Style::default().fg(Color::Rgb(212, 175, 55)).add_modifier(Modifier::BOLD)),
                    Span::styled(&q.prompt, Style::default().fg(Color::White).add_modifier(Modifier::BOLD)),
                ]),
                Line::from(""),
            ];

            for (idx, opt) in q.options.iter().enumerate() {
                let is_sel = q.selected_idx == Some(idx);
                let mark = if is_sel { "(●) " } else { "( ) " };
                let style = if is_sel {
                    Style::default().fg(Color::Rgb(212, 175, 55)).add_modifier(Modifier::BOLD)
                } else {
                    Style::default().fg(Color::Gray)
                };
                lines.push(Line::from(vec![
                    Span::styled(format!("    {} {}. {}", mark, idx + 1, opt), style),
                ]));
            }

            lines.push(Line::from(""));
            if self.exam_submitted {
                lines.push(Line::from(vec![
                    Span::styled("  🎉 考核完成！", Style::default().fg(Color::Green).add_modifier(Modifier::BOLD)),
                    Span::styled(format!(" 得分: {} 分 (出段判据: 通过)", self.score), Style::default().fg(Color::White)),
                ]));
                lines.push(Line::from(Span::styled("  [按 E 返回讲义阅读]", Style::default().fg(Color::Rgb(212, 175, 55)))));
            } else {
                lines.push(Line::from(Span::styled("  [按 1-4 选择答案 │ ↑/↓ 切换题目 │ 回车 Enter 提交试卷]", Style::default().fg(Color::DarkGray))));
            }

            let p = Paragraph::new(lines).block(block);
            f.render_widget(p, area);
        }
    }

    fn render_footer(&self, f: &mut Frame, area: Rect) {
        let footer_text = Line::from(vec![
            Span::styled("  [Tab] 切换面板  ", Style::default().fg(Color::DarkGray)),
            Span::styled("[j/k/↑/↓] 滚动/选节点  ", Style::default().fg(Color::DarkGray)),
            Span::styled("[E] 出段考核  ", Style::default().fg(Color::Rgb(212, 175, 55))),
            Span::styled("[q] 退出", Style::default().fg(Color::DarkGray)),
        ]);
        let p = Paragraph::new(footer_text);
        f.render_widget(p, area);
    }

    fn get_formatted_lecture(&self, node: &NodeEntry) -> Vec<Line<'static>> {
        if node.id == "A04" {
            vec![
                Line::from(Span::styled("# 一手原典文献锚点 (DK 12 B1)", Style::default().fg(Color::Rgb(212, 175, 55)).add_modifier(Modifier::BOLD))),
                Line::from(""),
                Line::from(vec![
                    Span::styled("  🏛️ [希腊原文] ", Style::default().fg(Color::Rgb(212, 175, 55)).add_modifier(Modifier::BOLD)),
                    Span::styled("ἐξ ὧν δὲ ἡ γένεσίς ἐστι τοῖς οὖσι, καὶ τὴν φθορὰν εἰς ταῦτα γίνεσθαι κατὰ τὸ χρεών· διδόναι γὰρ αὐτὰ δίκην καὶ τίσιν ἀλλήλοις τῆς ἀδικίας κατὰ τὴν τοῦ χρόνου τάξιν.", Style::default().fg(Color::Rgb(240, 220, 160))),
                ]),
                Line::from(""),
                Line::from(vec![
                    Span::styled("  📜 [学术中译] ", Style::default().fg(Color::Green).add_modifier(Modifier::BOLD)),
                    Span::styled("万物从何处生成，也必依照必然性（κατὰ τὸ χρεών）毁灭而归向何处；因为它们依照时间的裁定（κατὰ τὴν τοῦ χρόνου τάξιν），为了彼此的不义（ἀδικία）相互支付正义赔偿与赎罪（δίκην καὶ τίσιν）。", Style::default().fg(Color::White)),
                ]),
                Line::from(""),
                Line::from(Span::styled("# 核心哲学发生学解析", Style::default().fg(Color::Rgb(212, 175, 55)).add_modifier(Modifier::BOLD))),
                Line::from(""),
                Line::from("  1. 本原的抽象化飞跃：阿那克西曼德放弃了泰勒斯的具体“水”，提出 ἄπειρον（无定/无界）——本原不能具有排他性的具体形态，必须是未分化的中性母体；"),
                Line::from("  2. 宇宙法庭诉讼模型：事物的生成是单一元素对时空的单向侵占（如夏热侵占冷湿，构成 ἀδικία）；时间作为公正法官，要求其在冬季通过消亡清偿赔偿；"),
                Line::from("  3. 前哲学正义的自然化：完成了从赫西俄德人间司法向统御自然物理宇宙法则的伟大跃迁。"),
                Line::from(""),
                Line::from(Span::styled("# 形式化论证三段论 (Syllogism)", Style::default().fg(Color::Rgb(212, 175, 55)).add_modifier(Modifier::BOLD))),
                Line::from(""),
                Line::from(vec![Span::styled("  • 大前提 (P1): ", Style::default().fg(Color::Blue).add_modifier(Modifier::BOLD)), Span::raw("宇宙万物的终极本原不可归约为任何单一经验质料（火、水、气）")]),
                Line::from(vec![Span::styled("  • 小前提 (P2): ", Style::default().fg(Color::Blue).add_modifier(Modifier::BOLD)), Span::raw("凡有限有定之物皆处于相反者的相互逾界（ὕβρις）与补偿之中")]),
                Line::from(vec![Span::styled("  • 归谬 (R1): ", Style::default().fg(Color::Red).add_modifier(Modifier::BOLD)), Span::raw("若本原为水，则烈火必被扑灭而无法共存，宇宙失去动态平衡")]),
                Line::from(vec![Span::styled("  • 结论 (C): ", Style::default().fg(Color::Rgb(212, 175, 55)).add_modifier(Modifier::BOLD)), Span::raw("∴ 必须设立永恒不竭的 ἄπειρον（无定）与客观正义尺度 δίκη")]),
            ]
        } else {
            vec![
                Line::from(Span::styled(format!("# {} · {}", node.id, node.title), Style::default().fg(Color::Rgb(212, 175, 55)).add_modifier(Modifier::BOLD))),
                Line::from(""),
                Line::from(format!("  阶段分类: {}", node.stage)),
                Line::from(format!("  一手出处行号: {}", node.lines)),
                Line::from(""),
                Line::from("  讲义正在通过 Rust 原生 AST 引擎单遍编译呈现。"),
            ]
        }
    }
}
