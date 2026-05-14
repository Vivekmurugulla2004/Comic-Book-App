import SwiftUI

private let arcBgUIColor      = UIColor(Color.arcBg)
private let arcSurfaceUIColor = UIColor(Color.arcSurface)
private let arcGoldUIColor    = UIColor(Color.arcGold)

@main
struct ComicArcMobileApp: App {
    @StateObject private var library = LibraryViewModel()
    @AppStorage("onboardingDone") private var onboardingDone = false
    @AppStorage("appColorScheme") private var appColorScheme: String = "dark"

    init() {
        PreferenceSync.shared.start()

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = arcSurfaceUIColor
        tab.stackedLayoutAppearance.selected.iconColor = arcGoldUIColor
        tab.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: arcGoldUIColor]
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = arcSurfaceUIColor
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav

        UITableView.appearance().backgroundColor = arcBgUIColor
        UICollectionView.appearance().backgroundColor = arcBgUIColor
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingDone {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(library)
            .preferredColorScheme(appColorScheme == "system" ? nil : .dark)
            .tint(.arcGold)
            .background(Color.arcBg.ignoresSafeArea())
            .onOpenURL { url in
                onboardingDone = true
                library.importFiles([url])
            }
        }
    }
}
