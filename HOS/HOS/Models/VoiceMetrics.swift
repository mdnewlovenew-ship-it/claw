import Foundation

struct VoiceMetrics: Codable, Equatable, Sendable {
    var averageLevel: Float
    var peakLevel: Float
    var duration: TimeInterval
    var timestamp: Date
    var isRecording: Bool

    static let empty = VoiceMetrics(
        averageLevel: 0,
        peakLevel: 0,
        duration: 0,
        timestamp: .distantPast,
        isRecording: false
    )
}
