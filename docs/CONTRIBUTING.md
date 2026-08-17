# StudyLine Universal Knowledge & Research Monorepo 贡献指南

> **欢迎来到全人类知识与科学研究的开放基础设施（Knowledge GitHub）！**  
> 我们的使命是构建一个去中心化、基于 DAG 拓扑依赖、严谨且多模态的人类知识网络。

---

## 1. 核心贡献原则

1. **客观构建主义**：
   - 知识结构本身是网络状的，但教学必须有**明确、可追溯的前置依赖（Prerequisites）**与掌握层次（0-5）。
   - 拒绝凭空引用未定义的术语或跳步推导。
2. **开放多模态容器**：
   - 每个知识节点是一个独立目录，包含 `manifest.yml` 与对应的多模态资产（讲义、LaTeX、Jupyter 代码、交互控件、一手文献）。
3. **机器严苛 CI 执法**：
   - 所有提交必须通过 `studyline-compiler` 校验（JSON Schema 契约校验 + 全网跨仓无环性扫描 + 科学计算确定性复现）。

---

## 2. 贡献工作流 (PR Step-by-Step)

```text
Fork 仓库 ➔ 本地创建分支 ➔ 新建知识节点 ➔ 本地校验 ➔ 提交 PR ➔ CI 自动化验证 ➔ CODEOWNERS 评审合入
```

### 第一步：创建知识节点目录
在对应学科目录下建立规范文件夹：
```bash
domains/<discipline>/<domain>/<topic>/<node_id>/
├── manifest.yml        # 核心元契约 (必须严格符合 node-manifest.schema.json)
├── index.md            # 核心学术/教学正文
└── [可选多模态文件]    # .ipynb, .vtt, .wasm, 交互组件
```

### 第二步：编写 `manifest.yml`
```yaml
id: "philosophy.ancient-greek.arche"
title: "本原问题与古希腊自然哲学的滥觞"
domain: "philosophy"
summary: "探讨从米利都学派泰勒斯的水本原说，到阿那克西曼德的阿派朗..."
schema_version: "1.0.0"
content_hash: "<sha256>"
license: "CC-BY-SA-4.0"
maintainers:
  - "@your-github-handle"
prerequisites:
  - target_node_id: "philosophy.foundation.myth-and-logos"
    dependency_type: "strict"
    min_mastery_level: 3
    rationale: "理解自然哲学必须先理解神话向理性的过渡"
assets:
  - asset_id: "lecture_notes"
    role: "lecture"
    mime_type: "text/markdown"
    relative_path: "index.md"
    checksum: "<sha256>"
    file_size_bytes: 4096
created_at: "2026-08-17T20:00:00Z"
updated_at: "2026-08-17T20:00:00Z"
```

### 第三步：本地编译与无环性校验
```bash
cd tools
cargo run -p studyline-compiler -- check --strict
```

### 第四步：发起 PR 与自动化评审
- 提交 PR 后，GitHub Actions CI 将在 <28 秒内完成验证；
- PR Diff Bot 会在评论区自动回复高亮展示的 Mermaid 局部拓扑差异图与波及范围（Blast Radius）。
- 对应领域的维护团队（CODEOWNERS）将进行同行学术评审与合并。

---

## 3. 遇到教学卡点？
在学习任何节点时遇到断层或概念缺失，请直接提交 [🚨 教学断层与认知卡点反馈](.github/ISSUE_TEMPLATE/01_pedagogical_breakage.yml)，您的每一次卡点都在帮助全人类知识网络自愈。
