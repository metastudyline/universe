# 阶段A实战工坊：手写多线程极速文本检索器 (Mini-Ripgrep)

> **前置知识**：已完成阶段 A 所有权、借用检查器与生命周期 · **预计耗时**：4 小时

---

## 🛠️ 项目目标

通过手写一个真正的 `ripgrep` 核心子集，彻底融会贯通阶段 A 核心概念：
1. **零拷贝生命周期**：全程使用 `&'a str` 借用切片，杜绝堆内存垃圾复制；
2. **读写互斥实战**：体验如何在没有 GC 的情况下保证多线程并发搜索绝对无 Data Race；
3. **分步 TDD 检验**：完成全部 Step并通过 `studyline workshop test workshopA-mini-grep`。

---

## 🚀 快速启动

```bash
./studyline workshop init workshopA-mini-grep
```
