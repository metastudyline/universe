// =============================================================================
// StudyLine Curriculum Store & Knowledge Hierarchy Model
// Comprehensive Syllabus for Rust Systems (100 Lectures) & Philosophy (94 Lectures)
// =============================================================================

import Foundation

public struct CurriculumStage: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let subtitle: String
    public let domain: String
    public let nodes: [CurriculumNode]
}

public struct CurriculumNode: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let stageName: String
    public let domain: String
    public let coreTopic: String
    public let stars: Int
    public let summary: String
    public let primarySource: String
    public let translationCn: String
    public let citation: String
    public let p1: String
    public let p2: String
    public let reductio: String
    public let conclusion: String
}

public struct StudyLineCurriculumStore {
    // MARK: - Rust 系统级第一性原理大系 (4大阶段)
    public static let rustStages: [CurriculumStage] = [
        CurriculumStage(
            id: "rust_stage0",
            name: "0段 · 计算机物理内存与缺陷发生学",
            subtitle: "硬件寄存器、MMU 四级页表、C 指针缺陷与仿射逻辑",
            domain: "rust",
            nodes: [
                CurriculumNode(
                    id: "R01",
                    title: "栈堆物理布局与 CPU 缓存行",
                    stageName: "Rust 0段",
                    domain: "rust",
                    coreTopic: "硬件缓存与空间局部性",
                    stars: 5,
                    summary: "物理 RAM 到 CPU L1/L2/L3 Cache 的 64 字节缓存行（Cache Line）映射，栈连续性分配与堆链表离散分配对 Cache Miss 的决定性影响。",
                    primarySource: "x86_64 ABI: rsp 寄存器向下增长，栈帧分配仅需 `sub rsp, N` 单周期指令，堆分配需遍历 free list 并陷入内核或引发多线程锁竞争。",
                    translationCn: "栈的高性能源自硬件原生支持与 64 字节缓存行的绝对空间局部性；堆的灵活性是以离散地址跳跃与 Cache Miss 为代价的。",
                    citation: "Ulrich Drepper · 《What Every Programmer Should Know About Memory》",
                    p1: "硬件事实 (P1)：CPU 加载内存是以 64 字节 Cache Line 为最小原子单位；",
                    p2: "系统事实 (P2)：栈帧物理连续，堆对象在自由链表中离散分布；",
                    reductio: "归谬推导 (R)：若频繁在堆上分配小对象，导致跨缓存行指针追逐，CPU 绝大部分流水线周期将在等待 DRAM 延迟（~200周期）中空转；",
                    conclusion: "结论 (C)：现代高性能语言必须将值尽可能内联保留在栈上，避免不必要的堆分配。"
                ),
                CurriculumNode(
                    id: "R02",
                    title: "虚拟内存与 MMU 四级页表映射",
                    stageName: "Rust 0段",
                    domain: "rust",
                    coreTopic: "CR3 寄存器与 TLB 命中",
                    stars: 5,
                    summary: "x86_64 / AArch64 四级页表（PML4, PDPT, PD, PT）如何将 48 位虚拟地址转换为物理地址，缺页中断（Page Fault）与 TLB 缓存物理机制。",
                    primarySource: "MMU 硬件逐级解引用：虚拟地址 [47:39] 索引 PML4，[38:30] 索引 PDPT，[29:21] 索引 PD，[20:12] 索引 PT，[11:0] 为 4KB 页内偏移。",
                    translationCn: "程序中的每一个指针都不是物理内存，而是虚拟内存地址。非法指针访问会触发 MMU 硬件保护中断，向操作系统内核抛出 Page Fault (#PF)。",
                    citation: "Intel 64 and IA-32 Architectures Software Developer's Manual, Vol 3A",
                    p1: "物理约束 (P1)：操作系统通过 MMU 页表将进程虚拟地址空间与物理内存隔离；",
                    p2: "地址本质 (P2)：悬垂野指针指向未映射或已回收的页表项；",
                    reductio: "归谬推导 (R)：若进程试图解引用非法野指针，MMU 将产生硬件异常信号（SIGSEGV），导致进程瞬间崩溃；",
                    conclusion: "结论 (C)：内存安全必须在编译期静态消除非法指针的构造可能，而非依赖运行期内核崩溃截断。"
                ),
                CurriculumNode(
                    id: "R07",
                    title: "缺陷发生学 I · 释放后使用（UAF）与悬垂指针",
                    stageName: "Rust 0段",
                    domain: "rust",
                    coreTopic: "C 语言指针别名与 CWE-416",
                    stars: 5,
                    summary: "C/C++ 中由于指针可以任意别名拷贝，当一个指针执行 `free(p)` 后，其他指针变量无法感知内存已被回收，继续读写导致提权攻击与数据破坏。",
                    primarySource: "char *p = malloc(32);\nchar *q = p; // 产生别名 (Aliasing)\nfree(p);\n*q = 'A'; // CWE-416 Use-After-Free 漏洞",
                    translationCn: "释放后使用（UAF）的本质是：内存物理生命周期的终止与指针逻辑生命周期的存续之间发生了不可调和的脱节。",
                    citation: "MITRE CVE Database · CWE-416: Use After Free",
                    p1: "缺陷根因 (P1)：C 语言允许指针自由拷贝别名，且没有任何机制将指针与所指资源的销毁事件绑定；",
                    p2: "时空错位 (P2)：当堆分配器回收内存并重新分配给高权限对象时，残留的别名指针仍保留对其原地址的写权限；",
                    reductio: "归谬推导 (R)：攻击者可通过控制重新分配的内存布局，利用悬垂指针覆写虚表或返回地址，实现任意代码执行；",
                    conclusion: "结论 (C)：必须在语言核心引入唯一所有权（Ownership）与仿射类型系统，彻底终结 UAF。"
                ),
                CurriculumNode(
                    id: "R12",
                    title: "仿射类型系统（Affine Types）数学模型",
                    stageName: "Rust 0段",
                    domain: "rust",
                    coreTopic: "线性逻辑与 Use-at-most-once",
                    stars: 5,
                    summary: "Rust 类型系统的数理逻辑基石：从 Girard 线性逻辑到仿射类型系统。每个值作为资源，在其生命周期内最多被使用一次（Use at most once），Move 语义是其物理投影。",
                    primarySource: "Affine Logic Rule: Γ, x: T ⊢ e: U  ⟹  Γ ⊢ let y = x in e: U (x 转移后在原有作用域内永久作废)",
                    translationCn: "仿射类型系统证明：当资源从变量 A 移动到变量 B 时，编译器静态抹除 A 的可访问性，保证同一时刻全宇宙只有一个拥有者有权触发析构。",
                    citation: "Jean-Yves Girard (1987) · 《Linear Logic》 Theoretical Computer Science",
                    p1: "逻辑公理 (P1)：仿射逻辑规定任何资源变量在类型推导树中最多被消费一次；",
                    p2: "类型投影 (P2)：Rust 的赋值与传参默认按 Move 处理，原变量在符号表中被标记为不可用；",
                    reductio: "归谬推导 (R)：若允许被 Move 后的变量继续参与运算，则破坏了唯一所有权公理，导致双重释放（Double Free）；",
                    conclusion: "结论 (C)：Rust 的 Move 语义不是运行时开销，而是编译期仿射类型系统的不动点证明。"
                )
            ]
        ),
        CurriculumStage(
            id: "rust_stageA",
            name: "阶段A · 所有权哲学、借用检查器与生命周期拓扑",
            subtitle: "三大物理铁律、汇编 Move、别名异或可变性与 NLL Polonius",
            domain: "rust",
            nodes: [
                CurriculumNode(
                    id: "R21",
                    title: "所有权三大物理铁律与资源唯一排他性",
                    stageName: "Rust 阶段A",
                    domain: "rust",
                    coreTopic: "所有权三大法则与作用域销毁",
                    stars: 5,
                    summary: "1. Rust 中每个值都有一个所有者（Owner）；2. 同一时刻只能有一个所有者；3. 当所有者离开作用域，值将被自动物理丢弃（Drop）。",
                    primarySource: "pub const fn forget<T>(t: T) { let _ = ManuallyDrop::new(t); }",
                    translationCn: "所有权不是垃圾回收（GC），也不是程序员手动 free，而是编译器在 AST 上自动插入的确定性析构胶水（Drop Glue）。",
                    citation: "The Rust Programming Language · Chapter 4 Understanding Ownership",
                    p1: "定律一 (P1)：每个值在任意时刻有且仅有一个所有者变量；",
                    p2: "定律二 (P2)：当所有者变量超出 lexical/non-lexical 作用域边界时，编译器无条件执行析构；",
                    reductio: "归谬推导 (R)：若存在两个所有者，在作用域结束时将触发两次析构，引发 Double Free 堆破坏；",
                    conclusion: "结论 (C)：唯一所有权是实现确定性零成本资源管理（RAII）的充要条件。"
                ),
                CurriculumNode(
                    id: "R25",
                    title: "可变借用、独占锁契约与别名异或可变性定理",
                    stageName: "Rust 阶段A",
                    domain: "rust",
                    coreTopic: "Aliasing XOR Mutability 形式化证明",
                    stars: 5,
                    summary: "深入剖析 Rust 借用检查器的核心不动点：`&T`（无限只读共享）与 `&mut T`（绝对排他独占）在同一时空内互斥。这不仅根除了数据竞争，更为 LLVM 开启了激进的 `noalias` 寄存器优化。",
                    primarySource: "Aliasing XOR Mutability: ∀x, (Shared(x) ∧ ¬Mutable(x)) ⊕ (Mutable(x) ∧ Unique(x))",
                    translationCn: "在同一时空内，对内存的访问要么是无限只读共享，要么是绝对唯一排他。别名与可变性绝不可并存。",
                    citation: "RustBelt POPL 2018 · Iris Separation Logic",
                    p1: "并发公理 (P1)：数据竞争发生的充要条件是多个指针同时访问同一内存地址，且至少有一个指针执行写入；",
                    p2: "借用定理 (P2)：Rust 强制要求存在 `&mut T` 时，绝不允许任何其他 `&T` 或 `&mut T` 存活；",
                    reductio: "归谬推导 (R)：若编译器允许在拥有 `&T` 的同时存在 `&mut T`，读线程将读到未完成写入的非法中间态，破坏内存安全；",
                    conclusion: "结论 (C)：别名异或可变性定理不仅在编译期消除数据竞争，且零运行时性能损失。"
                )
            ]
        ),
        CurriculumStage(
            id: "rust_stageB",
            name: "阶段B · 特质系统、单态化膨胀与动态虚表分发",
            subtitle: "泛型编译期静态展开 vs dyn Trait 16字节胖指针虚表",
            domain: "rust",
            nodes: [
                CurriculumNode(
                    id: "R51",
                    title: "Trait 静态单态化（Monomorphization）与内联优化",
                    stageName: "Rust 阶段B",
                    domain: "rust",
                    coreTopic: "泛型编译期代码生成与零成本抽象",
                    stars: 5,
                    summary: "Rust 编译器如何为每一个具体类型实例化泛型函数，生成无虚表开销的直接调用（Direct Call）并允许 LLVM 执行激进的函数内联（Inlining）。",
                    primarySource: "fn process<T: Summary>(item: T) -> 编译期展开为 process_MyStruct(item), process_OtherStruct(item)",
                    translationCn: "零成本抽象的真谛：你没有使用的特性你不需要为此付出代价；你使用的特性不可能由你手写出更高性能的底层汇编。",
                    citation: "Bjarne Stroustrup / Aaron Turon · 《Zero-Cost Abstractions in Rust》",
                    p1: "抽象原则 (P1)：高级语言抽象不应带来运行时不可消除的性能惩罚；",
                    p2: "编译机制 (P2)：静态单态化在编译期将多态分发转换为硬编码的机器指令跳转；",
                    reductio: "归谬推导 (R)：若全量采用 Java/C# 风格的运行时虚表分发，CPU 将无法执行内联优化，破坏密集计算流水线；",
                    conclusion: "结论 (C)：静态单态化实现了高级类型表达力与手写 C 级极致速度的统一。"
                )
            ]
        ),
        CurriculumStage(
            id: "rust_stageC",
            name: "阶段C · 异步状态机、Pin 钉住证明与 Unsafe 内存模型",
            subtitle: "Future 自引用协程、Pin 不可移动契约、Waker 反应堆与 Miri 别名栈",
            domain: "rust",
            nodes: [
                CurriculumNode(
                    id: "R76",
                    title: "Future 自引用协程与 Pin 不可移动物理内存契约",
                    stageName: "Rust 阶段C",
                    domain: "rust",
                    coreTopic: "无栈协程跨 await 引用与 RFC 2349",
                    stars: 5,
                    summary: "为什么 `async fn` 编译出的无栈协程在跨 `await` 借用局部变量时会生成自引用结构体？`Pin<P<T>>` 如何在类型系统层面锁死物理内存地址，使得自引用指针绝无悬垂之虞。",
                    primarySource: "Pin<P<T>> guarantees that the pointee T will never be moved in memory until it is dropped.",
                    translationCn: "Pin 通过剥夺裸 &mut T 访问，在类型系统层面锁死物理内存地址，使得自引用无栈协程在跨 await 时绝无悬垂野指针之虞。",
                    citation: "Rust RFC 2349 · Pin API Specification",
                    p1: "协程本质 (P1)：无栈协程将局部变量与执行断点保存在编译器生成的自引用状态机结构体中；",
                    p2: "移动危害 (P2)：若自引用结构体在内存中被 memcpy 移动，其内部自引用指针将指向失效的旧内存地址；",
                    reductio: "归谬推导 (R)：若不通过 Pin 锁死地址，恢复协程执行时解引用内部指针将必然引发野指针崩溃；",
                    conclusion: "结论 (C)：Pin 是在无 GC 约束下支撑零分配高性能异步协程的数学基石。"
                )
            ]
        )
    ]

    // MARK: - 古希腊哲学史大系
    public static let philosophyStages: [CurriculumStage] = [
        CurriculumStage(
            id: "phil_stage0",
            name: "0段 · 神话宇宙论与悲剧城邦司法",
            subtitle: "从卡俄斯虚空裂开到雅典战神山法庭",
            domain: "philosophy",
            nodes: [
                CurriculumNode(
                    id: "E01",
                    title: "语言是人类的第一个外挂",
                    stageName: "哲学史 0段",
                    domain: "philosophy",
                    coreTopic: "符号抽象与人类认知的发生学",
                    stars: 5,
                    summary: "语言不仅是沟通工具，更是人类将感官离散经验压缩并跨代传递的第一性原理认知装置。",
                    primarySource: "语言是人类摆脱生物肉体局限、构建客观知识因果链的第一座巴别塔。",
                    translationCn: "我们通过词语为无序的经验宇宙划分边界与范畴。",
                    citation: "《严肃写作创作方法论》· 涛涛",
                    p1: "前置公理 (P1)：感官经验是瞬时且离散的；",
                    p2: "抽象发生 (P2)：语言将经验提炼为稳定符号；",
                    reductio: "归谬 (R)：若无语言符号，人类知识无法实现代际累加；",
                    conclusion: "结论 (C)：语言是人类知识大厦的元基石。"
                ),
                CurriculumNode(
                    id: "E07",
                    title: "卡俄斯：裂开的虚空",
                    stageName: "哲学史 0段",
                    domain: "philosophy",
                    coreTopic: "赫西俄德《神谱》四大始基",
                    stars: 5,
                    summary: "卡俄斯（Χάος）在词源上源自 χάσκω（裂开），是天地分化的原初物理容器空间，而非现代语义中的混乱。",
                    primarySource: "ἤτοι μὲν πρώτιστα Χάος γένετ' (Hesiod Theogony 116)",
                    translationCn: "最初生成的是卡俄斯（原初裂开的虚空），接着是宽胸的大地（盖亚）与爱（厄洛斯）。",
                    citation: "赫西俄德 · 《神谱》116-122行",
                    p1: "词源事实 (P1)：Χάος 源自动词 χάσκω（裂开/张开）；",
                    p2: "生成模型 (P2)：生成并非无中生有神创，而是空间的分化与显现；",
                    reductio: "归谬 (R)：若理解为无序混沌，则无法解释紧随其后的盖亚与塔尔塔罗斯空间定位；",
                    conclusion: "结论 (C)：卡俄斯是古希腊宇宙论对物理空间的第一次形而上学把握。"
                )
            ]
        ),
        CurriculumStage(
            id: "phil_stageA",
            name: "阶段A · 世界的质料与存在之锚",
            subtitle: "米利都三杰、赫拉克利特活火与巴门尼德本体论之锚",
            domain: "philosophy",
            nodes: [
                CurriculumNode(
                    id: "A04",
                    title: "巴门尼德真理之路与存在论之锚",
                    stageName: "哲学史 阶段A",
                    domain: "philosophy",
                    coreTopic: "存在者存在与思维与存在同一",
                    stars: 5,
                    summary: "西方形而上学第一声雷鸣：思维与存在同一。非存在不可思议、不可言说，存在者不生不灭、完整单一、连续不动。",
                    primarySource: "ἔστι γὰρ εἶναι, μηδὲν δ' οὐκ ἔστιν· τά σ' ἐγὼ φράζεσθαι ἄνωγα.",
                    translationCn: "因为存在者存在，非存在者完全不可能存在；我命令你牢牢将这一真理印在心上。",
                    citation: "巴门尼德 · 《论自然》真理之路 DK 28 B6",
                    p1: "大前提 (P1)：凡是能被思维和言说的对象，必须是某种‘存在者’（ἔστιν）；",
                    p2: "小前提 (P2)：‘非存在（无）’既不可被感知，也不可在思维中呈现（οὐκ ἔστιν）；",
                    reductio: "归谬推导 (R)：若主张‘非存在存在’或‘生成自非存在’，则必须思维‘无’，此举在逻辑上陷入自相矛盾；",
                    conclusion: "结论 (C)：存在者不生不灭、完整单一、连续不动，它是万物唯一稳固的形而上学之锚。"
                )
            ]
        )
    ]

    public static func allNodes() -> [CurriculumNode] {
        var result: [CurriculumNode] = []
        for stage in rustStages {
            result.append(contentsOf: stage.nodes)
        }
        for stage in philosophyStages {
            result.append(contentsOf: stage.nodes)
        }
        return result
    }

    public static func findNode(id: String) -> CurriculumNode? {
        allNodes().first(where: { $0.id == id })
    }
}
