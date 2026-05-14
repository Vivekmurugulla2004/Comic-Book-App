import Foundation

struct Run: Identifiable {
    let id: Int64
    var title: String
    var description: String
    var createdAt: Date
    var itemCount: Int
    var completedCount: Int

    var progressPercent: Double {
        guard itemCount > 0 else { return 0 }
        return Double(completedCount) / Double(itemCount)
    }

    var isFinished: Bool { itemCount > 0 && completedCount == itemCount }
    var isStarted: Bool  { completedCount > 0 }
}

struct RunItem: Identifiable {
    let id: Int64
    let runId: Int64
    let comic: Comic
    var position: Int
    var notes: String

    var isFinished: Bool { comic.isFinished }
    var isStarted: Bool  { comic.isStarted }
}

struct Tag: Identifiable, Hashable {
    let id: Int64
    let name: String
    var comicCount: Int
}
