# R02: 虚拟地址空间与 MMU：页表映射、缺页异常与物理内存隔离

> **一手文献与源码锚点**：Intel 64 and IA-32 Architectures Software Developer's Manual (Volume 3A, Chapter 4: Paging) · Linux 内核 `do_page_fault` 源码

---

## 1. 一手硬件原理：MMU 与四级页表（4-Level Paging）

在 64 位 x86_64 体系下，用户程序看到的 `0x7FFF_FFFF_FFFF` 永远只是**虚拟地址（Virtual Address）**，必须经过硬件 MMU 翻译才能定位到物理内存 DRAM。

```
虚拟地址 (48 位有效):
[ 9 位 PML4 索引 ] ➔ [ 9 位 PDPT 索引 ] ➔ [ 9 位 PD 索引 ] ➔ [ 9 位 PT 索引 ] ➔ [ 12 位页内偏移 (4KB) ]
       ↓                     ↓                    ↓                   ↓
  PML4 表项 ────➔       页目录指针表 ───➔     页目录表 ────➔      页表 (PT) ────➔ 物理页帧基址 + 偏移
```

- **TLB（Translation Lookaside Buffer）**：硬件缓存最近翻译的页表项。TLB Miss 将引发多达 4 次内存访问（Page Table Walk）。
- **缺页异常（Page Fault, Interrupt 14）**：当页表项标记为“未就绪/未分配”，CPU 暂停执行并打断进入操作系统内核，内核分配物理内存后恢复执行。

---

## 2. 形式化论证三段论 (Formal Syllogism)

- **大前提 ($P_1$)**：现代操作系统的安全边界建立在虚拟内存隔离之上，非法跨界读写将直接触发 MMU 硬件保护中断（SIGSEGV 段错误）。
- **小前提 ($P_2$)**：虚拟内存只能以 4KB 物理页为最小粒度进行保护，无法在字节（Byte）级别阻止同进程内部的指针越界与别名踩踏。
- **归谬 ($R$)**：若寄希望于操作系统硬件来保证程序内部对象的安全性，则所有堆栈越界与 UAF 在未跨出 4KB 页边界前都将完全失控。
- **结论 ($C$)**：∴ 细粒度（精确到单个字段和字节）的内存安全性必须由编程语言的类型系统在编译期完成证明。
