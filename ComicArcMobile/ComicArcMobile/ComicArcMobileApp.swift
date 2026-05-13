import SwiftUI

@main
struct ComicArcMobileApp: App {
    @StateObject private var library = LibraryViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .preferredColorScheme(.dark)
                .tint(.arcGold)
                .onOpenURL { url in
                    library.importFiles([url])
                }
        }
    }
}
