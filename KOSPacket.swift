import Foundation

public struct KOSPacket: Codable, Equatable, Sendable {
    public let protocolName: String
    public let version: Int
    public let type: String
    public var name: String?
    public var board: String?
    public var payload: [String: KOSJSONValue]?
    public var ok: Bool?
    public var message: String?

    enum CodingKeys: String, CodingKey {
        case protocolName = "protocol"
        case version, type, name, board, payload, ok, message
    }

    public init(type: String, name: String? = nil, board: String? = nil,
                payload: [String: KOSJSONValue]? = nil, ok: Bool? = nil,
                message: String? = nil, version: Int = 1) {
        self.protocolName = "KOS"
        self.version = version
        self.type = type
        self.name = name
        self.board = board
        self.payload = payload
        self.ok = ok
        self.message = message
    }
}

public enum KOSPacketError: Error, Equatable {
    case invalidProtocol
    case unsupportedVersion(Int)
    case invalidName
}

public enum KOSPacketCodec {
    public static func encode(_ packet: KOSPacket) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        var data = try encoder.encode(packet)
        data.append(0x0A)
        return data
    }

    public static func decode(_ data: Data) throws -> KOSPacket {
        let packet = try JSONDecoder().decode(KOSPacket.self, from: data)
        guard packet.protocolName == "KOS" else { throw KOSPacketError.invalidProtocol }
        guard packet.version == 1 else { throw KOSPacketError.unsupportedVersion(packet.version) }
        return packet
    }
}
