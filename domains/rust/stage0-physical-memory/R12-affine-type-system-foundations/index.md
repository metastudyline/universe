# R12: 形式化类型论起步：线性逻辑与仿射类型系统（Affine Types）数学模型

> **一手文献与源码锚点**：Jean-Yves Girard (1987) *Linear Logic* (Theoretical Computer Science) · Philip Wadler (1990) *Linear types can change the world!*

---

## 1. 一手数学推导：结构规则与类型系统的四象限

在形式逻辑与类型论中，管理假设/资源的关键在于两个**结构规则（Structural Rules）**：

$$\begin{aligned}
\text{Weakening (弱化律)} &: \quad \frac{\Gamma \vdash e : B}{\Gamma, x : A \vdash e : B} \quad (\text{允许丢弃资源}) \\
\text{Contraction (收缩律)} &: \quad \frac{\Gamma, x : A, y : A \vdash e : B}{\Gamma, z : A \vdash e[z/x, z/y] : B} \quad (\text{允许复制使用资源})
\end{aligned}$$

| 类型系统分类 | Weakening (丢弃) | Contraction (复制) | 使用次数限制 | 对应语言特性 |
| :--- | :--- | :--- | :--- | :--- |
| **Linear (线性)** | $\times$ 禁止 | $\times$ 禁止 | 恰好 1 次 ($=1$) | 必须显式消费，禁止隐式丢弃 |
| **Affine (仿射)** | $\checkmark$ 允许 | $\times$ 禁止 | 最多 1 次 ($\le 1$) | **Rust 核心所有权 (Move + 隐式 Drop)** |
| **Relevant (相关)** | $\times$ 禁止 | $\checkmark$ 允许 | 至少 1 次 ($\ge 1$) | 禁止泄漏，允许随意克隆 |
| **Unrestricted (经典)**| $\checkmark$ 允许 | $\checkmark$ 允许 | 任意次 ($\omega$) | C/C++/Java/Python 传统类型 |

---

## 2. 形式化论证三段论 (Formal Syllogism)

- **大前提 ($P_1$)**：若类型系统禁止收缩律（Contraction），则任何试图在赋值或传参时隐式复制资源的行为都将被编译器拒绝，强行将操作映射为所有权转移（Move）。
- **小前提 ($P_2$)**：若类型系统允许弱化律（Weakening），则未被后续消费的资源可以安全存留并在作用域结束时统一应用析构规则（Drop）。
- **归谬 ($R$)**：若 Rust 采用严格的线性类型系统（禁止弱化），则每次使用变量都必须手动调用消费函数，代码将充斥着冗余的人工释放样板；若采用经典无限制类型系统，则无法阻止浅拷贝带来的 Double Free。
- **结论 ($C$)**：∴ 仿射类型系统是兼顾“零运行时双重释放安全”与“RAII 自动确定性析构人体工学”的终极数学解。
