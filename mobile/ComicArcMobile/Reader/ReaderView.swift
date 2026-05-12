import SwiftUI
import PDFKit

struct ReaderView: View {
    @EnvironmentObject var library: LibraryViewModel
    @Environment(\.dismiss) private var dismiss

    var comic: Comic
    /// When reading inside a run, pass all comics so the reader can auto-advance.
    var runQueue: [Comic] = []

    @State private var currentPage: Int = 0
    @State private var readMode: ReadMode = .paged
    @State private var showToolbar = true
    @State private var showRatingSheet = false

    // Autoplay
    @State private var autoplayOn = false
    @State private var autoplayCountdown: Double = 10
    @State private var autoplayTimer: Timer?

    // Run auto-advance
    @State private var nextComic: Comic?
    @State private var showNextComicBanner = false

    enum ReadMode { case paged, scroll }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                if comic.fileExtension == "pdf" {
                    PDFReaderView(url: URL(fileURLWithPath: comic.filePath),
                                  currentPage: $currentPage)
                } else if readMode == .scroll {
                    ScrollReaderView(comic: comic, currentPage: $currentPage)
                } else {
                    PagedReaderView(comic: comic, currentPage: $currentPage)
                }
            }
            .onTapGesture { withAnimation { showToolbar.toggle() } }
            .onChange(of: currentPage) { page in
                library.updateProgress(comic, page: page)
                if autoplayOn { resetAutoplayTimer() }
                checkRunAdvance(page: page)
            }

            if showToolbar { toolbar }

            // Auto-advance banner
            if showNextComicBanner, let next = nextComic {
                nextComicBanner(next)
            }
        }
        .statusBarHidden(!showToolbar)
        .onAppear {
            currentPage = comic.progress
            readMode = UserDefaults.standard.string(forKey: "defaultReadMode") == "scroll" ? .scroll : .paged
            if let idx = runQueue.firstIndex(where: { $0.id == comic.id }),
               idx + 1 < runQueue.count {
                nextComic = runQueue[idx + 1]
            }
        }
        .onDisappear {
            stopAutoplay()
            library.load()
        }
        .sheet(isPresented: $showRatingSheet) {
            RatingSheet(comic: comic)
                .environmentObject(library)
                .presentationDetents([.height(200)])
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        VStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }

                Spacer()

                // Autoplay countdown indicator
                if autoplayOn {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        Circle()
                            .trim(from: 0, to: autoplayCountdown / 10)
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 28, height: 28)
                    .animation(.linear(duration: 1), value: autoplayCountdown)
                }

                Text("\(currentPage + 1) / \(comic.pageCount)")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())

                Spacer()

                Menu {
                    Button {
                        withAnimation { readMode = readMode == .paged ? .scroll : .paged }
                    } label: {
                        Label(readMode == .paged ? "Switch to Scroll" : "Switch to Paged",
                              systemImage: readMode == .paged ? "scroll" : "book")
                    }

                    Button {
                        autoplayOn ? stopAutoplay() : startAutoplay()
                    } label: {
                        Label(autoplayOn ? "Stop Autoplay" : "Autoplay (10s)",
                              systemImage: autoplayOn ? "stop.circle" : "play.circle")
                    }

                    Button { showRatingSheet = true } label: {
                        Label("Rate", systemImage: "star")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .foregroundStyle(.white)
            .padding()

            Spacer()

            if comic.pageCount > 0 {
                Slider(value: Binding(
                    get: { Double(currentPage) },
                    set: { currentPage = Int($0) }
                ), in: 0...Double(max(comic.pageCount - 1, 0)), step: 1)
                .tint(.orange)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Next Comic Banner

    private func nextComicBanner(_ next: Comic) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                CoverImage(comicId: next.id)
                    .frame(width: 44, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Up Next")
                        .font(.caption).foregroundStyle(.orange)
                    Text(next.title)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }

                Spacer()

                Button {
                    showNextComicBanner = false
                    dismiss()
                    // The parent run detail will re-present ReaderView with next comic
                    // via the run queue — signal via library state
                    library.pendingRunComic = next
                } label: {
                    Text("Read")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }

                Button { showNextComicBanner = false } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.bottom, showToolbar ? 60 : 16)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Run auto-advance

    private func checkRunAdvance(page: Int) {
        guard let next = nextComic,
              comic.pageCount > 0,
              page >= comic.pageCount - 1 else { return }
        withAnimation { showNextComicBanner = true }
    }

    // MARK: - Autoplay

    private func startAutoplay() {
        autoplayOn = true
        autoplayCountdown = 10
        resetAutoplayTimer()
    }

    private func stopAutoplay() {
        autoplayOn = false
        autoplayTimer?.invalidate()
        autoplayTimer = nil
    }

    private func resetAutoplayTimer() {
        autoplayTimer?.invalidate()
        autoplayCountdown = 10
        autoplayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                autoplayCountdown -= 1
                if autoplayCountdown <= 0 {
                    advancePage()
                    autoplayCountdown = 10
                }
            }
        }
    }

    private func advancePage() {
        if currentPage < comic.pageCount - 1 {
            currentPage += 1
        } else {
            stopAutoplay()
        }
    }
}

// MARK: - Paged Reader

struct PagedReaderView: View {
    let comic: Comic
    @Binding var currentPage: Int

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(0..<max(1, comic.pageCount), id: \.self) { index in
                AsyncPageImage(comic: comic, index: index)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

// MARK: - Scroll Reader

struct ScrollReaderView: View {
    let comic: Comic
    @Binding var currentPage: Int

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(0..<max(1, comic.pageCount), id: \.self) { index in
                    AsyncPageImage(comic: comic, index: index, zoomable: false)
                        .onAppear { currentPage = index }
                }
            }
        }
    }
}

// MARK: - Async Page Image

struct AsyncPageImage: View {
    let comic: Comic
    let index: Int
    let zoomable: Bool

    init(comic: Comic, index: Int, zoomable: Bool = true) {
        self.comic   = comic
        self.index   = index
        self.zoomable = zoomable
    }

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let img = image {
                if zoomable {
                    ZoomableImage(image: img)
                } else {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                }
            } else {
                Color.black
                    .overlay { ProgressView().tint(.white) }
                    .aspectRatio(2/3, contentMode: .fit)
            }
        }
        .task(id: index) { await load() }
    }

    private func load() async {
        guard image == nil else { return }
        let url = URL(fileURLWithPath: comic.filePath)
        let ext = comic.fileExtension
        image = await Task.detached(priority: .userInitiated) {
            switch ext {
            case "cbz":
                return (try? CBZReader(url: url))?.image(at: index)
            case "pdf":
                return PDFPageCounter.image(url: url, at: index)
            case "jpg", "jpeg", "png":
                return index == 0 ? UIImage(contentsOfFile: comic.filePath) : nil
            default:
                return nil
            }
        }.value
    }
}

// MARK: - PDF Reader (native PDFView)

struct PDFReaderView: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales      = true
        view.displayMode     = .singlePage
        view.displayDirection = .horizontal
        view.usePageViewController(true, withViewOptions: nil)
        view.backgroundColor = .black
        view.document        = PDFDocument(url: url)
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: view
        )
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        guard let doc  = view.document,
              let page = doc.page(at: currentPage),
              view.currentPage != page else { return }
        view.go(to: page)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject {
        var parent: PDFReaderView
        init(_ parent: PDFReaderView) { self.parent = parent }

        @objc func pageChanged(_ note: Notification) {
            guard let view = note.object as? PDFView,
                  let page = view.currentPage,
                  let doc  = view.document else { return }
            DispatchQueue.main.async {
                self.parent.currentPage = doc.index(for: page)
            }
        }
    }
}

// MARK: - Rating Sheet

struct RatingSheet: View {
    @EnvironmentObject var library: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    let comic: Comic
    @State private var rating: Int = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Rate this comic")
                .font(.headline)
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .font(.title)
                        .foregroundStyle(i <= rating ? .orange : .secondary)
                        .onTapGesture { rating = i }
                }
            }
            Button("Save") {
                library.setRating(comic, rating: rating)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
        .onAppear { rating = comic.rating }
    }
}
