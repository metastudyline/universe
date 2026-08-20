# R25: 借用检查器与别名异或可变性：Polonius Datalog 模型与 LLVM noalias 优化

> **一手文献与源码锚点**：Rust RFC 2094 Non-Lexical Lifetimes · Polonius 形式化规则集 · LLVM `noalias` Metadata Specification

---

## 1. 一手原典：别名异或可变性（Aliasing XOR Mutability）

Rust 的借用检查器（Borrow Checker）强制维持如下绝对不变量：

$$\text{Valid Borrows} \iff (\text{Shared}(x) \land \neg \text{Mutable}(x)) \oplus (\text{Mutable}(x) \land \text{Unique}(x))$$

- **`&T` (共享借用)**：只读、可自由复制（`Copy`）、协变（`Covariant`），允许多重只读别名；
- **`&mut T` (独占借用)**：读写、不可复制（`!Copy`）、不变（`Invariant`），在生命周期内排他独占。

---

## 2. LLVM `noalias` 性能红利

在 C 语言中，由于指针可能互为别名，编译器无法将循环中的内存加载提升到寄存器外：

```c
// C 语言：无法确定 a 和 b 是否指向同一内存
void add(int *a, int *b) {
    *a += *b; // 必须生成读 b -> 算 -> 写 a，无法充分流水线化
}
```

而在 Rust 中，`fn add(a: &mut i32, b: &i32)`：
- 编译器为 `a` 附加 `noalias` 属性；
- LLVM 优化器确信对 `a` 的写入绝不可能修改 `b` 的值，从而进行指令激进重排与自动 SIMD 向量化。

---

## 3. 形式化论证三段论 (Formal Syllogism)

- **大前提 ($P_1$)**：若优化器在编译期能确证某指针在当前作用域内无任何别名干扰，则可安全应用最高等级的寄存器缓存与指令流水线重排。
- **小前提 ($P_2$)**：Rust 类型系统通过借用检查器严格保证 `&mut T` 独占且无任何重叠别名。
- **归谬 ($R$)**：若允许 `&mut T` 与 `&T` 并存，则一次写入将悄无声息地使只读引用产生脏读，编译器优化将直接退化为保守的内存屏障。
- **结论 ($C$)**：∴ 借用检查器不仅是内存安全的护盾，更是编译期激进性能优化的终极基石。
