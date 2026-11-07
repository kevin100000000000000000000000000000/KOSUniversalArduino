import XCTest
@testable import KOSUniversalArduino

final class KOSUniversalArduinoTests: XCTestCase {
    func testPacketRoundTrip() throws {
        let original = KOSPacket(type: "set_name", name: "KOS Main")
        let encoded = try KOSPacketCodec.encode(original)
        let decoded = try KOSPacketCodec.decode(Data(encoded.dropLast()))
        XCTAssertEqual(decoded, original)
    }

    func testRejectsWrongProtocol() throws {
        let data = Data(#"{"protocol":"OTHER","version":1,"type":"hello"}"#.utf8)
        XCTAssertThrowsError(try KOSPacketCodec.decode(data))
    }

    func testRenameCommand() throws {
        XCTAssertEqual(try KOSCommand.parse(#"board rename "KOS Main""#), .rename("KOS Main"))
    }

    func testRejectsTooLongName() {
        XCTAssertThrowsError(try KOSCommand.parse("board rename \"\(String(repeating: "a", count: 33))\""))
    }

    func testFramingAcrossChunks() throws {
        var framer = KOSLineFramer()
        XCTAssertTrue(try framer.append(Data("{\"a\":".utf8)).isEmpty)
        let lines = try framer.append(Data("1}\n{\"b\":2}\n".utf8))
        XCTAssertEqual(lines.count, 2)
    }
}
