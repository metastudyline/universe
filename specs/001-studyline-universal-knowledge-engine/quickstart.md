# Quickstart & Validation Guide: StudyLine Universal Knowledge Infrastructure

**Feature Identifier**: `001-studyline-universal-knowledge-engine`  
**Status**: Ready for Validation  
**Created**: 2026-08-17  

---

## 1. 概述与前置准备 (Prerequisites)

本指南提供对 StudyLine 核心基础设施三大关键链路的端到端可复现验证场景：
1. **全库 DAG 依赖与 Schema 强类型编译验证**（Rust 核心引擎与无环性检测）
2. **PR 增量变更分析与 Blast Radius 差分计算**（逆向依赖传递闭包与 Mermaid 导出）
3. **科学计算沙箱与可复现性回归测试**（Jupyter Notebook + Papermill + 数值容差断言）

### 前置环境要求
- **Rust Toolchain**: `cargo >= 1.80`
- **Python**: `python >= 3.11` + `uv`
- **Git**: `git >= 2.40` (支持 Sparse-checkout Cone Mode)

---

## 2. 场景化验证步骤 (Verification Scenarios)

### Scenario 1: 全库 DAG 拓扑无环性与 Schema 验证
验证 `studyline-compiler` 对全库数十万节点的 Draft-07 Schema 与拓扑有向无环图进行高并发扫描。

- **Command**:
  ```bash
  cargo run --release -p studyline-compiler -- check --schemas-dir ./schemas --domains-dir ./domains --strict
  ```
- **Expected Output**:
  ```text
  [INFO] Scanning schemas in ./schemas (3 contracts loaded)... OK
  [INFO] Validating 10,420 knowledge node manifests across 6 domains...
  [INFO] Building Dependency DAG (Nodes: 10,420, Edges: 48,930)...
  [INFO] Running Kahn Topological Sort & Tarjan SCC Cycle Detector...
  [SUCCESS] All schemas valid. DAG is strictly acyclic. (Elapsed: 420ms)
  ```
- **Failure Diagnostic**:
  - *若输出 `[ERROR] DAG_CYCLE_DETECTED: Cycle found: node_A -> node_B -> node_C -> node_A`*：
    - **排查路径**：运行 `cargo run -p studyline-compiler -- trace-cycle --node node_A`，定位引入循环依赖的 `manifest.yml`，移除错误的循环前置边。
  - *若输出 `[ERROR] SCHEMA_VALIDATION_ERROR in domains/.../manifest.yml`*：
    - **排查路径**：检查报错节点的 JSON/YAML 字段是否遗漏 `min_mastery_level` 或不符合 `node-manifest.schema.json` 规范。

---

### Scenario 2: PR 增量变更分析与 Mermaid Visual Diff 导出
模拟在某一基础哲学节点（如笛卡尔）修改掌握层次要求，验证是否能在 2ms 内精准计算下游传递闭包（Blast Radius）并输出差异图。

- **Command**:
  ```bash
  cargo run --release -p studyline-compiler -- diff \
    --base origin/main \
    --head HEAD \
    --format mermaid \
    --k-hop 2 \
    --output ./target/pr_diff_report.json
  ```
- **Expected Output**:
  ```text
  [INFO] Git diff detected: 1 node modified (philosophy.modern.descartes-dualism)
  [INFO] Calculating Inverted Graph Reachability (Blast Radius)...
  [INFO] Direct Changed: 1, Downstream Affected Nodes: 14, Impacted Paths: 3
  [SUCCESS] Mermaid differential diagram generated at ./target/pr_diff_report.json (Elapsed: 1.8ms)
  ```
- **Failure Diagnostic**:
  - *若输出 `[ERROR] UNKNOWN_BASE_COMMIT: Cannot resolve origin/main`*：
    - **排查路径**：运行 `git fetch origin main` 获取远端最新引用后再执行 diff。

---

### Scenario 3: 科学计算节点 Jupyter 可复现性与数据容差测试
验证科研知识节点的 Python/Jupyter Notebook 能否在沙箱中自动跑通并与基准数据完成容差断言。

- **Command**:
  ```bash
  uv run pytest --nbval-lax -v domains/mathematics/linear-algebra/eigenvalues/tests/test_reproducibility.py
  ```
- **Expected Output**:
  ```text
  ============================= test session starts ==============================
  collecting ... collected 3 items

  test_reproducibility.py::test_notebook_executes_without_error PASSED   [ 33%]
  test_reproducibility.py::test_eigenvalue_numerical_precision PASSED    [ 66%]
  test_reproducibility.py::test_spectrum_plot_svg_consistency PASSED     [100%]

  ============================== 3 passed in 4.12s ===============================
  ```
- **Failure Diagnostic**:
  - *若输出 `AssertionError: Arrays are not equal: rtol=1e-05, atol=1e-08`*：
    - **排查路径**：检查实验脚本中的随机种子是否固定（如 `np.random.seed(42)`），核对 CPU 浮点运算精度设置。

---

## 3. 性能基准校验 (Performance Benchmarks)

执行基准测试验证符合系统白皮书与 Success Criteria 指标：
```bash
cargo bench -p studyline-graph-core
```
- **断言目标**：
  - 单源拓扑 DP 学线生成（10 万节点）: $< 5\text{ms}$ (白皮书 SC-01: $<200\text{ms}$)
  - 逆依赖传递闭包计算（10 万节点）: $< 2\text{ms}$
  - Rkyv 零拷贝图加载: $< 3\text{ms}$
