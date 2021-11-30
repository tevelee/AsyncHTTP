import Foundation

public protocol Loader {
    associatedtype Input
    associatedtype Output
    func load(_ input: Input) async throws -> Output
}

extension Loader {
    public func loadResult(_ input: Input) async -> Result<Output, Error> {
        do {
            let value = try await load(input)
            return .success(value)
        } catch {
            return .failure(error)
        }
    }
}

public protocol CompositeLoader: Loader {
    associatedtype Wrapped: Loader
}

public enum Loaders {}
