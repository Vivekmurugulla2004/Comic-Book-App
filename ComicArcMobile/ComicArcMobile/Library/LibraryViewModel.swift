import SwiftUI
import Combine

struct ImportProgress {
    var done: Int = 0
    var total: Int = 0
    var currentFile: String = ""
    var failures: Int = 0
    var isScanning: Bool = false  // true during folder scan before total is known
    var isActive: Bool { total > 0 || isScanning }
}

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var comics: [Comic] = []
    @Published var inProgress: [Comic] = []
    @Published var characterGroups: [SeriesGroup] = []
    @Published var seriesGroups: [SeriesGroup] = []
    @Published var publishers: [String] = []
    @Published var allTags: [Tag] = []

    @Published var selectedPublisher: String = "All"
    @Published var sortOrder: DatabaseManager.SortOrder = .publisher
    @Published var searchText: String = ""
    @Published var selectedTag: String?
    @Published var importProgress = ImportProgress()
    @Published var importError: String?

    /// Set by ReaderView when user taps "Read Next" in a run — observed by RunDetailView
    @Published var pendingRunComic: Comic?

    private let db = DatabaseManager.shared
    private var importTask: Task<Void, Never>?

    // MARK: - Load

    func load() {
        publishers   = db.publishers()
        inProgress   = db.inProgress()
        allTags      = db.allTags()
        characterGroups = db.characterGroups(
            publisher: selectedPublisher == "All" ? nil : selectedPublisher
        )

        if let tag = selectedTag {
            comics = db.comics(withTag: tag)
        } else {
            comics = db.allComics(
                publisher: selectedPublisher == "All" ? nil : selectedPublisher,
                search: searchText.isEmpty ? nil : searchText,
                sortOrder: sortOrder
            )
        }
    }

    func loadSeries(for character: String) {
        seriesGroups = db.seriesGroups(
            character: character,
            publisher: selectedPublisher == "All" ? nil : selectedPublisher
        )
    }

    func loadIssues(character: String?, series: String) {
        comics = db.allComics(
            publisher: selectedPublisher == "All" ? nil : selectedPublisher,
            character: character,
            series: series,
            nullCharacterOnly: character == nil,
            sortOrder: sortOrder
        )
    }

    func loadSearchResults() {
        guard !searchText.isEmpty else { load(); return }
        comics = db.allComics(
            publisher: selectedPublisher == "All" ? nil : selectedPublisher,
            search: searchText,
            sortOrder: sortOrder
        )
    }

    // MARK: - Import

    func cancelImport() {
        importTask?.cancel()
        importTask = nil
        importProgress = ImportProgress()
    }

    func importFiles(_ urls: [URL]) {
        importTask?.cancel()
        let count = urls.count
        importProgress = ImportProgress(done: 0, total: count, currentFile: "", failures: 0)
        importTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            var failures = 0
            for (i, url) in urls.enumerated() {
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    self.importProgress.done = i
                    self.importProgress.currentFile = url.lastPathComponent
                }
                let ok = await self.importFile(url)
                if !ok { failures += 1 }
                await MainActor.run { self.importProgress.failures = failures }
            }
            await MainActor.run {
                self.importProgress = ImportProgress()
                self.load()
            }
        }
    }

    /// Recursively scans a user-selected folder and imports all supported comic files,
    /// preserving the subfolder structure so ComicImporter.parse() can derive metadata.
    func importFolder(_ folderURL: URL) {
        importTask?.cancel()
        importProgress = ImportProgress(isScanning: true)
        importTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let accessing = folderURL.startAccessingSecurityScopedResource()
            defer { if accessing { folderURL.stopAccessingSecurityScopedResource() } }

            // Phase 1: scan recursively
            let supported = Set(["cbz", "cbr", "pdf", "jpg", "jpeg", "png"])
            guard let enumerator = FileManager.default.enumerator(
                at: folderURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { return }

            var files: [URL] = []
            for case let fileURL as URL in enumerator {
                guard !Task.isCancelled else { return }
                if supported.contains(fileURL.pathExtension.lowercased()) {
                    files.append(fileURL)
                }
            }
            files.sort { $0.path < $1.path }

            await MainActor.run {
                self.importProgress = ImportProgress(done: 0, total: files.count, currentFile: "", failures: 0)
            }

            // Phase 2: import — the folder's security scope covers all children
            var failures = 0
            for (i, fileURL) in files.enumerated() {
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    self.importProgress.done = i
                    self.importProgress.currentFile = fileURL.lastPathComponent
                }
                let ok = await self.importFileFromFolder(fileURL, folderRoot: folderURL)
                if !ok { failures += 1 }
                await MainActor.run { self.importProgress.failures = failures }
            }

            await MainActor.run {
                self.importProgress = ImportProgress()
                self.load()
            }
        }
    }

    // Preserves relative directory structure so ComicImporter derives publisher/character/series from path.
    private func importFileFromFolder(_ source: URL, folderRoot: URL) async -> Bool {
        if source.pathExtension.lowercased() == "cbr" {
            // Build relative path hint (preserving folder structure) with .cbr directory name
            var rel = source.path
            let rootPath = folderRoot.path
            if rel.hasPrefix(rootPath) {
                rel = String(rel.dropFirst(rootPath.count))
                while rel.hasPrefix("/") { rel = String(rel.dropFirst()) }
            } else {
                rel = source.lastPathComponent
            }
            let relDir = URL(fileURLWithPath: rel).deletingPathExtension().path + ".cbr"
            return await importCBR(source, relativePathHint: relDir)
        }

        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Comics")

        var relative = source.path
        let rootPath = folderRoot.path
        if relative.hasPrefix(rootPath) {
            relative = String(relative.dropFirst(rootPath.count))
            while relative.hasPrefix("/") { relative = String(relative.dropFirst()) }
        } else {
            relative = source.lastPathComponent
        }
        if relative.isEmpty { relative = source.lastPathComponent }

        let dest = docs.appendingPathComponent(relative)
        try? FileManager.default.createDirectory(
            at: dest.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        // Skip if already catalogued
        if db.comicId(forFilePath: dest.path) != nil { return true }

        if !FileManager.default.fileExists(atPath: dest.path) {
            do {
                try FileManager.default.copyItem(at: source, to: dest)
            } catch {
                await MainActor.run { self.importError = error.localizedDescription }
                return false
            }
        }

        let meta      = ComicImporter.parse(url: dest)
        let pageCount = await ComicImporter.pageCount(url: dest)

        let ext = dest.pathExtension.lowercased()
        if pageCount == 0 && (ext == "cbz" || ext == "pdf") { return false }

        db.insertComic(
            title:       meta.title,
            filePath:    dest.path,
            publisher:   meta.publisher,
            character:   meta.character,
            series:      meta.series,
            issueNumber: meta.issueNumber,
            pageCount:   pageCount,
            writer:      meta.writer,
            summary:     meta.summary
        )
        return true
    }

    // MARK: - CBR Import

    private func importCBR(_ source: URL, relativePathHint: String? = nil) async -> Bool {
        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Comics")
        try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)

        // Extracted folder has the same base name as the CBR but stored as a directory with .cbr extension.
        let folderName = relativePathHint ?? source.deletingPathExtension().lastPathComponent + ".cbr"
        let destDir    = docs.appendingPathComponent(folderName)

        if db.comicId(forFilePath: destDir.path) != nil { return true }

        let extractedURLs: [URL]
        do {
            extractedURLs = try await Task.detached(priority: .userInitiated) {
                try RARExtractor.extract(archiveURL: source, destination: destDir)
            }.value
        } catch {
            // Clean up any partially-extracted files so we don't leave orphan data on disk
            try? FileManager.default.removeItem(at: destDir)
            await MainActor.run { self.importError = error.localizedDescription }
            return false
        }

        let meta = ComicImporter.parse(url: source)
        db.insertComic(
            title:       meta.title,
            filePath:    destDir.path,
            publisher:   meta.publisher,
            character:   meta.character,
            series:      meta.series,
            issueNumber: meta.issueNumber,
            pageCount:   extractedURLs.count,
            writer:      meta.writer,
            summary:     meta.summary
        )
        return true
    }

    @discardableResult
    private func importFile(_ source: URL) async -> Bool {
        let accessing = source.startAccessingSecurityScopedResource()
        defer { if accessing { source.stopAccessingSecurityScopedResource() } }

        if source.pathExtension.lowercased() == "cbr" {
            let ok = await importCBR(source)
            return ok
        }

        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Comics")
        try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)

        let dest = docs.appendingPathComponent(source.lastPathComponent)

        // Skip if already catalogued by path
        if db.comicId(forFilePath: dest.path) != nil { return true }

        if !FileManager.default.fileExists(atPath: dest.path) {
            do {
                try FileManager.default.copyItem(at: source, to: dest)
            } catch {
                await MainActor.run { self.importError = error.localizedDescription }
                return false
            }
        }

        let meta      = ComicImporter.parse(url: dest)
        let pageCount = await ComicImporter.pageCount(url: dest)

        let ext = dest.pathExtension.lowercased()
        if pageCount == 0 && (ext == "cbz" || ext == "pdf") { return false }

        db.insertComic(
            title:       meta.title,
            filePath:    dest.path,
            publisher:   meta.publisher,
            character:   meta.character,
            series:      meta.series,
            issueNumber: meta.issueNumber,
            pageCount:   pageCount,
            writer:      meta.writer,
            summary:     meta.summary
        )
        return true
    }

    // MARK: - Mutations

    func setRating(_ comic: Comic, rating: Int) {
        db.setRating(comic.id, rating)
        load()
    }

    func delete(_ comic: Comic) {
        _deleteOne(comic)
        load()
    }

    func deleteBatch(_ comics: [Comic]) {
        comics.forEach { _deleteOne($0) }
        load()
    }

    private func _deleteOne(_ comic: Comic) {
        let docsPath = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Comics").path
        if comic.filePath.hasPrefix(docsPath) {
            try? FileManager.default.removeItem(atPath: comic.filePath)
        }
        ThumbnailCache.shared.invalidate(comicId: comic.id)
        CBZReaderCache.shared.invalidate(path: comic.filePath)
        DirectoryReaderCache.shared.invalidate(path: comic.filePath)
        db.deleteComic(comic.id)
    }

    func updateProgress(_ comic: Comic, page: Int) {
        db.updateProgress(comicId: comic.id, page: page)
    }
}
