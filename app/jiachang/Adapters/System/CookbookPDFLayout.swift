import UIKit

/// Colours and fonts mirrored from the design tokens; the PDF writer never imports SwiftUI.
enum PDFStyle {
    static let pageSize = CGSize(width: 595.2, height: 841.8) // A4
    static let margin: CGFloat = 48
    static let footerGap: CGFloat = 18

    static let ink = UIColor(red: 0.180, green: 0.141, blue: 0.125, alpha: 1)
    static let muted = UIColor(red: 0.541, green: 0.478, blue: 0.431, alpha: 1)
    static let persimmon = UIColor(red: 0.851, green: 0.329, blue: 0.169, alpha: 1)
    static let hairline = UIColor(red: 0.929, green: 0.890, blue: 0.843, alpha: 1)
    static let cream = UIColor(red: 0.992, green: 0.973, blue: 0.941, alpha: 1)
    static let paper = UIColor(red: 1, green: 0.992, blue: 0.988, alpha: 1)

    static func kai(_ size: CGFloat) -> UIFont {
        UIFont(name: "JiachangKai-Medium", size: size) ?? .systemFont(ofSize: size)
    }

    static func hei(_ size: CGFloat) -> UIFont {
        UIFont(name: "JiachangHei-Regular", size: size) ?? .systemFont(ofSize: size)
    }

    static func serif(_ size: CGFloat) -> UIFont {
        let base = UIFont.systemFont(ofSize: size)
        let descriptor = base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor
        return UIFont(descriptor: descriptor, size: size)
    }

    static func text(
        _ string: String,
        font: UIFont,
        color: UIColor = ink,
        lineSpacing: CGFloat = 3,
        alignment: NSTextAlignment = .left,
        tracking: CGFloat = 0
    ) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing
        paragraph.alignment = alignment
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        if tracking != 0 { attributes[.kern] = tracking }
        return NSAttributedString(string: string, attributes: attributes)
    }
}

/// Lays blocks out top-down and starts new pages when they no longer fit.
/// The same layout runs twice: once measuring (draws = false, page numbers only)
/// and once drawing, so the table of contents can name real page numbers.
final class PDFFlow {
    private let draws: Bool
    private let beginPage: () -> Void
    private(set) var pageNumber = -1
    private var y: CGFloat = 0
    let pageSize = PDFStyle.pageSize
    let margin = PDFStyle.margin

    var contentWidth: CGFloat { pageSize.width - margin * 2 }
    var bottom: CGFloat { pageSize.height - margin - PDFStyle.footerGap }
    var remaining: CGFloat { max(0, bottom - y) }
    var currentY: CGFloat { y }
    var isDrawing: Bool { draws }

    init(draws: Bool, beginPage: @escaping () -> Void = {}) {
        self.draws = draws
        self.beginPage = beginPage
    }

    /// Printed page number for the next page: cover is 0 and stays unnumbered.
    var upcomingPageNumber: Int { pageNumber + 1 }

    func start(background: UIColor? = nil) {
        pageNumber = 0
        y = margin
        if draws {
            beginPage()
            fill(background)
        }
    }

    func nextPage(background: UIColor? = nil) {
        if draws {
            drawFooter()
            beginPage()
        }
        pageNumber += 1
        y = margin
        if draws { fill(background) }
    }

    func finish() {
        if draws { drawFooter() }
    }

    func ensure(_ height: CGFloat, background: UIColor? = nil) {
        if y + height > bottom { nextPage(background: background) }
    }

    @discardableResult
    func text(_ string: NSAttributedString, spacingAfter: CGFloat = 0, background: UIColor? = nil) -> CGFloat {
        let height = ceil(string.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height)
        ensure(height + spacingAfter, background: background)
        if draws {
            string.draw(with: CGRect(x: margin, y: y, width: contentWidth, height: height),
                        options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        }
        y += height + spacingAfter
        return height
    }

    func image(_ image: UIImage, height: CGFloat, corner: CGFloat, spacingAfter: CGFloat) {
        ensure(height + spacingAfter)
        if draws, let context = UIGraphicsGetCurrentContext() {
            let rect = CGRect(x: margin, y: y, width: contentWidth, height: height)
            context.saveGState()
            UIBezierPath(roundedRect: rect, cornerRadius: corner).addClip()
            image.draw(aspectFill: rect)
            context.restoreGState()
        }
        y += height + spacingAfter
    }

    func rule(color: UIColor = PDFStyle.hairline, spacingBefore: CGFloat = 0, spacingAfter: CGFloat = 0) {
        y += spacingBefore
        ensure(1 + spacingAfter)
        if draws, let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: margin, y: y, width: contentWidth, height: 0.6))
        }
        y += 0.6 + spacingAfter
    }

    func space(_ height: CGFloat) { y += height }

    /// A short accent line used under the cover kicker and section headings.
    func accentRule(width: CGFloat, color: UIColor = PDFStyle.persimmon, spacingAfter: CGFloat = 0) {
        ensure(2 + spacingAfter)
        if draws, let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: margin, y: y, width: width, height: 2))
        }
        y += 2 + spacingAfter
    }

    private func fill(_ color: UIColor?) {
        guard let color, let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(color.cgColor)
        context.fill(CGRect(origin: .zero, size: pageSize))
    }

    private func drawFooter() {
        guard pageNumber > 0, let context = UIGraphicsGetCurrentContext() else { return }
        let label = PDFStyle.text("\(pageNumber)", font: PDFStyle.hei(9), color: PDFStyle.muted, alignment: .center)
        let height: CGFloat = 12
        label.draw(with: CGRect(x: margin, y: pageSize.height - margin + 2, width: contentWidth, height: height),
                   options: [.usesLineFragmentOrigin], context: nil)
        context.setFillColor(PDFStyle.hairline.cgColor)
        context.fill(CGRect(x: (pageSize.width - 24) / 2, y: pageSize.height - margin + 16, width: 24, height: 0.5))
    }
}

private extension UIImage {
    func draw(aspectFill rect: CGRect) {
        guard size.width > 0, size.height > 0 else { return }
        let scale = max(rect.width / size.width, rect.height / size.height)
        let drawn = CGSize(width: size.width * scale, height: size.height * scale)
        let origin = CGPoint(x: rect.midX - drawn.width / 2, y: rect.midY - drawn.height / 2)
        draw(in: CGRect(origin: origin, size: drawn))
    }
}
