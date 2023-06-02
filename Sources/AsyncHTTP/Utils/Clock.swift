import Foundation

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
extension Clock {
    func sleep(for duration: Duration, tolerance: Duration? = nil) async throws {
        try await sleep(until: now.advanced(by: duration), tolerance: tolerance)
    }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
extension Clock where Duration == Swift.Duration {
    func sleep(seconds: TimeInterval) async throws {
        try await sleep(until: now.advanced(by: .seconds(seconds)), tolerance: nil)
    }
}

extension Task where Success == Never, Failure == Never {
    public static func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
