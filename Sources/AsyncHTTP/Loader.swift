import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if compiler(>=5.7)
@rethrows public protocol Loader<Input, Output> {
    associatedtype Input
    associatedtype Output
    func load(_ input: Input) async throws -> Output
}
#else
@rethrows public protocol Loader {
    associatedtype Input
    associatedtype Output
    func load(_ input: Input) async throws -> Output
}
#endif

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

#if canImport(Combine)
import Combine

extension Loader {
    public func loadPublisher(_ input: Input) -> Deferred<Future<Output, Error>> {
        Deferred {
            Future { promise in
                Task { @MainActor in
                    do {
                        let result = try await self.load(input)
                        promise(.success(result))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}
#endif
