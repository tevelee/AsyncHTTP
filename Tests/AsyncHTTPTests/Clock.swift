@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
final class ImmediateClock<Duration: DurationProtocol & Hashable>: Clock, @unchecked Sendable {
    struct Instant: InstantProtocol {
        var offset: Duration

        init(offset: Duration = .zero) {
            self.offset = offset
        }

        func advanced(by duration: Duration) -> Self {
            .init(offset: offset + duration)
        }

        func duration(to other: Self) -> Duration {
            other.offset - offset
        }

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.offset < rhs.offset
        }
    }

    var now = Instant()
    var minimumResolution = Instant.Duration.zero

    init(now: Instant = .init()) {
        self.now = now
    }

    func sleep(until deadline: Instant, tolerance: Instant.Duration?) async throws {
        try Task.checkCancellation()
        now = deadline
        await Task.yield()
    }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
extension ImmediateClock where Duration == Swift.Duration {
    convenience init() {
        self.init(now: .init())
    }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
extension Clock where Self == ImmediateClock<Swift.Duration> {
    static var immediate: Self {
        ImmediateClock()
    }
}
