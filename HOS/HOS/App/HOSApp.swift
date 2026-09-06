import SwiftUI

@main
struct HOSApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
                .preferredColorScheme(nil)
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            ActivityView()
                .tabItem { Label("Activity", systemImage: "figure.walk") }

            VoiceView()
                .tabItem { Label("Voice", systemImage: "mic.fill") }

            HealthView()
                .tabItem { Label("Health", systemImage: "heart.fill") }

            TimelineView()
                .tabItem { Label("Timeline", systemImage: "list.bullet.rectangle") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
