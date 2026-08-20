# R03: 栈帧（Stack Frame）的物理本质：RSP 指针、调用规约与局部变量确定性销毁

> **一手文献与源码锚点**：System V Application Binary Interface (AMD64 Architecture Processor Supplement, Section 3.2: Function Calling Sequence)

---

## 1. 一手汇编拆解：栈帧的诞生与湮灭

```assembly
# 函数调用过程物理剖析
my_function:
    # 1. 函数序言 (Prologue)
    pushq   %rbp            # 保存调用者的基址指针
    movq    %rsp, %rbp      # 建立当前函数的栈帧基址
    subq    $32, %rsp       # 仅一条指令，原子性在栈上开辟 32 字节局部变量空间！

    # ... 执行计算 ...

    # 2. 函数结语 (Epilogue)
    movq    %rbp, %rsp      # 丢弃局部变量：RSP 瞬间回弹，局部变量物理失效！
    popq    %rbp            # 恢复调用者的基址指针
    ret                     # 弹栈返回地址并跳转
```

- **物理极速**：栈分配耗时仅 $1\sim 2$ 个 CPU 时钟周期（$\approx 0.3\text{ns}$）；
- **确定性释放**：无需任何垃圾回收算法，指令指针（RIP）与栈指针（RSP）步进即意味着生命周期终结。

---

## 2. 形式化论证三段论 (Formal Syllogism)

- **大前提 ($P_1$)**：栈内存的分配与回收由 CPU 栈指针（RSP）单向移动完成，天然具备严格的 LIFO（后进先出）拓扑序。
- **小前提 ($P_2$)**：若局部变量的生命周期严格受限于其所属的函数栈帧，则其销毁具有 100% 的物理确定性与零运行时开销。
- **归谬 ($R$)**：若函数允许将其栈上局部变量的裸指针直接返回给外部调用者，则函数返回后外部解引用将立即发生野指针访问（Stack UAF）。
- **结论 ($C$)**：∴ 现代系统语言必须在编译期严格阻止栈上局部引用逃逸出其存活栈帧的生命周期边界。
