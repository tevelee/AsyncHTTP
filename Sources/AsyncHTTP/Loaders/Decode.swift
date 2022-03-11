import Combine
import Foundation

extension Loader where Output: Decodable {
    public func decode<DecodedOutput, Decoder: TopLevelDecoder>(using decoder: Decoder, to type: DecodedOutput.Type = DecodedOutput.self) -> Loaders.Decoded<Self, DecodedOutput, Decoder> where Decoder.Input == Output {
        Loaders.Decoded<Self, DecodedOutput, Decoder>(self, decoder: decoder)
    }

    public func decode<DecodedOutput>(using decoder: JSONDecoder = JSONDecoder(), to type: DecodedOutput.Type = DecodedOutput.self) -> Loaders.Decoded<Self, DecodedOutput, JSONDecoder> {
        Loaders.Decoded<Self, DecodedOutput, JSONDecoder>(self, decoder: decoder)
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
