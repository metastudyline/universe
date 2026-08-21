# R00-02: 全景 Rust 工具链与工业级 IDE 终极实战指南

> **适合人群**：想要打造世界级 Rust 开发工作流的工程师与零基础初学者 · **预计耗时**：25 分钟

---

## 💡 1. 现代 Rust 开发军火库全景

很多初学者觉得写 Rust 痛苦，往往是因为**没有配置好 IDE 的 HUD 抬头显示器**。当配置好 `rust-analyzer` 和 `CodeLLDB` 之后，编译器会在你敲代码的瞬间实时告诉你每一个变量的推导类型、借用状态和潜在 bug。

```
+-------------------------------------------------------------------------+
| 🛸 现代 Rust 工业级生产力矩阵                                            |
+-------------------------------------------------------------------------+
| 1. 语言核心引擎: rustup (工具链版本管理) + cargo (工程构建与包分发)       |
| 2. 智能副驾 HUD: rust-analyzer (LSP 语法提示 / Inlay Hints / 宏展开)    |
| 3. 原生单步调试: CodeLLDB (支持切片/智能指针/枚举内存透视)              |
| 4. 静态安全卫士: clippy (代码异味查杀) + rustfmt (官方代码美化)          |
| 5. 极客硬核武器: miri (未定义行为检测) + cargo-flamegraph (CPU火焰图)    |
+-------------------------------------------------------------------------+
```

---

## 🛠️ 2. 主流四大 IDE 权威选型与黄金配置

### 方案 A: VS Code (官方生态首选 · 推荐度 ★★★★★)
1. **必装插件**：
   - `rust-analyzer` (The Rust Programming Language)
   - `CodeLLDB` (Vadim Chugunov)
   - `crates` (Serayuzgur)
2. **黄金配置文件 (`.vscode/settings.json`)**：
   ```json
   {
     // 保存时自动触发 Clippy 深度体检
     "rust-analyzer.checkOnSave.command": "clippy",
     "rust-analyzer.checkOnSave.enable": true,
     
     // 开启类型与参数 Inlay Hints 透视
     "rust-analyzer.inlayHints.typeHints.enable": true,
     "rust-analyzer.inlayHints.parameterHints.enable": true,
     "rust-analyzer.inlayHints.chainingHints.enable": true,
     
     // 保存时自动执行 rustfmt
     "[rust]": {
       "editor.defaultFormatter": "rust-lang.rust-analyzer",
       "editor.formatOnSave": true
     }
   }
   ```

---

### 方案 B: JetBrains RustRover (专有工业级 IDE · 推荐度 ★★★★★)
- **特点**：开箱即用，无需配置 LSP，内置商业级 AST 分析与可视化断点调试器；
- **配置**：在 `Settings -> Rust` 中开启 `External Linters -> Clippy` 即可。

---

### 方案 C: Zed 编辑器 (极速 GPU 渲染 · 推荐度 ★★★★☆)
- **特点**：基于纯 Rust + GPU 渲染，原生内置 `rust-analyzer`，毫秒级启动与键入；
- **配置 (`.zed/settings.json`)**：
  ```json
  {
    "languages": { "Rust": { "format_on_save": "on" } },
    "lsp": { "rust-analyzer": { "initialization_options": { "check": { "command": "clippy" } } } }
  }
  ```

---

### 方案 D: Neovim (终端极客首选 · 推荐度 ★★★★☆)
- **推荐插件**：`mrcjkb/rustaceanvim`（专为 Neovim 0.10+ 设计，无缝集成 DAP 调试与 CodeLens）。

---

## 🔬 3. 必备 5 大命令行武器库

```bash
# 1. 深度静态体检与异味查杀
cargo clippy

# 2. 官方标准格式化
cargo fmt

# 3. 过程宏与宏生成源码展开（透视 #[derive] 背后的真相）
cargo install cargo-expand
cargo expand

# 4. 未定义行为 (UB) 与内存别名虚拟机检测
cargo +nightly miri run

# 5. CPU 性能剖析与交互式火焰图生成
cargo install flamegraph
cargo flamegraph
```

---

## 🎯 4. 动手一键体检 (StudyLine Doctor)

在终端运行下面的命令，检测你当前的开发环境是否已就绪：

```bash
./studyline doctor
```
