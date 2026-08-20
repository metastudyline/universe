// =============================================================================
// StudyLine Academic Lecture Workbench View
// Bilingual Primary Source Parallel Box & Formal Syllogism Reasoning Cards
// =============================================================================

import SwiftUI

public struct LectureWorkbenchView: View {
    public let node: NodeModel
    public let onOpenExam: () -> Void

    public init(node: NodeModel, onOpenExam: @escaping () -> Void) {
        self.node = node
        self.onOpenExam = onOpenExam
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 1. 双语一手原典对照框 (Bilingual Primary Source Card)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "character.book.closed.fill")
                            .foregroundStyle(TTZipTheme.kintsugiGold)
                        Text("一手原典文献锚点 (DK 12 B1 · 辛普里丘引述)")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                        Spacer()
                        Text("残篇 12 B1")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(TTZipTheme.kintsugiGold)
                    }

                    Divider()

                    // 双语并列排版
                    HStack(alignment: .top, spacing: 16) {
                        // 左侧希腊原文
                        VStack(alignment: .leading, spacing: 4) {
                            Text("🏛️ 古希腊多调原文")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                            Text("ἐξ ὧν δὲ ἡ γένεσίς ἐστι τοῖς οὖσι, καὶ τὴν φθορὰν εἰς ταῦτα γίνεσθαι κατὰ τὸ χρεών· διδόναι γὰρ αὐτὰ δίκην καὶ τίσιν ἀλλήλοις τῆς ἀδικίας κατὰ τὴν τοῦ χρόνου τάξιν.")
                                .font(.system(size: 13, design: .serif))
                                .lineSpacing(4)
                                .foregroundStyle(TTZipTheme.kintsugiGold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // 分割虚线
                        Rectangle()
                            .fill(Color.primary.opacity(0.1))
                            .frame(width: 1)

                        // 右侧学术中译
                        VStack(alignment: .leading, spacing: 4) {
                            Text("📜 权威学术中译")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                            Text("万物从何处生成，也必依照必然性（κατὰ τὸ χρεών）毁灭而归向何处；因为它们依照时间的裁定（κατὰ τὴν τοῦ χρόνου τάξιν），为了彼此的不义（ἀδικία）相互支付正义赔偿与赎罪（δίκην καὶ τίσιν）。")
                                .font(.system(size: 13, design: .serif))
                                .lineSpacing(5)
                                .foregroundStyle(.primary.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(18)
                .background(Color.primary.opacity(0.025))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(TTZipTheme.hairlineBorder, lineWidth: 0.8))

                // 2. 核心哲学发生学解析
                VStack(alignment: .leading, spacing: 10) {
                    Text("核心概念发生学解析")
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("• **本原的抽象化跃迁**：阿那克西曼德放弃了泰勒斯的具体“水”，提出 **ἄπειρον（无定/无界）**——本原不可具有排他性的具体形态，必须是未分化的中性母体。")
                            .font(.system(size: 13))
                        Text("• **宇宙法庭诉讼模型**：事物的生成是单一元素对时空的单向侵占（夏热侵占冷湿构成 ἀδικία）；时间作为公正法官，要求其在冬季通过消亡清偿赔偿。")
                            .font(.system(size: 13))
                        Text("• **前哲学正义的自然化**：完成了从赫西俄德人间司法向统御自然物理宇宙法则的伟大跃迁。")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.primary.opacity(0.85))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.025))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(TTZipTheme.hairlineBorder, lineWidth: 0.8))

                // 3. 形式化论证三段论卡片 (Formal Syllogism Card)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "flowchart.fill")
                            .foregroundStyle(TTZipTheme.kintsugiGold)
                        Text("形式化演绎论证三段论 (Formal Syllogism)")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Text("P1")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(TTZipTheme.kintsugiGold.opacity(0.2))
                                .clipShape(Capsule())
                            Text("宇宙万物的终极本原不可归约为任何单一经验质料（火、水、气）")
                                .font(.system(size: 12))
                        }

                        HStack(spacing: 8) {
                            Text("P2")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(TTZipTheme.kintsugiGold.opacity(0.2))
                                .clipShape(Capsule())
                            Text("凡有限有定之物皆处于相反者的相互逾界（ὕβρις）与补偿之中")
                                .font(.system(size: 12))
                        }

                        HStack(spacing: 8) {
                            Text("R")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(TTZipTheme.cinnabarRed.opacity(0.2))
                                .clipShape(Capsule())
                            Text("若本原为水，则烈火必被扑灭而无法共存，宇宙失去动态平衡")
                                .font(.system(size: 12))
                        }

                        HStack(spacing: 8) {
                            Text("C")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(TTZipTheme.bambooGreen.opacity(0.2))
                                .clipShape(Capsule())
                            Text("∴ 必须设立永恒不竭的 ἄπειρον（无定）与客观正义尺度 δίκη")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(TTZipTheme.bambooGreen)
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.025))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(TTZipTheme.hairlineBorder, lineWidth: 0.8))
            }
            .padding(24)
        }
    }
}
