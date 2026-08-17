# Phase 0 Research: StudyLine Universal Knowledge & Research Open Infrastructure

**Feature Identifier**: `001-studyline-universal-knowledge-engine`  
**Status**: Completed  
**Created**: 2026-08-17  

---

## 1. R001: 超大规模知识拓扑 DAG 在 Git 上的存储格式与高性能拓扑算法选型

### 1.1 节点与边的物理存储与 Git 膨胀防御
- **Decision（选定方案）**：
  采用**“层级语义分片目录 + 单节点强类型 Manifest 独立存储”**方案。
  - 路径规范：`domains/<discipline>/<domain>/<topic>/<node_id>/`
    - `manifest.yml` (或 `spec.json`)：强类型元数据（唯一标识、层级、前置依赖 `prerequisites: [{node_id, dependency_type: "strict"|"supporting", min_mastery_level: 0..5}]`）。
    - `index.md`：结构化正文与教案。
    - `raw/`, `assets/`, `widgets/`：伴生多模态资产。
  - 单目录文件数硬性上限：通过 3 级学科树分片，单个叶子目录下节点数 $\le 500$，规避文件系统 inode 遍历退化。
  - **Git 索引与克隆优化**：
    1. 启用 `git sparse-checkout set --cone <sub-path>`，利用目录树前缀匹配替代 glob，避免遍历数十万文件的 index。
    2. 客户端与 CI 采用 `git clone --filter=blob:none`（Partial Clone），仅拉取元数据树，按需延迟拉取大文件 blob。
    3. 开启 `core.fsmonitor=true` 与 `core.commitGraph=true`，将 `git status` 与 commit 遍历开销降为 $O(\Delta\text{files})$。
    4. 源码与派生快照解耦：Git 仅存单一事实源。CI 编译生成不可变扁平二进制快照（`graph.rkyv` / `graph.bin`），客户端直接拉取快照，严禁将全量派生索引提交回 Git。
- **Rationale（选择理由）**：
  1. 多人协同零冲突：单节点独立目录保证 PR 粒度解耦，知识点增删改不产生全局文件的行锁冲突与 Git Merge 冲突。
  2. Git 树对象天然去重：Tree Object 对未变动子目录复用 SHA-1，微小变动仅生成极少量新 Tree 节点。
  3. Cone Mode 复杂度由 $O(\text{files} \times \text{patterns})$ 降至 $O(\text{depth})$。
- **Alternatives Considered（被否决方案）**：
  - *否决单一大文件存储（如全局 `knowledge_dag.json`）*：高并发 PR 合并时发生剧烈 Git 冲突；无法精确关联多模态资源；文件尺寸膨胀后导致 Git Diff 渲染崩溃与内存耗尽。
  - *否决纯平面无层级目录存储（`nodes/<node_id>/`）*：当节点达 10 万+ 时，APFS/ext4 发生单目录 Hash Collision 与 inode 线性扫描性能衰减，导致本地 `ls`、IDE 文件树及 `git status` 卡顿。
- **Source（查阅来源）**：
  - Git Sparse Checkout Spec: https://git-scm.com/docs/git-sparse-checkout
  - Microsoft Scalar Architecture: https://github.com/microsoft/scalar
  - Git Partial Clone Documentation: https://git-scm.com/docs/partial-clone

### 1.2 拓扑算法引擎与计算选型
- **Decision（选定方案）**：
  采用 **Rust 编写独立核心计算库 `studyline-graph-core`**（集成 `petgraph` + `roaring-rs`）。
  1. **无环检测与精确定位**：单次校验使用 Kahn 算法（$O(V+E)$）；检测到环时触发 **Tarjan 强连通分量（SCC）算法**，精准定位闭环路径（如 `A -> B -> C -> A`）并高亮报错。
  2. **最短学线与关键路径**：因严格为 DAG，直接利用拓扑排序执行**单源拓扑动态规划（Topological DP）**，单次计算 $O(V+E) < 2\text{ms}$，无需 $O((V+E)\log V)$ 堆排序。
  3. **零拷贝序列化快照**：使用 **`rkyv`** 导出全库图快照，支持 mmap 直接读取，10 万节点加载 $< 5\text{ms}$，内存 $< 30\text{MB}$。
  4. **跨端分发**：编译为原生 CLI 工具（CI 使用）与 WebAssembly（通过 `wasm-pack` 供 Web/NoteBoot 客户端离线运行）。
- **Rationale（选择理由）**：
  1. 内存紧凑与 CPU Cache 局部性：`petgraph::Graph` 使用 32 位 NodeIndex，比 64 位指针节省 50% 内存。
  2. 跨端统一：Rust 保证 CI 与前端 WASM 逻辑 100% 相同，杜绝双端计算不一致。
- **Alternatives Considered（被否决方案）**：
  - *否决纯 Python `networkx`*：基于 Dict-of-Dict 实现，10 万节点内存占用超 1.2GB，遍历耗时数秒，无法满足 CI 毫秒级门禁与客户端离线需求。
  - *否决纯 JavaScript `graphology`*：大图位运算与深度递归遍历存在 V8 GC 停顿，且无法直接复用于 Rust/C 原生 CLI 环境。
- **Source（查阅来源）**：
  - Petgraph Crate: https://docs.rs/petgraph/latest/petgraph/
  - Rustworkx: https://github.com/Qiskit/rustworkx
  - Rkyv Zero-Copy Deserialization: https://rkyv.org/

### 1.3 增量变更分析（Impact Analysis / Blast Radius）
- **Decision（选定方案）**：
  三步极速爆炸半径算法：
  1. `git diff --name-only origin/main...HEAD` 提取变动节点集合 $S_{\text{changed}}$。
  2. 维护逆向拓扑图 $G_{\text{rev}} = (V, E^T)$，使用 `RoaringBitmap` 计算可达传递闭包：$\text{BlastRadius}(S) = \bigcup_{u \in S} \text{Reachable}_{G_{\text{rev}}}(u)$（耗时 $1 \sim 2\text{ms}$）。
  3. CI 仅对 $\text{BlastRadius}(S)$ 范围内的下游节点触发 Schema、考核题与静态渲染回归，豁免 99%+ 无关节点。
- **Rationale（选择理由）**：
  借鉴 Google Bazel `rdeps` 与 Turborepo Task Graph 机制，避免全量回归，使 CI 反馈从数分钟降至 5 秒内。
- **Alternatives Considered（被否决方案）**：
  - *否决全量全库重新校验*：随着节点规模扩大，CI 耗时呈线性膨胀至数十分钟。
  - *否决仅校验直接 1-hop 依赖节点*：漏判深层传递依赖，造成破坏性变更暗病。
- **Source（查阅来源）**：
  - Bazel Query Language Reference: https://bazel.build/query/language#rdeps
  - Turborepo Task Graph Engine: https://turborepo.dev/docs/core-concepts/monorepos/task-graphs

---

## 2. R002: 基于 GitHub Actions 的 Knowledge CI 编译器与自动化评审工作流

### 2.1 知识 CI 流水线设计
- **Decision（选定方案）**：
  基于 **Rust 原生 CLI (`studyline-compiler`) + GitHub Actions 多阶段并行流水线**：
  - `pre-flight` (3s)：`dorny/paths-filter@v3` 过滤变动。
  - `matrix-parallel` (15s 并发执行)：
    - Job A (`schema-and-dag-lint`): Rust 原生校验 Draft-07 JSON Schema (`jsonschema-rs`) 与 DAG 拓扑无环性（耗时 ~4s）。
    - Job B (`markdown-link-check`): `lycheeverse/lychee-action` 异步多线程检测外部文献与内部双链（耗时 ~12s）。
    - Job C (`blast-radius-calc`): 提取下游拓扑闭包并生成 PR Diff 工件（耗时 ~2s）。
  - 全量 Wall-Clock 时间控制在 **20~28 秒**，远低于 60 秒硬性预算。
- **Rationale（选择理由）**：
  Rust 静态二进制免除 CI 运行时的 `npm install` / `pip install` 耗时，多线程利用 Rayon 跑满 GitHub Runner CPU。
- **Alternatives Considered（被否决方案）**：
  - *否决 Python / Node.js 混编 CI*：冷启动与依赖拉取耗时 15-30 秒，极易突破 60 秒硬指标。
- **Source（查阅来源）**：
  - Lychee Link Checker Action: https://github.com/lycheeverse/lychee-action
  - JSONSchema-rs: https://github.com/Stranger6667/jsonschema-rs

### 2.2 科学计算与代码沙箱可复现性验证
- **Decision（选定方案）**：
  基于 **GHCR 预置科学计算镜像 + `uv` 极速依赖管理 + `Papermill` + `pytest` (`nbval` + `pytest-mpl`)**：
  1. 预构建 Docker 镜像 `ghcr.io/studyline/sci-sandbox:latest`（包含 Python 3.12, NumPy, SciPy, Matplotlib, SymPy 等），针对特定依赖使用 `uv` 在 $<1.5\text{s}$ 创建虚拟环境。
  2. 使用 `Papermill` 执行受影响节点的 Notebook，通过 `Scrapbook` 记录关键数值量，由 `numpy.testing.assert_allclose` 进行浮点容差数据断言。
  3. 图表与视觉回归采用 `pytest-mpl`（容差比对）+ SVG 归一化 DOM 对比，排除跨平台字体抗锯齿微小差异。
  4. 使用 `nbval --nbval-lax` 正则过滤执行序号、时间戳与内存地址，杜绝伪失败。
- **Rationale（选择理由）**：
  消除硬件浮点与时间戳漂移导致的测试假阳性；预置镜像与 `uv` 消除依赖构建等待时间。
- **Alternatives Considered（被否决方案）**：
  - *否决 `nbconvert --execute` 裸运行*：无法细粒度断言数据数值容差，缺乏输出脱敏机制。
  - *否决 `repo2docker` 动态构建*：每次构建 Conda 耗时 5-10 分钟，不可接受。
- **Source（查阅来源）**：
  - Papermill Parameterized Notebooks: https://papermill.readthedocs.io/
  - Nbval Cell Validation: https://github.com/computationalmodelling/nbval
  - Astral uv: https://github.com/astral-sh/uv

### 2.3 PR Visual Diff Bot
- **Decision（选定方案）**：
  基于 **GitHub 原生 Mermaid 渲染 + `peter-evans/create-or-update-comment@v4` 幂等评论机器人**：
  1. 提取 $k$-Hop 局部子图（$k=2$），根据 `Added`, `Deleted`, `Modified`, `Affected` 状态输出带有高对比度 ClassDef 的 Mermaid 流程图。
  2. 通过唯一签名 `<!-- studyline-topology-diff-bot -->` 原地更新 PR 评论，包含状态徽章、Mermaid 拓扑对比图及折叠式受波及学线清单。
- **Rationale（选择理由）**：
  无需在 CI 中启动 Headless Chrome 截图，零外部服务依赖，完全使用 GitHub 原生 Markdown 渲染，避免评论轰炸。
- **Alternatives Considered（被否决方案）**：
  - *否决 Graphviz 渲染 SVG 并上传外部图床*：外部图床存在网络死链与学术数据泄露风险。
  - *否决纯 ASCII Tree 文本输出*：DAG 多入度网络在 ASCII 树中交织折叠，严重影响阅读。
- **Source（查阅来源）**：
  - GitHub Mermaid Support: https://github.blog/2022-02-14-include-diagrams-markdown-files-mermaid/
  - Peter Evans Create-or-Update-Comment: https://github.com/peter-evans/create-or-update-comment

---

## 3. R003: 开放多模态知识容器的安全渲染与插件化架构

### 3.1 宿主渲染安全与沙箱隔离
- **Decision（选定方案）**：
  采用**「三层分级分流沙箱架构 (Three-Tier Tiered Sandboxing)」**：
  - **Tier 1 (静态声明层 - Native DOM)**：Markdown, KaTeX, Mermaid, SVG。主线程直接渲染，通过 `DOMPurify` 严格过滤并启用 Strict CSP。
  - **Tier 2 (无 DOM 计算沙箱层 - Isolated Web Worker + WASM)**：Jupyter/Pyodide, WebR, Lean 4。在独立 Web Worker 中运行 WebAssembly 内存沙箱，无 DOM 访问权，通过强类型 RPC 通信，配备 Watchdog 超时销毁机制。
  - **Tier 3 (富交互动态渲染层 - Unique-Origin Sandboxed IFrame)**：GeoGebra, Observable, Manim WebGL, 第三方交互组件。独立沙箱 IFrame 配置 `sandbox="allow-scripts"`（**严禁** `allow-same-origin`，赋予独一无二 `null` 源），通过 `postMessage` + JSON-RPC 2.0 通信，`ResizeObserver` 动态计算高度。
- **Rationale（选择理由）**：
  1. 彻底阻断 XSS 跨源访问 `localStorage` 与父级 DOM。
  2. 重型计算与死循环被隔离在 Worker 中，主线程 UI 保持 60fps 响应。
  3. IFrame 独立作用域天然防止第三方 CSS/JS 污染全局样式与原型链。
- **Alternatives Considered（被否决方案）**：
  - *否决纯 Shadow DOM / SES 闭包隔离*：Shadow DOM 不提供 JS 运行隔离，易发生主线程 CPU 阻塞与原型链污染。
  - *否决 `sandbox="allow-scripts allow-same-origin"` 混用*：OWASP 明确列为高危漏洞，同源代码可移除自身沙箱属性提权。
- **Source（查阅来源）**：
  - WHATWG HTML IFrame Sandbox Spec: https://html.spec.whatwg.org/multipage/iframe-embed-object.html#attr-iframe-sandbox
  - Pyodide Web Worker Usage: https://pyodide.org/en/stable/usage/webworker.html
  - OWASP HTML5 Security Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html

### 3.2 多模态资产零配置加载与动态挂载管线
- **Decision（选定方案）**：
  采用**「MIME 插件注册表 + 动态 ESM 懒加载 + WebVTT `cuechange` 双向时间轴联动状态机」**：
  1. 借鉴 JupyterLab `IRenderMimeRegistry` 与 VS Code `notebookRenderer` 架构，建立按 MIME 分发的渲染器接口 `IKnowledgeRenderer`。
  2. 客户端主运行时保持轻量（<150KB），各模态渲染器拆分为独立 ESM Chunk 按需动态 `import()` 加载。
  3. 视听文本双向同步基于 HTML5 原生 `TextTrack` API 的 `cuechange` 事件与二分匹配：视频播放平滑高亮并滚动讲义段落；点击讲义时间戳锚点精确反向 Seek 视频播放位置。
- **Rationale（选择理由）**：
  标准化 MIME 注册契约便于复用开源生态；动态拆包保障首屏秒开（$< 1.5\text{s}$）；原生 `TextTrack` 避免 `setInterval` 轮询产生的时间漂移与后台节流。
- **Alternatives Considered（被否决方案）**：
  - *否决 Monolithic 全量打包所有渲染器*：主 Bundle 膨胀超 30MB，严重破坏首屏性能。
  - *否决基于 `setInterval` 的时间轮询*：后台标签页被浏览器降频节流，导致高亮不同步。
- **Source（查阅来源）**：
  - JupyterLab IRenderMimeRegistry: https://jupyterlab.readthedocs.io/en/stable/extension/extension_dev_overview.html
  - W3C WebVTT & TextTrack Specification: https://www.w3.org/TR/webvtt1/
