import PDFKit
import UIKit

enum PDFPageCounter {
    nonisolated static func count(url: URL) -> Int {
        PDFDocument(url: url)?.pageCount ?? 0
    }

    nonisolated static func firstPage(url: URL) -> UIImage? {
        guard let doc = PDFDocument(url: url),
              let page = doc.page(at: 0) else { return nil }
        return render(page: page)
    }

    nonisolated static func image(url: URL, at index: Int) -> UIImage? {
        guard let doc = PDFDocument(url: url),
              let page = doc.page(at: index) else { return nil }
        return render(page: page)
    }

    private nonisolated static func render(page: PDFPage) -> UIImage {
        let bounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            ctx.cgContext.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
    }
}
