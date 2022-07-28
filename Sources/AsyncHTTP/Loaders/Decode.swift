#if canImport(Combine)
import Combine
#endif
import Foundation

extension Loader where Output: Decodable {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func decode<DecodedOutput: Decodable, Decoder: TopLevelDecoder>(using decoder: Decoder, to type: DecodedOutput.Type = DecodedOutput.self) -> some Loader<Input, DecodedOutput> where Decoder.Input == Output {
        Loaders.Decoded(self, decoder: decoder)
    }
#endif

    public func decode<DecodedOutput: Decodable, Decoder: TopLevelDecoder>(using decoder: Decoder, to type: DecodedOutput.Type = DecodedOutput.self) -> Loaders.Decoded<Self, DecodedOutput, Decoder> where Decoder.Input == Output {
        .init(self, decoder: decoder)
    }
}

extension Loader where Output == Data {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func decode<DecodedOutput: Decodable>(using decoder: JSONDecoder = JSONDecoder(), to type: DecodedOutput.Type = DecodedOutput.self) -> some Loader<Input, DecodedOutput> {
        Loaders.Decoded(self, decoder: decoder)
    }
#endif

    public func decode<DecodedOutput: Decodable>(using decoder: JSONDecoder = JSONDecoder(), to type: DecodedOutput.Type = DecodedOutput.self) -> Loaders.Decoded<Self, DecodedOutput, JSONDecoder> {
        .init(self, decoder: decoder)
    }
}

extension Loaders {
    public struct Decoded<Upstream: Loader, DecodedOutput: Decodable, Decoder: TopLevelDecoder>: Loader where Decoder.Input == Upstream.Output {
        public typealias Input = Upstream.Input

        private let upstream: Upstream
        private let decoder: Decoder

        init(_ upstream: Upstream, decoder: Decoder) {
            self.upstream = upstream
            self.decoder = decoder
        }

        public func load(_ input: Input) async throws -> DecodedOutput {
            let output = try await upstream.load(input)
            return try decoder.decode(DecodedOutput.self, from: output)
        }
    }
}
