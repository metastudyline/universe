# Implementation Plan: StudyLine Universal Knowledge & Research Open Infrastructure

**Feature Identifier**: `001-studyline-universal-knowledge-engine`  
**Status**: Ready & Approved (Full Architecture Baseline)  
**Created**: 2026-08-17  
**Spec Document**: [spec.md](./spec.md)  
**Research Document**: [research.md](./research.md)  
**Data Model**: [data-model.md](./data-model.md)  
**Contracts**: [contracts/](./contracts/)  
**Quickstart**: [quickstart.md](./quickstart.md)  

---

## 1. Technical Context & System Overview

### 1.1 全球基础设施与联邦架构 (Global Infrastructure & Federation)
- **核心定位**：全人类知识与科学研究的开源协作基础设施（Knowledge GitHub / Federated Hub-and-Spoke Architecture）。
- **母仓库 (`studyline/universe`)**：
  - 维护全局 DAG 拓扑总索引、Draft-07 Schemas 元契约、全局 CI 编译器与联邦注册表 (`registry.yml`)。
  - 体积极小（<50MB），全网广播不可变零拷贝快照 (`global_graph.rkyv`)。
- **子仓库 (`studyline/domain-*` / 第三方仓库)**：
  - 按学科与组织独立自治，承载开放多模态知识容器（`manifest.yml`、`index.md`、交互沙箱、数据集、影印件）。
  - 配置独立的 CODEOWNERS、Issue 看板与 Release 周期。
  - 支持 Git Sparse-Checkout (Cone Mode) + Partial Clone (`--filter=blob:none`) 抵御索引膨胀。

### 1.2 客户端双层渲染与计算引擎 (Dual-Layer Client Rendering Pipeline)
- **宏观知识宇宙引擎 (Macro Canvas Engine)**：
  - 基于 WebGPU / WebGL + 视距分级渲染（LOD 10% 星云热力 ➔ 50% 知识组与金色学线 ➔ 100% 节点卡片）。
  - 集成 Rust `studyline-graph-core` WASM 模块，单源拓扑 DP 学线规划 $<2\text{ms}$，端侧完全离线运行。
- **微观多模态胶囊引擎 (Micro Multimodal Capsule Engine)**：
  - **Tier 1 (Native DOM + Pretext)**: Markdown 讲义、KaTeX 动态公式、Mermaid 概念图，基于 DOMPurify 严格净化，断裂重连链表排版。
  - **Tier 2 (Web Worker + Pyodide/Lean WASM)**: Jupyter Python 与形式化证明本地计算沙箱，带看门狗超时监控，UI 保持 60fps。
  - **Tier 3 (Sandboxed IFrame)**: GeoGebra、Observable、Manim WebGL 运行于 `sandbox="allow-scripts"`（无 `allow-same-origin`，赋予独一无二 `null` 源）独立沙箱中，彻底防御 XSS。
- **双向视听联动与浮动 HUD (Sync & Floating HUD)**：
  - 基于 WebVTT `cuechange` 事件：看视频时自动平滑滚动高亮讲义段落；读讲义点击公式/文字精准反向 Seek 视频播放秒数。
  - 遇到前置术语点击直接在侧边呼出浮动微缩卡片（Dynamic Window），打破第四面墙且不中断专注心流。

### 1.3 自动化流水线 (Knowledge CI & Bot Workflow)
- **GitHub Actions 并行 CI 流水线 (<28s 预算)**：
  - `studyline-compiler` 进行全库 Draft-07 JSON Schema 校验与 DAG 无环性检测。
  - 逆向依赖传递闭包（Roaring Bitmap）计算 Blast Radius，精准收敛下游回归测试。
  - 科学可复现性沙箱：`uv` + `Papermill` + `pytest-mpl` 容差断言。
  - PR Mermaid Visual Diff Bot：在 PR 评论区自动原地更新 2-Hop 局部拓扑差分矢量图。

---

## 2. Constitution & Principles Check

| 准则 | 评估结论 | 架构设计保障 |
| :--- | :---: | :--- |
| **反双重异化** | 满足 | 开放开源结构，知识主权归属全人类，不设封闭付费墙或流水线强制开班制。 |
| **客观构建主义** | 满足 | DAG 依赖拓扑锚定客观教学依赖；开放容器与学派分叉（Fork）包容主观建构多元性。 |
| **极简公共契约** | 满足 | 仅以 `manifest.yml`（DAG 依赖+掌握六层次）为唯一强制规范，解耦多模态表达。 |
| **造钟而非报时** | 满足 | 机器严苛 CI 执法 + 自动化卡点反馈 Issue + CODEOWNERS 分层治理，实现去中心化自演进。 |
| **联邦自治与普遍联系** | 满足 | Hub-and-Spoke 架构确保学科小仓库轻量独立，母仓库总索引保证全网跨学科串联。 |
| **零裸通配类型** | 满足 | 所有外部接口与系统边界定义在 `contracts/` 下强类型 JSON Schema（Draft-07）。 |

---

## 3. Phase 0: Research Items (已完备)

- [x] **R001** `[SUBAGENT:research]` 《超大规模知识拓扑 DAG 在 Git 上的存储格式、增量索引与高性能拓扑算法选型》：完成层级目录、Sparse-checkout、petgraph/rkyv 与 RoaringBitmap 爆炸半径设计。（见 [research.md](./research.md#1-r001-超大规模知识拓扑-dag-在-git-上的存储格式与高性能拓扑算法选型)）
- [x] **R002** `[SUBAGENT:research]` 《基于 GitHub Actions 的 Knowledge CI 编译器与自动化评审工作流架构》：完成 Rust 统一校验 CLI、uv+Papermill 科学复现沙箱与 GitHub 原生 Mermaid Diff Bot 设计。（见 [research.md](./research.md#2-r002-基于-github-actions-的-knowledge-ci-编译器与自动化评审工作流)）
- [x] **R003** `[SUBAGENT:research]` 《开放多模态知识容器（Open Knowledge Container）的安全渲染与插件化架构》：完成三层分流安全沙箱（DOM/Worker/IFrame）、MIME 插件注册表与 WebVTT 双向时间轴联动状态机设计。（见 [research.md](./research.md#3-r003-开放多模态知识容器的安全渲染与插件化架构)）

---

## 4. Phase 1: Design Artifacts & Contracts Index (已完备)

- [x] **Data Model**：[`data-model.md`](./data-model.md) — 强类型知识与联邦实体模型（`KnowledgeHubRegistry`, `FederatedDomainRepository`, `KnowledgeNode`, `DependencyEdge`, `MultimodalAsset`, `KnowledgePullRequest`）。
- [x] **System Contracts (1:1 边界强类型 JSON Schema)**：
  - `[SUBAGENT:research]` [`contracts/node-manifest.schema.json`](./contracts/node-manifest.schema.json) — 知识节点元数据与 DAG 依赖边界规范。
  - `[SUBAGENT:research]` [`contracts/hub-registry.schema.json`](./contracts/hub-registry.schema.json) — 母仓库全局联邦子仓注册表规范。
  - `[SUBAGENT:research]` [`contracts/knowledge-pr-webhook.schema.json`](./contracts/knowledge-pr-webhook.schema.json) — 知识 PR 提交、CI 校验状态与 Blast Radius 事件三元组契约。
  - `[SUBAGENT:research]` [`contracts/studyline-render-rpc.schema.json`](./contracts/studyline-render-rpc.schema.json) — 客户端宿主与多模态 IFrame / Web Worker 沙箱间 JSON-RPC 2.0 双向通信契约。
- [x] **Quickstart Validation**：[`quickstart.md`](./quickstart.md) — 包含端到端 DAG 校验、科学计算复现与沙箱渲染测试的场景化执行手册。

---

## 5. Component Impact Analysis (按组件落地清单)

```text
studyline-universe/                        # 母仓库 (Global Hub)
├── schemas/                               # 核心强类型契约 (Draft-07)
│   ├── node-manifest.schema.json
│   ├── hub-registry.schema.json
│   ├── knowledge-pr-webhook.schema.json
│   └── studyline-render-rpc.schema.json
├── registry.yml                           # 全网联邦子仓库注册表
├── tools/studyline-compiler/               # Rust 核心拓扑编译与跨仓校验 CLI
│   ├── Cargo.toml
│   ├── src/
│   │   ├── main.rs
│   │   ├── dag.rs                        # petgraph DAG 算法与 Tarjan 环检测
│   │   ├── registry_loader.rs            # 联邦子仓拉取与全局大图组装
│   │   ├── validator.rs                  # jsonschema 校验与死链扫描
│   │   └── diff.rs                       # Mermaid 差分图与 Blast Radius 计算
├── .github/                                # 母仓 Actions 流水线
│   ├── CODEOWNERS                        # 全局 TSC 治理矩阵
│   └── workflows/knowledge_ci.yml        # 跨仓全局 DAG 校验流水线
│
studyline-domain-philosophy/               # 示例学科子仓库 (Spoke)
├── .github/CODEOWNERS                     # 哲学学科 Maintainers
├── 0_myth_and_language/
│   └── node_arche/manifest.yml
└── A_ancient_greece/
│
packages/studyline-renderer/               # 客户端双层渲染核心包
├── src/
│   ├── macro_canvas/                     # WebGPU/LOD 知识宇宙渲染器
│   ├── micro_capsule/                    # Pretext + 三层沙箱调度器
│   ├── media_sync.ts                     # WebVTT 双向时间轴联动状态机
│   └── floating_hud.ts                   # 浮动上下文微缩卡片管理器
```
