// =============================================================================
// StudyLine Typora-Fidelity Academic Markdown & LaTeX Parser Engine
// Single-Pass KaTeX rendering, Three-Line Tables, Footnotes, TOC, & Methodology blocks
// =============================================================================

import katex from "katex";
import DOMPurify from "dompurify";

export interface TOCHeading {
    id: string;
    level: number;
    title: string;
}

export interface ParsedAcademicArticle {
    html: string;
    headings: TOCHeading[];
    footnotes: { label: string; index: number; content: string }[];
}

export class AcademicMarkdownParser {
    private static canonicalGreekTerms = [
        "ἄπειρον", "δίκη", "ὕβρις", "τιμή", "Χάος", "ἀρχή", "οὐσία", 
        "ψυχή", "νοῦς", "λόγος", "ἀλήθεια", "ἔστιν", "γέρας", "μοῖρα"
    ];

    /**
     * Single-pass lexer and compiler from Markdown + LaTeX to Typora-fidelity HTML
     */
    public static parse(rawMarkdown: string): ParsedAcademicArticle {
        if (!rawMarkdown || rawMarkdown.trim() === "") {
            return { html: "<p class='empty-placeholder'>暂无讲义正文。</p>", headings: [], footnotes: [] };
        }

        const headings: TOCHeading[] = [];
        const footnotesMap = new Map<string, { label: string; index: number; content: string }>();
        let footnoteCounter = 1;

        // 1. Extract Footnote Definitions: [^label]: content
        let text = rawMarkdown.replace(/^\[\^([^\]]+)\]:\s*([\s\S]*?)(?=\n\[\^|\n\n|\n#|$)/gm, (_, label, content) => {
            if (!footnotesMap.has(label)) {
                footnotesMap.set(label, {
                    label,
                    index: footnoteCounter++,
                    content: content.trim()
                });
            }
            return "";
        });

        // 2. Extract and compile Display Math ($$...$$ and \begin{aligned}...\end{aligned})
        const mathBlocks: string[] = [];
        text = text.replace(/\$\$([\s\S]*?)\$\$/g, (_, math) => {
            const index = mathBlocks.length;
            try {
                const rendered = katex.renderToString(math.trim(), {
                    displayMode: true,
                    throwOnError: false,
                    output: "htmlAndMathml"
                });
                mathBlocks.push(`<div class="latex-display-math">${rendered}</div>`);
            } catch (err) {
                mathBlocks.push(`<div class="latex-display-math math-error">${math}</div>`);
            }
            return `<!--MATH_BLOCK_${index}-->`;
        });

        // 3. Extract and compile Inline Math ($...$)
        const inlineMathList: string[] = [];
        text = text.replace(/\$([^\$\n]+?)\$/g, (_, math) => {
            const index = inlineMathList.length;
            try {
                const rendered = katex.renderToString(math.trim(), {
                    displayMode: false,
                    throwOnError: false,
                    output: "htmlAndMathml"
                });
                inlineMathList.push(`<span class="latex-inline-math">${rendered}</span>`);
            } catch (err) {
                inlineMathList.push(`<span class="latex-inline-math math-error">${math}</span>`);
            }
            return `<!--INLINE_MATH_${index}-->`;
        });

        // 4. Parse Headings (# H1 ~ #### H4) & Build TOC
        text = text.replace(/^(#{1,4})\s+(.*$)/gm, (_, hashes, rawTitle) => {
            const level = hashes.length;
            const title = rawTitle.trim().replace(/[*_`]/g, "");
            const slug = title.toLowerCase().replace(/[\s\W-]+/g, "-").replace(/^-+|-+$/g, "") || `sec-${headings.length}`;
            headings.push({ id: slug, level, title });
            return `<h${level} id="${slug}">${rawTitle.trim()}</h${level}>`;
        });

        // 5. Parse Methodology Blocks: Bilingual Primary Sources (> [!BILINGUAL:...] or classical quote)
        text = text.replace(/^>\s*🏛️\s*\[希腊原文\]\s*(.*$)\n^>\s*📜\s*\[学术中译\]\s*(.*$)/gm, (_, greek, trans) => {
            return `
                <div class="bilingual-primary-box">
                    <div class="bilingual-grid">
                        <div class="bilingual-col-greek"><span class="bilingual-badge">一手原典</span>${greek}</div>
                        <div class="bilingual-col-trans"><span class="bilingual-badge trans">权威中译</span>${trans}</div>
                    </div>
                </div>
            `;
        });

        // 6. Parse Syllogism Blocks (- P1: ..., - P2: ..., - C: ...)
        text = text.replace(/^-\s*\*\*(大前提|小前提|引理|归谬|结论|P\d+|L\d+|R\d+|C)\*\*\s*:\s*(.*$)/gm, (_, tag, content) => {
            const isConclusion = tag === "结论" || tag.startsWith("C");
            const isReductio = tag === "归谬" || tag.startsWith("R");
            const badgeClass = isConclusion ? "syllogism-badge-conclusion" : (isReductio ? "syllogism-badge-reductio" : "syllogism-badge-premise");
            return `
                <div class="syllogism-step-row ${isConclusion ? 'is-conclusion' : ''}">
                    <span class="syllogism-tag ${badgeClass}">${tag}</span>
                    <span class="syllogism-text">${content}</span>
                </div>
            `;
        });

        // 7. Parse Academic Three-Line Tables
        text = this.parseThreeLineTables(text);

        // 8. Parse Standard Markdown Formats
        text = text
            .replace(/\*\*(.*?)\*\*/g, "<strong class='latex-bold'>$1</strong>")
            .replace(/\*(.*?)\*/g, "<em class='latex-italic'>$1</em>")
            .replace(/`([^`\n]+)`/g, "<code class='latex-code-inline'>$1</code>")
            .replace(/^>\s+(.*$)/gm, "<blockquote class='latex-blockquote'><p>$1</p></blockquote>")
            .replace(/^---$/gm, "<hr class='latex-hr' />");

        // 9. Parse Footnote In-text References: [^label]
        text = text.replace(/\[\^([^\]]+)\]/g, (_, label) => {
            const fn = footnotesMap.get(label);
            if (fn) {
                return `<sup class="academic-footnote-ref" id="fnref-${label}"><a href="#fn-${label}" class="footnote-ref-link" data-footnote-id="${label}">［${fn.index}］</a></sup>`;
            }
            return `<sup>[${label}]</sup>`;
        });

        // 10. Parse Polytonic Greek Lexicon Token Injection
        for (const term of this.canonicalGreekTerms) {
            const reg = new RegExp(`(?<!data-greek=")${term}(?!")`, "g");
            text = text.replace(reg, `<span class="studyline-term greek-term-token" data-greek="${term}">${term}</span>`);
        }

        // 11. Wrap Paragraphs
        const rawBlocks = text.split(/\n\s*\n/);
        const compiledBlocks = rawBlocks.map(block => {
            const b = block.trim();
            if (!b) return "";
            if (b.startsWith("<h") || b.startsWith("<div") || b.startsWith("<table") || 
                b.startsWith("<blockquote") || b.startsWith("<hr") || b.startsWith("<!--MATH_BLOCK_")) {
                return b;
            }
            if (b.startsWith("- ") || b.startsWith("1. ")) {
                return this.parseListBlock(b);
            }
            return `<p class="latex-paragraph">${b.replace(/\n/g, "<br/>")}</p>`;
        });

        let fullHtml = compiledBlocks.join("\n");

        // 12. Restore LaTeX Math Placeholders
        fullHtml = fullHtml.replace(/<!--MATH_BLOCK_(\d+)-->/g, (_, idx) => mathBlocks[parseInt(idx, 10)] || "");
        fullHtml = fullHtml.replace(/<!--INLINE_MATH_(\d+)-->/g, (_, idx) => inlineMathList[parseInt(idx, 10)] || "");

        // 13. Append Footnotes Section if any
        const footnotesList = Array.from(footnotesMap.values()).sort((a, b) => a.index - b.index);
        if (footnotesList.length > 0) {
            const footnotesHtml = `
                <section class="academic-footnotes-section" aria-label="参考文献与注释">
                    <hr class="footnotes-separator" />
                    <h4 class="footnotes-heading">参考文献与注释</h4>
                    <ol class="footnotes-list">
                        ${footnotesList.map(fn => `
                            <li id="fn-${fn.label}" class="footnote-item">
                                <span class="footnote-content">${fn.content}</span>
                                <a href="#fnref-${fn.label}" class="footnote-backref" aria-label="返回正文引用点"> ↩︎</a>
                            </li>
                        `).join("")}
                    </ol>
                </section>
            `;
            fullHtml += footnotesHtml;
        }

        // 14. DOMPurify sanitize with MathML support
        const cleanHtml = DOMPurify.sanitize(fullHtml, {
            ADD_TAGS: ["math", "mrow", "mi", "mo", "mstyle", "mtable", "mtd", "mtr", "semantics", "annotation", "annotation-xml"],
            ADD_ATTR: ["display", "xmlns", "mathvariant", "data-greek", "data-footnote-id", "target", "id"]
        });

        return {
            html: cleanHtml,
            headings,
            footnotes: footnotesList
        };
    }

    private static parseThreeLineTables(text: string): string {
        const tableRegex = /((?:\|[^\n]+\|\r?\n)+)/g;
        return text.replace(tableRegex, (rawTable) => {
            const lines = rawTable.trim().split("\n").map(l => l.trim()).filter(l => l.startsWith("|"));
            if (lines.length < 2) return rawTable;

            const headerLine = lines[0];
            const separatorLine = lines[1];
            const bodyLines = lines.slice(2);

            if (!separatorLine.includes("-")) return rawTable;

            const extractCells = (line: string) => line.split("|").slice(1, -1).map(c => c.trim());

            const headers = extractCells(headerLine);
            const theadHtml = `<thead><tr>${headers.map(h => `<th>${h}</th>`).join("")}</tr></thead>`;

            const rowsHtml = bodyLines.map(line => {
                const cells = extractCells(line);
                return `<tr>${cells.map(c => `<td>${c}</td>`).join("")}</tr>`;
            }).join("");

            return `
                <div class="latex-table-container">
                    <table class="latex-three-line-table">
                        ${theadHtml}
                        <tbody>${rowsHtml}</tbody>
                    </table>
                </div>
            `;
        });
    }

    private static parseListBlock(listBlock: string): string {
        const lines = listBlock.split("\n").map(l => l.trim()).filter(Boolean);
        const isOrdered = /^\d+\./.test(lines[0]);
        const items = lines.map(line => {
            const cleaned = line.replace(/^(-\s+|\d+\.\s+)/, "");
            return `<li class="latex-list-item">${cleaned}</li>`;
        });
        const tag = isOrdered ? "ol" : "ul";
        return `<${tag} class="latex-list">${items.join("")}</${tag}>`;
    }
}
