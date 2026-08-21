// =============================================================================
// StudyLine Daily Epigram Engine (每日一手原典与思维火花确定性引擎)
// Covers Greek Philosophy & Rust First-Principles
// =============================================================================

import Foundation

public struct EpigramItem: Identifiable, Hashable {
    public let id: String
    public let domain: String
    public let domainColor: String
    public let primaryText: String
    public let translationCn: String
    public let citation: String
    public let insight: String
}

public struct DailyEpigramEngine {
    public static let library: [EpigramItem] = [
        EpigramItem(
            id: "EPI_01",
            domain: "古希腊哲学史",
            domainColor: "gold",
            primaryText: "ἐξ ὧν δὲ ἡ γένεσίς ἐστι τοῖς οὖσι, καὶ τὴν φθορὰν εἰς ταῦτα γίνεσθαι κατὰ τὸ χρεών· διδόναι γὰρ αὐτὰ δίκην καὶ τίσιν ἀλλήλοις τῆς ἀδικίας κατὰ τὴν τοῦ χρόνου τάξιν.",
            translationCn: "万物由它产生，也必复归于它，这是命运的裁定；因为它们依照时间的秩序，为彼此的不义互相偿付赔偿与正义。",
            citation: "阿那克西曼德 · DK 12 B1 (Simplicius Phys. 24, 13)",
            insight: "生成是对无定（ἄπειρον）始基的僭越侵犯，时间是终极的宇宙司法官。"
        ),
        EpigramItem(
            id: "EPI_02",
            domain: "Rust 系统哲学",
            domainColor: "bamboo",
            primaryText: "pub const fn forget<T>(t: T) { let _ = ManuallyDrop::new(t); }",
            translationCn: "通过透明包装器 ManuallyDrop 抑制 Drop Glue，变量占用的栈内存随栈指针正常回弹，但其管理的堆内存被永久移出析构管线。",
            citation: "Rust 标准库 · library/core/src/mem/mod.rs",
            insight: "所有权不是隐式黑盒，而是编译期仿射类型系统（Affine Types）与硬件栈帧物理回弹的精确解耦。"
        ),
        EpigramItem(
            id: "EPI_03",
            domain: "古希腊哲学史",
            domainColor: "gold",
            primaryText: "κόσμον τόνδε, τὸν αὐτὸν ἁπάντων, οὔτε τις θεῶν οὔτε ἀνθρώπων ἐποίησεν, ἀλλ' ἦν ἀεὶ καὶ ἔστιν καὶ ἔσται πῦρ ἀείζωον, ἁπτόμενον μέτρα καὶ ἀποσβεννύμενον μέτρα.",
            translationCn: "这个世界秩序，对一切存在者都是同一的，不是任何神也不是任何人创造的；它过去是、现在是、将来也永远是一团永恒的活火，按尺度点燃，按尺度熄灭。",
            citation: "赫拉克利特 · DK 22 B30 (Clement Strom. V, 104, 1)",
            insight: "火不是实体质料，而是动态平衡、守恒与 Logos 尺度的最高象征。"
        ),
        EpigramItem(
            id: "EPI_04",
            domain: "Rust 系统哲学",
            domainColor: "bamboo",
            primaryText: "Pin<P<T>> guarantees that the pointee T will never be moved in memory until it is dropped.",
            translationCn: "Pin 通过剥夺裸 &mut T 访问，在类型系统层面锁死物理内存地址，使得自引用无栈协程（Stackless Coroutine）在跨 await 时绝无悬垂野指针之虞。",
            citation: "Rust RFC 2349 · Pin API Specification",
            insight: "在无 GC 与无分段栈的极端约束下，通过类型系统证明内存地址恒定性。"
        ),
        EpigramItem(
            id: "EPI_05",
            domain: "古希腊哲学史",
            domainColor: "gold",
            primaryText: "ἔστι γὰρ εἶναι, μηδὲν δ' οὐκ ἔστιν· τά σ' ἐγὼ φράζεσθαι ἄνωγα.",
            translationCn: "因为存在者存在，非存在者绝不可能存在；我命令你牢牢将这一真理印在心上。",
            citation: "巴门尼德 · 《论自然》真理之路 DK 28 B6",
            insight: "西方本体论（Ontology）的第一声雷鸣：思维与存在的同一性。"
        ),
        EpigramItem(
            id: "EPI_06",
            domain: "Rust 系统哲学",
            domainColor: "bamboo",
            primaryText: "Aliasing XOR Mutability: ∀x, (Shared(x) ∧ ¬Mutable(x)) ⊕ (Mutable(x) ∧ Unique(x))",
            translationCn: "在同一时空内，对内存的访问要么是无限只读共享，要么是绝对唯一排他。别名与可变性绝不可并存。",
            citation: "RustBelt POPL 2018 · Iris Separation Logic",
            insight: "不仅根除了数据竞争与 UAF，更为 LLVM noalias 指令重排提供了充要数学依据。"
        )
    ]

    public static func todayEpigram() -> EpigramItem {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = abs(dayOfYear) % library.count
        return library[index]
    }
}
