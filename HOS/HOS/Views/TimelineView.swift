import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                if appState.storage.events.isEmpty {
                    ContentUnavailableView(
                        "No Context Events",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Events appear when motion changes, recordings start/stop, or health data refreshes.")
                    )
                } else {
                    List {
                        ForEach(appState.storage.events) { event in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(event.eventType)
                                        .font(.headline)
                                    Spacer()
                                    Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(event.value)
                                    .font(.subheadline)
                                Text(event.source)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear", role: .destructive) {
                        appState.storage.clear()
                    }
                    .disabled(appState.storage.events.isEmpty)
                }
            }
        }
    }
}
