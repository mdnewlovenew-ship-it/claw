import Foundation

/// Simple Codable JSON store. Architecture stays ready for a later SwiftData migration.
@MainActor
final class LocalStorageManager: ObservableObject {
    @Published private(set) var events: [ContextEvent] = []

    private let fileURL: URL
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("hos-context-events.json")
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

    @discardableResult
    func append(eventType: String, value: String, source: String) -> ContextEvent {
        let event = ContextEvent(eventType: eventType, value: value, source: source)
        events.insert(event, at: 0)
        persist()
        return event
    }

    func clearAll() {
        events = []
        persist()
    }

    var count: Int { events.count }

    private func persist() {
        do {
            let data = try encoder.encode(events)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Keep in-memory events even if disk write fails.
        }
    }
}
