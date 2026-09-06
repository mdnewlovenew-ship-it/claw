import Foundation

@MainActor
final class LocalStorageManager: ObservableObject {
    @Published private(set) var events: [ContextEvent] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let maxEvents = 500

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("hos-context-events.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            events = []
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            events = try decoder.decode([ContextEvent].self, from: data)
                .sorted { $0.timestamp > $1.timestamp }
        } catch {
            events = []
        }
    }

    func append(eventType: String, value: String, source: String) {
        let event = ContextEvent(eventType: eventType, value: value, source: source)
        events.insert(event, at: 0)
        if events.count > maxEvents {
            events = Array(events.prefix(maxEvents))
        }
        persist()
    }

    func clear() {
        events = []
        persist()
    }

    var count: Int { events.count }

    private func persist() {
        do {
            let data = try encoder.encode(events)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Keep in-memory state even if disk write fails.
        }
    }
}
