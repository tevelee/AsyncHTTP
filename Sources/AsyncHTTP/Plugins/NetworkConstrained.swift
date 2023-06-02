import Network

extension Loader {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func networkConstrained(monitor: NWPathMonitor = .init()) -> some Loader<Input, Output> {
        Loaders.NetworkConstrained(loader: self, monitor: monitor)
    }
#endif

    public func networkConstrained(monitor: NWPathMonitor = .init()) -> Loaders.NetworkConstrained<Self> {
        Loaders.NetworkConstrained(loader: self, monitor: monitor)
    }
}

extension Loaders {
    public struct NetworkConstrained<Wrapped: Loader>: Loader {
        private let wrapped: Wrapped
        private let monitor: NWPathMonitor

        init(loader: Wrapped, monitor: NWPathMonitor) {
            self.wrapped = loader
            self.monitor = monitor
        }

        public func load(_ input: Wrapped.Input) async rethrows -> Wrapped.Output {
            await monitor.waitUntilSatisfied()
            return try await wrapped.load(input)
        }
    }
}

private extension NWPathMonitor {
    func paths() -> AsyncStream<NWPath> {
        AsyncStream { continuation in
            pathUpdateHandler = { path in
                continuation.yield(path)
            }
            continuation.onTermination = { [weak self] _ in
                self?.cancel()
            }
            start(queue: DispatchQueue(label: "NSPathMonitor.paths"))
        }
    }

    func waitUntilSatisfied() async {
        if currentPath.isSatisfied { return }
        _ = await paths().first(where: \.isSatisfied)
    }
}

private extension NWPath {
    var isSatisfied: Bool { status == .satisfied }
}
