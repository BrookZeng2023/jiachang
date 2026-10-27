import UIKit

/// Writes an A4 cookbook: cover, contents with real page numbers, one recipe per page,
/// and the cook's most recent journal line under each recipe.
struct CookbookPDFWriter: CookbookPDFWriting {
    func pdfData(for content: CookbookContent) throws -> Data {
        guard !content.recipes.isEmpty else { throw SharingError.emptySelection }

        // First pass: page numbers only, so the contents page can name them.
        let measure = PDFFlow(draws: false)
        let starts = layout(content, in: measure, pageNumbers: [])
        measure.finish()

        var drewPage = false
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: content.title,
            kCGPDFContextAuthor as String: "Jiachang",
            kCGPDFContextCreator as String: "Jiachang"
        ]
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: PDFStyle.pageSize),
            format: format
        )
        let data = renderer.pdfData { context in
            let flow = PDFFlow(draws: true) { context.beginPage() }
            _ = layout(content, in: flow, pageNumbers: starts)
            flow.finish()
            drewPage = flow.pageNumber >= 1
        }
        guard drewPage, !data.isEmpty else { throw SharingError.renderFailed }
        return data
    }

    /// Runs the same layout for measuring and drawing; returns each recipe's printed page.
    private func layout(_ content: CookbookContent, in flow: PDFFlow, pageNumbers: [Int]) -> [Int] {
        cover(content, flow)
        contents(content, flow, pageNumbers: pageNumbers)
        var starts: [Int] = []
        for item in content.recipes {
            flow.nextPage(background: PDFStyle.paper)
            starts.append(flow.pageNumber)
            recipe(item, flow, strings: content.strings)
        }
        return starts
    }

    private func cover(_ content: CookbookContent, _ flow: PDFFlow) {
        flow.start(background: PDFStyle.cream)
        flow.space(46)
        flow.text(PDFStyle.text(content.strings.brand, font: PDFStyle.serif(12), color: PDFStyle.persimmon, lineSpacing: 0, tracking: 3), spacingAfter: 14)
        flow.accentRule(width: 64, spacingAfter: 28)
        flow.text(PDFStyle.text(content.title, font: PDFStyle.kai(36), lineSpacing: 6), spacingAfter: 12)
        if !content.dedication.isEmpty {
            flow.space(150)
            flow.text(PDFStyle.text(content.dedication, font: PDFStyle.kai(18), color: PDFStyle.ink, lineSpacing: 9), spacingAfter: 16)
        }
        flow.space(max(0, flow.remaining - 44))
        flow.text(PDFStyle.text(content.coverDate, font: PDFStyle.hei(10), color: PDFStyle.muted, lineSpacing: 0), spacingAfter: 6)
        flow.text(PDFStyle.text(content.strings.brand, font: PDFStyle.serif(10), color: PDFStyle.muted, lineSpacing: 0, tracking: 2))
    }

    private func contents(_ content: CookbookContent, _ flow: PDFFlow, pageNumbers: [Int]) {
        flow.nextPage(background: PDFStyle.paper)
        flow.text(PDFStyle.text(content.strings.contents, font: PDFStyle.kai(24), lineSpacing: 0), spacingAfter: 8)
        flow.accentRule(width: 30, spacingAfter: 20)
        for (index, item) in content.recipes.enumerated() {
            let page = pageNumbers.indices.contains(index) ? "\(pageNumbers[index])" : ""
            row(flow, name: item.recipe.name, page: page)
        }
    }

    private func row(_ flow: PDFFlow, name: String, page: String) {
        let rowHeight: CGFloat = 27
        flow.ensure(rowHeight)
        guard flow.isDrawing, let context = UIGraphicsGetCurrentContext() else {
            flow.space(rowHeight)
            return
        }
        let y = flow.currentY
        let nameFont = PDFStyle.hei(13)
        let pageFont = PDFStyle.hei(12)
        let pageWidth: CGFloat = 26
        let maxName = flow.contentWidth - pageWidth - 24
        let attributes: [NSAttributedString.Key: Any] = [.font: nameFont, .foregroundColor: PDFStyle.ink]
        let nameWidth = min(maxName, ceil((name as NSString).size(withAttributes: attributes).width))
        (name as NSString).draw(
            in: CGRect(x: flow.margin, y: y, width: maxName, height: 18),
            withAttributes: attributes
        )
        let dotsStart = flow.margin + nameWidth + 8
        let dotsEnd = flow.margin + flow.contentWidth - pageWidth - 6
        if dotsEnd > dotsStart {
            context.saveGState()
            context.setStrokeColor(PDFStyle.hairline.cgColor)
            context.setLineWidth(0.7)
            context.setLineDash(phase: 0, lengths: [0.8, 3])
            context.move(to: CGPoint(x: dotsStart, y: y + 9))
            context.addLine(to: CGPoint(x: dotsEnd, y: y + 9))
            context.strokePath()
            context.restoreGState()
        }
        (page as NSString).draw(
            in: CGRect(x: flow.margin + flow.contentWidth - pageWidth, y: y, width: pageWidth, height: 18),
            withAttributes: [
                .font: pageFont,
                .foregroundColor: PDFStyle.muted,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.alignment = .right
                    return style
                }()
            ]
        )
        flow.space(rowHeight)
    }

    private func recipe(_ item: CookbookRecipeContent, _ flow: PDFFlow, strings: CookbookStrings) {
        if let data = item.imageData, let image = UIImage(data: data) {
            flow.image(image, height: 182, corner: 10, spacingAfter: 16)
        }
        flow.text(PDFStyle.text(item.recipe.name, font: PDFStyle.kai(26), lineSpacing: 4), spacingAfter: 6)
        if let description = item.recipe.description, !description.isEmpty {
            flow.text(PDFStyle.text(description, font: PDFStyle.hei(12), color: PDFStyle.muted, lineSpacing: 4), spacingAfter: 10)
        }
        if !item.meta.isEmpty {
            flow.text(PDFStyle.text(item.meta, font: PDFStyle.hei(10.5), color: PDFStyle.muted, lineSpacing: 0), spacingAfter: 18)
        }
        section(strings.ingredients, flow)
        for ingredient in item.recipe.ingredients {
            flow.text(PDFStyle.text("·  " + ingredient.text, font: PDFStyle.hei(12.5), lineSpacing: 3), spacingAfter: 5)
        }
        flow.space(14)
        section(strings.method, flow)
        for (index, instruction) in item.recipe.instructions.enumerated() {
            step(index + 1, instruction, flow)
        }
        if let journal = item.latestJournal {
            let label = PDFStyle.text(
                "\(strings.latestNote) · \(item.journalDate ?? "")",
                font: PDFStyle.kai(11),
                color: PDFStyle.persimmon,
                lineSpacing: 0
            )
            let note = PDFStyle.text(journal.note, font: PDFStyle.hei(11.5), lineSpacing: 4)
            // Keep the label and the note on the same page; if they must move,
            // leave a "continued" line so the page is not just a stray paragraph.
            let block = measure(label) + 6 + measure(note) + 25
            if flow.remaining < block {
                flow.nextPage(background: PDFStyle.paper)
                flow.text(
                    PDFStyle.text("\(item.recipe.name) · \(strings.continued)", font: PDFStyle.kai(11), color: PDFStyle.muted, lineSpacing: 0),
                    spacingAfter: 10
                )
            }
            flow.rule(spacingBefore: 14, spacingAfter: 10)
            flow.text(label, spacingAfter: 6)
            flow.text(note)
        }
    }

    private func measure(_ text: NSAttributedString) -> CGFloat {
        ceil(text.boundingRect(
            with: CGSize(width: PDFStyle.pageSize.width - PDFStyle.margin * 2, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height)
    }

    private func section(_ title: String, _ flow: PDFFlow) {
        flow.text(PDFStyle.text(title, font: PDFStyle.kai(17), lineSpacing: 0), spacingAfter: 8)
        flow.accentRule(width: 18, spacingAfter: 12)
    }

    private func step(_ number: Int, _ instruction: RecipeInstruction, _ flow: PDFFlow) {
        let font = PDFStyle.hei(12.5)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        let text = NSAttributedString(string: instruction.text, attributes: [
            .font: font, .foregroundColor: PDFStyle.ink, .paragraphStyle: paragraph
        ])
        let height = ceil(text.boundingRect(
            with: CGSize(width: flow.contentWidth - 26, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height)
        flow.ensure(max(height, 18) + 10)
        guard flow.isDrawing, let context = UIGraphicsGetCurrentContext() else {
            flow.space(max(height, 18) + 10)
            return
        }
        let y = flow.currentY
        let circle = CGRect(x: flow.margin, y: y + 1, width: 16, height: 16)
        context.setFillColor(PDFStyle.persimmon.cgColor)
        context.fillEllipse(in: circle)
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let numberSize = ("\(number)" as NSString).size(withAttributes: numberAttributes)
        ("\(number)" as NSString).draw(
            at: CGPoint(x: circle.midX - numberSize.width / 2, y: circle.midY - numberSize.height / 2),
            withAttributes: numberAttributes
        )
        text.draw(
            with: CGRect(x: flow.margin + 26, y: y, width: flow.contentWidth - 26, height: height + 4),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        flow.space(max(height, 18) + 10)
    }
}
