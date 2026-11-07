import Foundation

public enum KOSCommand: Equatable, Sendable {
    case help
    case boardInfo
    case boardName
    case rename(String)
    case pinRead(String)
    case pinWrite(String, Bool)
    case uptime

    public static func parse(_ input: String) throws -> KOSCommand {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "help" { return .help }
        if trimmed == "board info" { return .boardInfo }
        if trimmed == "board name" { return .boardName }
        if trimmed == "board uptime" { return .uptime }
        if trimmed.hasPrefix("board rename ") {
            let raw = String(trimmed.dropFirst("board rename ".count)).trimmingCharacters(in: .whitespaces)
            let name: String
            if raw.count >= 2, raw.first == "\"", raw.last == "\"" {
                name = String(raw.dropFirst().dropLast())
            } else { name = raw }
            guard !name.isEmpty, name.utf8.count <= 32,
                  !name.contains("\n"), !name.contains("\r"), !name.contains("\"") else {
                throw KOSPacketError.invalidName
            }
            return .rename(name)
        }
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        if parts.count == 3, parts[0] == "pin", parts[1] == "read" { return .pinRead(parts[2]) }
        if parts.count == 4, parts[0] == "pin", parts[1] == "write" {
            let value = parts[3].uppercased()
            guard value == "HIGH" || value == "LOW" else { throw KOSCommandError.invalidSyntax }
            return .pinWrite(parts[2], value == "HIGH")
        }
        throw KOSCommandError.invalidSyntax
    }

    public func packet() -> KOSPacket? {
        switch self {
        case .help: return nil
        case .boardInfo: return KOSPacket(type: "get_info")
        case .boardName: return KOSPacket(type: "get_name")
        case .rename(let name): return KOSPacket(type: "set_name", name: name)
        case .pinRead(let pin): return KOSPacket(type: "pin_read", payload: ["pin": .string(pin)])
        case .pinWrite(let pin, let high): return KOSPacket(type: "pin_write", payload: ["pin": .string(pin), "value": .integer(high ? 1 : 0)])
        case .uptime: return KOSPacket(type: "get_uptime")
        }
    }
}

public enum KOSCommandError: Error, Equatable { case invalidSyntax }
