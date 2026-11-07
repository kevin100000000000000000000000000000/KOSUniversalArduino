import Foundation

public struct KOSLineFramer: Sendable {
    private var buffer = Data()
    public let maximumLineLength: Int

    public init(maximumLineLength: Int = 16_384) {
        self.maximumLineLength = max(256, maximumLineLength)
    }

    public mutating func append(_ data: Data) throws -> [Data] {
        var lines: [Data] = []
        for byte in data {
            if byte == 0x0A {
                if !buffer.isEmpty && buffer.last == 0x0D { buffer.removeLast() }
                if !buffer.isEmpty { lines.append(buffer) }
                buffer.removeAll(keepingCapacity: true)
            } else {
                buffer.append(byte)
                if buffer.count > maximumLineLength {
                    buffer.removeAll(keepingCapacity: true)
                    throw KOSLineFramerError.lineTooLong
                }
            }
        }
        return lines
    }
}

public enum KOSLineFramerError: Error { case lineTooLong }
