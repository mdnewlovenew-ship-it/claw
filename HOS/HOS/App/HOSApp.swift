import SwiftUI

@main
struct HOSApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            ActivityView()
                .tabItem { Label("Activity", systemImage: "figure.walk") }
                .tag(1)

            VoiceView()
                .tabItem { Label("Voice", systemImage: "mic.fill") }
                .tag(2)

            HealthView()
                .tabItem { Label("Health", systemImage: "heart.fill") }
                .tag(3)

            TimelineView()
                .tabItem { Label("Timeline", systemImage: "list.bullet.rectangle") }
                .tag(4)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(5)
        }
        .tint(.cyan)
    }
}
