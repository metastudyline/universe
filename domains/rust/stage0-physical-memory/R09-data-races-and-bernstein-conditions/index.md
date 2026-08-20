# R09: 经典缺陷发生学 III：数据竞争（Data Race）与 Bernstein 并发条件失效

> **一手文献与源码锚点**：A. J. Bernstein (1966) *Analysis of Programs for Parallel Processing* (IEEE Transactions on Electronic Computers) · C++11 内存模型 ISO/IEC 14882:2011 (Section 1.10)

---

## 1. 一手数学公理：Bernstein 并发条件

设两个并发任务 $T_1$ 与 $T_2$，其读取数据集为 $R(T_i)$，写入数据集为 $W(T_i)$。当且仅当满足以下 Bernstein 条件时，两任务并发执行方可保证结果的确定性：

$$\begin{cases}
R(T_1) \cap W(T_2) = \emptyset & \text{(禁止读写冲突 / RAW 冒险)} \\
W(T_1) \cap R(T_2) = \emptyset & \text{(禁止写读冲突 / WAR 冒险)} \\
W(T_1) \cap W(T_2) = \emptyset & \text{(禁止写写冲突 / WAW 冒险)}
\end{cases}$$

- **硬件并发放大**：现代多核 CPU（x86 / ARM）存在写缓冲区（Store Buffer）与乱序执行引擎，未受保护的数据竞争会导致不同核心观察到的内存状态完全错乱。

---

## 2. 形式化论证三段论 (Formal Syllogism)

- **大前提 ($P_1$)**：若多线程并发访问同一内存位置且包含写操作，在无硬件级内存屏障或同步偏序下必然产生数据竞争与脏读。
- **小前提 ($P_2$)**：Rust 的借用检查器要求在编译期证明：任何时刻对数据的访问要么是全部只读共享（$W = \emptyset$），要么是单线程唯一独占（独占所有权或 `&mut`，不存在并发任务）。
- **归谬 ($R$)**：若允许自由跨线程共享可变裸指针，则任何多线程程序都将处于不可预测的未定义行为之中。
- **结论 ($C$)**：∴ 别名异或可变性公理在并发维度上天然等价于 Bernstein 条件，从语言定义层面达成了“无畏并发（Fearless Concurrency）”。
