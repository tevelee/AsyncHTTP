import Combine
import Foundation

extension Loader where Output: Decodable {
    public func decode<DecodedOutput, Decoder: TopLevelDecoder>(using decoder: Decoder, to type: DecodedOutput.Type = DecodedOutput.self) -> Loaders.Decoded<Self, DecodedOutput, Decoder> where Decoder.Input == Output {
        Loaders.Decoded<Self, DecodedOutput, Decoder>(self, decoder: decoder)
    }
}

extension Loaders {
    public struct Decoded<Downstream: Loader, DecodedOutput: Decodable, Decoder: TopLevelDecoder>: Loader where Decoder.Input == Downstream.Output {
        public typealias Input = Downstream.Input

        private let downstream: Downstream
        private let decoder: Decoder

        init(_ downstrean: Downstream, decoder: Decoder) {
            self.downstream = downstrean
            self.decoder = decoder
        }

        public func load(_ input: Input) async throws -> DecodedOutput {
            let output = try await downstream.load(input)
            return try decoder.decode(DecodedOutput.self, from: output)
        }
    }
}
