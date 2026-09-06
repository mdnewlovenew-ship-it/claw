import Foundation

struct ContextEvent: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let eventType: String
    let value: String
    let source: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        eventType: String,
        value: String,
        source: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.value = value
        self.source = source
    }
}
