import Foundation

/// Implement this protocol with a real BLE, Wi-Fi, or supported accessory transport.
public protocol KOSTransport: Sendable {
    func send(_ data: Data) async throws
    func receive() async throws -> Data
}

public enum KOSClientError: Error { case notConnected }

public actor KOSClient {
    private let transport: any KOSTransport
    private var framer = KOSLineFramer()

    public init(transport: any KOSTransport) { self.transport = transport }

    public func send(_ packet: KOSPacket) async throws {
        try await transport.send(KOSPacketCodec.encode(packet))
    }

    public func receivePackets() async throws -> [KOSPacket] {
        let data = try await transport.receive()
        let lines = try framer.append(data)
        return try lines.map { try KOSPacketCodec.decode($0) }
    }

    public func execute(_ command: KOSCommand) async throws {
        guard let packet = command.packet() else { return }
        try await send(packet)
    }
}
