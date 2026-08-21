# R35: 生命周期子类型化与型变（Variance）：协变、逆变与 Invariance UAF 形式化证明

> **一手文献与规范锚点**：*The Rustonomicon: Subtyping and Variance* · Rust RFC 769 (Sound generic drop) · Barbara Liskov (LSP Substitution Principle)

---

## 1. 概念发生学：型变（Variance）是什么？

在类型系统中，若类型 $S$ 可以安全地替换类型 $T$，我们称 $S$ 是 $T$ 的**子类型（Subtype）**，记作：

$$S <: T$$

在 Rust 中，生命周期的包含关系定义了子类型：**活得久的生命周期是活得短的生命周期的子类型**。即若 `'long: 'short`，则：

$$'long <: 'short$$

型变（Variance）描述的是：**当类型构造器 $F\langle T\rangle$ 接收子类型作为泛型参数时，新类型 $F\langle S\rangle$ 与 $F\langle T\rangle$ 之间的子类型关系如何演化**：

1. **协变（Covariant）**：$S <: T \implies F\langle S\rangle <: F\langle T\rangle$ （保持方向）
2. **逆变（Contravariant）**：$S <: T \implies F\langle T\rangle <: F\langle S\rangle$ （反转方向）
3. **不变（Invariant）**：$F\langle S\rangle <: F\langle T\rangle \iff S == T$ （无子类型转换关系）

---

## 2. 为什么 `&'a mut T` 对 `T` 必须是不变（Invariant）？

很多开发者无法理解为什么 `&'a mut &'static str` 不能隐式转换为 `&'a mut &'local str`。我们构造一个**如果 `&mut T` 对 `T` 协变必然导致 UAF 内存破坏的反例**：

```rust
// 假定：&mut T 对 T 是协变的。
// 已知：'static: 'local => &'static str <: &'local str
// 假定推导：&mut &'static str <: &mut &'local str

fn evil_feeder<'local>(target: &mut &'local str, source: &'local str) {
    *target = source; // 写入短生命周期引用
}

fn exploit() {
    let mut static_ptr: &'static str = "I am immortal";
    {
        let local_payload: String = String::from("dangling memory");
        let local_ref: &str = &local_payload;

        // 如果 &mut T 协变，这里会隐式向上转型并通过编译：
        evil_feeder(&mut static_ptr, local_ref);
    } // local_payload 在此被 drop，栈内存释放！

    // 此时 static_ptr 依然拥有 &'static str 类型，但内部指针指向已被释放的内存：
    println!("{}", static_ptr); // 💣 触发 Use-After-Free (UAF)！
}
```

**数学证明结论**：可变引用拥有**写权限（In-place Mutation）**。一旦允许写入，必须强制保持泛型参数 $T$ 不变（Invariant），以阻止向长周期容器注入短周期指针。

---

## 3. `PhantomData` 型变与 DropCK 控制矩阵

| 幽灵类型标记 | 对 `T` 的型变 | DropCK 语义（析构检查） | 典型应用场景 |
| :--- | :--- | :--- | :--- |
| `PhantomData<*const T>` | **Covariant**（协变） | **非拥有（Non-owning）**：不持有 `T` 实例，析构时不递归检查 `T` | 自定义只读 Raw Slice 视图、只读迭代器 |
| `PhantomData<fn(T) -> T>` | **Invariant**（不变） | **非拥有（Non-owning）**：函数指针不持有 `T`，析构无所有权约束 | 自定义不变性容器、裸指针安全封装 |
| `PhantomData<T>` | **Covariant**（协变） | **严格拥有（Owning）**：假定拥有并在 Drop 中释放 `T` | `Vec<T>`, `Box<T>`, `NonNull<T>` 智能指针 |

---

## 4. 形式化论证三段论 (Formal Syllogism)

- **大前提 ($P_1$)**：若类型系统允许通过可变别名向长生命周期变量中写入短生命周期引用，则该变量在其外层作用域被解引用时必然产生野指针（UAF）。
- **小前提 ($P_2$)**：将 `&mut T` 对 $T$ 强制约束为不变性（Invariant），从静态类型层面彻底切断了短生命周期向长生命周期容器的非法流入。
- **归谬 ($R$)**：若为了所谓的语法灵活性而放松对 $T$ 的不变性限制，静态类型系统的健全性（Soundness）将彻底坍塌。
- **结论 ($C$)**：∴ 型变（Variance）与不变性规则构成了 Rust 静态无 GC 内存安全最严密的数学长城。
