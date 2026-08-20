# R21: 所有权三大定律与 Move 语义底层汇编：寄存器传递与零成本 Relocation

> **一手文献与源码锚点**：Rust 标准库 `library/core/src/mem/mod.rs` · `library/core/src/mem/manually_drop.rs` · System V AMD64 ABI 寄存器分配规约

---

## 1. 一手源码考据：`core::mem::forget` 的真正实现

在 Rust 标准库中，`mem::forget` 是如何做到“阻止析构函数运行”的？

```rust
// library/core/src/mem/mod.rs
#[inline]
#[stable(feature = "rust1", since = "1.0.0")]
#[rustc_const_stable(feature = "const_forget", since = "1.46.0")]
pub const fn forget<T>(t: T) {
    let _ = ManuallyDrop::new(t);
}

// library/core/src/mem/manually_drop.rs
#[lang = "manually_drop"]
#[derive(Copy, Clone, Debug, Default, PartialEq, Eq, PartialOrd, Ord, Hash)]
#[repr(transparent)]
pub struct ManuallyDrop<T: ?Sized> {
    value: T,
}
```

- **物理本质**：`ManuallyDrop<T>` 是一个带有编译器语言项 `#[lang = "manually_drop"]` 的透明包装结构体。
- **编译器行为**：Drop Elaboration（析构展开 Pass）在生成 MIR 时，**明确跳过该类型，不为其发射任何 Drop Glue 析构指令，也不为其分配 Drop Flag**。结构体所在的栈帧在函数返回时随 `RSP` 指针正常回弹，但其管理的堆内存不会被释放。

---

## 2. 所有权三大定律的底层汇编映射

```assembly
# Rust: fn consume(p: Point) -> u64
# struct Point { x: u64, y: u64 }
consume:
    movq %rdi, %rax     # 第一个 8 字节通过 %rdi 传递
    addq %rsi, %rax     # 第二个 8 字节通过 %rsi 传递
    ret                 # 零内存分配，零 memcpy，直接在 CPU 寄存器内完成 Move！
```

1. **第一定律**：Rust 中每一个值都有一个被称为其**所有者（Owner）**的变量；
2. **第二定律**：同一时间内，一个值只能拥有**唯一所有者**；
3. **第三定律**：当所有者离开作用域时，该值将被**自动丢弃（Dropped via Drop Glue）**。

---

## 3. 形式化论证三段论 (Formal Syllogism)

- **大前提 ($P_1$)**：若语言要求资源在离开作用域时自动且确定性地释放（RAII），则必须在静态编译期杜绝多个所有者重复释放（Double Free）的可能性。
- **小前提 ($P_2$)**：Rust 所有权规则规定变量赋值默认执行所有权转移（Move），并在类型系统中作废原变量绑定符号。
- **归谬 ($R$)**：若 Move 操作需要隐式调用运行期深拷贝或构造函数，则高频数据传递将带来不可控的 CPU 吞吐量惩罚。
- **结论 ($C$)**：∴ Rust 将 Move 约束为编译期符号失效加硬件级平凡浅拷贝（Trivially Relocatable / Register Passing），实现了真正的零成本所有权管理。
