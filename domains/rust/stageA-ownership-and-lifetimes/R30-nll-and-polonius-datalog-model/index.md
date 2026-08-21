# R30: 非词法作用域生命周期 (NLL) 与 Polonius：CFG 点集、活性分析与图可达性

> **一手学术论文与规范锚点**：Rust RFC 2094 (NLL) · Polonius Datalog Rules (`origin_contains_loan_on_entry`) · Niko Matsakis (An alias-based formulation of the borrow checker)

---

## 1. 历史语境与问题发生学

在 Rust 2015 早期版本中，引用的生命周期严格绑定在语法块的大括号 `{}` 之间。这意味着：

```rust
fn example() {
    let mut data = vec![1, 2, 3];
    let r = &data[0]; // 借用开始
    println!("{}", r); // 最后一次使用点
    // 在旧版 Rust 中，r 的生命周期一直存活到本函数末尾大括号！
    data.push(4); // 早期报错：data 仍被 r 借用中！
}
```

2018 年，Rust 引入了划时代的 **NLL（Non-Lexical Lifetimes）**，将生命周期从“语法代码块”解放为“控制流图（CFG）上的真实活性区间（Liveness Points）”。

---

## 2. Polonius 的 Datalog 形式化模型

尽管 NLL 解决了 90% 的生命周期问题，但在处理**分支返回借用（Returning Borrow Problem）**时，由于 NLL 仍将生命周期看作附着在变量上的全局点集，依然会引发误报：

```rust
fn get_default<'m>(map: &'m mut HashMap<Key, Value>, key: Key) -> &'m mut Value {
    match map.get_mut(&key) {
        Some(val) => val, // 分支 1：返回借用
        None => {
            map.insert(key, default_val()); // 分支 2：NLL 仍可能报错误判借用未结束！
            map.get_mut(&key).unwrap()
        }
    }
}
```

Polonius 彻底重构了底层形式化语义：
- **基本实体**：不再将生命周期看作 CFG 点的集合，而是将 **Origin（生命周期参数）看作「借用（Loans）的集合」**。
- **Datalog 核心推导规则**：
  $$\text{origin\_contains\_loan}(O_2, L, P) \leftarrow \text{origin\_contains\_loan}(O_1, L, P),\ \text{subset}(O_1, O_2, P)$$
  $$\text{Error}(L, P) \leftarrow \text{loan\_invalidated\_at}(L, P) \land \text{loan\_live\_at}(L, P)$$

```
+-------------------------------------------------------------+
| Polonius 图可达性求解模型 (Polonius Reachability Model)      |
+-------------------------------------------------------------+
|  [Point P0: map.get_mut(&k)] ── 发起借用 Loan L1              |
|              │                                              |
|      ┌───────┴───────┐                                      |
|      ▼               ▼                                      |
|  [Some(val)]     [None] ── Loan L1 不可达！Origin 不包含 L1    |
|      │               │                                      |
|  返回外部 'm         └─ map.insert(...) 安全执行！无虚假冲突！ |
+-------------------------------------------------------------+
```

---

## 3. 形式化论证三段论 (Formal Syllogism)

- **大前提 ($P_1$)**：内存安全依赖于在资源被借用期间禁止使其失效的写操作，而非禁止所有语法上处于同一语句块的代码。
- **小前提 ($P_2$)**：Polonius 将借用检查建模为 Datalog 传递闭包与图可达性问题，能够在控制流分支级别精确隔离借用作用域。
- **归谬 ($R$)**：若继续将生命周期强行绑死在词法 AST 或全局粗粒度变量集上，将导致大量在数学上绝对安全的惯用模式被编译器误杀，迫使开发者滥用 Unsafe 或冗余克隆。
- **结论 ($C$)**：∴ 将借用分析形式化下沉至 Datalog 关系谓词系统是静态程序分析演进的必然方向。
