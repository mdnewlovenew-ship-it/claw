import Foundation

struct ContextEvent: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var timestamp: Date
    var eventType: String
    var value: String
    var source: String

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
