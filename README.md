# KOSUniversalArduino

A transport-independent Swift package and Arduino-side reference firmware for the KOS JSON-lines protocol (version 1).

## What is included

- Swift packet model and JSON encoder/decoder.
- Newline-delimited stream framing.
- A command parser for `help`, `board info`, `board name`, `board rename`, `board uptime`, `pin read`, and `pin write`.
- A transport protocol that an iOS app can implement using CoreBluetooth, Wi-Fi, or a supported accessory route.
- Arduino reference firmware with persistent board naming using EEPROM-compatible storage and a serial command interface.
- Unit tests for packet encoding, protocol validation, command parsing, and stream framing.

## Important compatibility truth

This is not a universal plug-and-play driver. The Arduino must run compatible KOS firmware, and the iPhone/iPad app must implement a transport that iOS permits for the hardware being used.

The example firmware is designed for Arduino cores that provide `Arduino.h` and `EEPROM.h`, including classic AVR UNO/Nano/Mega, UNO R4, and ESP32 Arduino cores. Actual compilation and behavior must be verified for each exact board/core version. The generic example uses `Serial` at 115200 baud; it does not provide Bluetooth or Wi-Fi transport by itself.

- Classic UNO R3 / Mega / many Nano boards: USB serial from a computer is common. Direct generic USB-serial access from iOS is not guaranteed; accessory and adapter support varies.
- UNO R4 Minima: USB-C serial; no built-in Wi-Fi/BLE.
- UNO R4 WiFi: wireless hardware exists, but this serial example does not configure wireless networking.
- ESP32: BLE/Wi-Fi are available on many variants, but a separate wireless transport firmware implementation is needed.

The Swift package intentionally does not claim that it can discover or connect to every board automatically. `KOSTransport` is the integration point for a real connection implementation.

## Commands

Commands are parsed locally and converted into KOS packets:

```text
help
board info
board name
board rename "KOS Main"
board uptime
pin read A0
pin write 13 HIGH
pin write 13 LOW
```

Rename packet example:

```json
{"protocol":"KOS","version":1,"type":"set_name","name":"KOS Main"}
```

The example firmware saves the name in EEPROM-compatible storage and reports it in subsequent packets. This changes the KOS device name only; it does not alter the board's USB descriptor, Bluetooth advertisement name, or physical model identity.

## Safety

`pin write` directly changes a GPIO output. Confirm wiring and voltage limits before using it. Do not drive motors, relays, or high-current loads directly from a GPIO. The example's numeric pin guard is a broad upper bound, not a guarantee that a pin exists or is safe on every board. Pin mapping and reserved pins vary by board.

## Build and test the Swift package

With Swift 5.9 or newer:

```sh
swift test
```

The package uses Foundation only. It does not require an Apple Developer account to run its package tests on a supported Swift toolchain. Building/signing a native iOS app still requires an appropriate Apple build environment.

## License

MIT. See `LICENSE`.
