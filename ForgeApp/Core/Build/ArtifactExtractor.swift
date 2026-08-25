import Foundation
import Compression

/// Minimal ZIP reader for single-file artifacts produced by
/// actions/upload-artifact (the artifact zip contains exactly one .ipa).
enum ArtifactExtractor {
    static func extractSingleFile(from zipData: Data) throws -> Data {
        guard zipData.count > 30 else { throw ExtractorError.invalidArchive }
        let signature: UInt32 = 0x04034b50
        guard zipData.withUnsafeBytes({ $0.load(as: UInt32.self) }) == signature else {
            throw ExtractorError.invalidArchive
        }

        let method = UInt16(zipData[8]) | UInt16(zipData[9]) << 8
        let compressedSize = UInt32(zipData[18]) | UInt32(zipData[19]) << 8
            | UInt32(zipData[20]) << 16 | UInt32(zipData[21]) << 24
        let uncompressedSize = UInt32(zipData[22]) | UInt32(zipData[23]) << 8
            | UInt32(zipData[24]) << 16 | UInt32(zipData[25]) << 24
        let nameLength = Int(UInt16(zipData[26]) | UInt16(zipData[27]) << 8)
        let extraLength = Int(UInt16(zipData[28]) | UInt16(zipData[29]) << 8)
        let start = 30 + nameLength + extraLength
        let end = start + Int(compressedSize)
        guard end <= zipData.count else { throw ExtractorError.truncated }

        let compressed = zipData.subdata(in: start..<end)
        switch method {
        case 0:
            return compressed
        case 8:
            return try inflate(compressed, expectedSize: Int(uncompressedSize))
        default:
            throw ExtractorError.unsupportedMethod
        }
    }

    private static func inflate(_ compressed: Data, expectedSize: Int) throws -> Data {
        var zlib = Data([0x78, 0x9C])
        zlib.append(compressed)
        var adlerA: UInt32 = 1, adlerB: UInt32 = 0
        for byte in compressed {
            adlerA = (adlerA + UInt32(byte)) % 65521
            adlerB = (adlerB + adlerA) % 65521
        }
        var checksum = (adlerB << 16) | adlerA
        withUnsafeBytes(of: checksum) { zlib.append(contentsOf: $0) }

        var output = Data(count: expectedSize)
        let decoded = zlib.withUnsafeBytes { src in
            output.withUnsafeMutableBytes { dst in
                compression_decode_buffer(dst.bindMemory(to: UInt8.self).baseAddress!, expectedSize,
                                          src.bindMemory(to: UInt8.self).baseAddress!, zlib.count,
                                          nil, COMPRESSION_ZLIB)
            }
        }
        guard decoded == expectedSize else { throw ExtractorError.decompressionFailed }
        return output
    }

    enum ExtractorError: LocalizedError {
        case invalidArchive, truncated, unsupportedMethod, decompressionFailed

        var errorDescription: String? {
            switch self {
            case .invalidArchive: return "The downloaded artifact is not a valid ZIP archive."
            case .truncated: return "The artifact payload is incomplete."
            case .unsupportedMethod: return "Unsupported ZIP compression method."
            case .decompressionFailed: return "Could not decompress the IPA artifact."
            }
        }
    }
}
