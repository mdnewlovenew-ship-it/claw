import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        NavigationStack {
            Group {
                if app.storage.events.isEmpty {
                    ContentUnavailableView(
                        "No Context Yet",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Motion, voice, and health actions will appear here as local ContextEvents.")
                    )
                } else {
                    List(app.storage.events) { event in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(event.eventType)
                                .font(.headline)
                            Text(event.value)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack {
                                Text(event.source)
                                Spacer()
                                Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                            }
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Timeline")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !app.storage.events.isEmpty {
                        Button("Clear") {
                            app.storage.clearAll()
                        }
                    }
                }
            }
        }
    }
}
