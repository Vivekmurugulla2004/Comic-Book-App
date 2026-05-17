import UIKit
import ZIPFoundation

final class CBZReader: @unchecked Sendable {
    nonisolated(unsafe) private let archive: Archive
    nonisolated(unsafe) private let entries: [Entry]

    nonisolated var pageCount: Int { entries.count }

    nonisolated init(url: URL) throws {
        let archive = try Archive(url: url, accessMode: .read, pathEncoding: nil)
        self.archive = archive
        self.entries = archive
            .filter { CBZReader.isImagePath($0.path) }
            .sorted { CBZReader.naturalSort($0.path, $1.path) }
    }

    nonisolated func image(at index: Int) -> UIImage? {
        guard index >= 0, index < entries.count else { return nil }
        var data = Data()
        _ = try? archive.extract(entries[index], consumer: { data.append($0) })
        return UIImage(data: data)
    }

    private nonisolated static func isImagePath(_ path: String) -> Bool {
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "webp"].contains(ext)
    }

    private nonisolated static func naturalSort(_ a: String, _ b: String) -> Bool {
        a.compare(b, options: [.numeric, .caseInsensitive]) == .orderedAscending
    }
}
