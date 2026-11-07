/*
  KOS Universal Arduino Bridge - protocol v1
  Compatible-by-design with classic AVR UNO/Nano/Mega, UNO R4 and ESP32 Arduino cores.
  Compile for your exact board in Arduino IDE. This example uses Serial at 115200 baud.
  It does not create a phone connection by itself; use a supported USB host/accessory,
  BLE, or Wi-Fi transport implementation on the phone side.
*/
#include <Arduino.h>
#include <EEPROM.h>
#include <string.h>
#include <stdio.h>

#if defined(ESP32)
  #define KOS_EEPROM_SIZE 64
  #define KOS_EEPROM_BEGIN() EEPROM.begin(KOS_EEPROM_SIZE)
  #define KOS_EEPROM_COMMIT() EEPROM.commit()
#else
  #define KOS_EEPROM_BEGIN() do {} while (0)
  #define KOS_EEPROM_COMMIT() do {} while (0)
#endif

static const char *DEFAULT_NAME = "Arduino Board";
static char boardName[33] = "Arduino Board";
static char inputLine[192];
static size_t inputLength = 0;

void emitPacket(const char *type, const char *extra = "") {
  Serial.print("{\"protocol\":\"KOS\",\"version\":1,\"type\":\"");
  Serial.print(type);
  Serial.print("\",\"board\":\"Arduino\",\"name\":\"");
  Serial.print(boardName);
  Serial.print("\"");
  if (extra && extra[0]) { Serial.print(","); Serial.print(extra); }
  Serial.println("}");
}

void loadBoardName() {
  KOS_EEPROM_BEGIN();
  char stored[33];
  for (int i = 0; i < 32; ++i) stored[i] = (char)EEPROM.read(i);
  stored[32] = '\0';
  bool valid = stored[0] != '\0';
  for (int i = 0; i < 32 && valid; ++i) {
    if (stored[i] == '\0') break;
    if ((uint8_t)stored[i] < 32 || stored[i] == '"' || stored[i] == '\\') valid = false;
  }
  if (valid) strncpy(boardName, stored, sizeof(boardName) - 1);
  else strncpy(boardName, DEFAULT_NAME, sizeof(boardName) - 1);
  boardName[32] = '\0';
}

bool extractString(const char *line, const char *key, char *out, size_t capacity) {
  char pattern[24];
  snprintf(pattern, sizeof(pattern), "\"%s\":\"", key);
  const char *start = strstr(line, pattern);
  if (!start) return false;
  start += strlen(pattern);
  const char *end = strchr(start, '"');
  if (!end) return false;
  size_t length = (size_t)(end - start);
  if (length == 0 || length >= capacity) return false;
  memcpy(out, start, length); out[length] = '\0';
  for (size_t i = 0; i < length; ++i) if ((uint8_t)out[i] < 32 || out[i] == '\\') return false;
  return true;
}

bool extractInt(const char *line, const char *key, int *value) {
  char pattern[24]; snprintf(pattern, sizeof(pattern), "\"%s\":", key);
  const char *p = strstr(line, pattern); if (!p) return false;
  *value = atoi(p + strlen(pattern)); return true;
}

void saveBoardName(const char *name) {
  strncpy(boardName, name, sizeof(boardName) - 1); boardName[32] = '\0';
  for (int i = 0; i < 32; ++i) EEPROM.write(i, i < (int)strlen(boardName) ? boardName[i] : 0);
  KOS_EEPROM_COMMIT();
}

void handleLine(const char *line) {
  if (!strstr(line, "\"protocol\":\"KOS\"")) { emitPacket("error", "\"message\":\"Invalid protocol\""); return; }
  char type[24] = {0};
  if (!extractString(line, "type", type, sizeof(type))) { emitPacket("error", "\"message\":\"Missing command type\""); return; }

  if (strcmp(type, "get_info") == 0) {
    char extra[80]; snprintf(extra, sizeof(extra), "\"ok\":true,\"payload\":{\"uptime_ms\":%lu}", (unsigned long)millis()); emitPacket("info", extra);
  } else if (strcmp(type, "get_name") == 0) {
    emitPacket("name", "\"ok\":true");
  } else if (strcmp(type, "set_name") == 0) {
    char requested[33];
    if (!extractString(line, "name", requested, sizeof(requested))) { emitPacket("error", "\"ok\":false,\"message\":\"Invalid name (1-32 safe characters)\""); return; }
    saveBoardName(requested);
    emitPacket("name_changed", "\"ok\":true,\"message\":\"Name saved\"");
  } else if (strcmp(type, "get_uptime") == 0) {
    char extra[64]; snprintf(extra, sizeof(extra), "\"ok\":true,\"payload\":{\"uptime_ms\":%lu}", (unsigned long)millis());
    emitPacket("uptime", extra);
  } else if (strcmp(type, "pin_read") == 0) {
    char pinText[12];
    if (!extractString(line, "pin", pinText, sizeof(pinText))) { emitPacket("error", "\"ok\":false,\"message\":\"Missing pin\""); return; }
    int pin = (pinText[0] == 'A' || pinText[0] == 'a') ? analogRead(atoi(pinText + 1)) : digitalRead(atoi(pinText));
    char extra[80]; snprintf(extra, sizeof(extra), "\"ok\":true,\"payload\":{\"pin\":\"%s\",\"value\":%d}", pinText, pin);
    emitPacket("pin_value", extra);
  } else if (strcmp(type, "pin_write") == 0) {
    char pinText[12]; int value = 0;
    if (!extractString(line, "pin", pinText, sizeof(pinText)) || !extractInt(line, "value", &value) || (value != 0 && value != 1)) { emitPacket("error", "\"ok\":false,\"message\":\"Invalid pin write\""); return; }
    int pin = atoi(pinText);
    if (pin < 0 || pin > 53) { emitPacket("error", "\"ok\":false,\"message\":\"Pin outside supported numeric range\""); return; }
    pinMode(pin, OUTPUT); digitalWrite(pin, value ? HIGH : LOW);
    emitPacket("pin_written", "\"ok\":true");
  } else {
    emitPacket("error", "\"ok\":false,\"message\":\"Unknown command\"");
  }
}

void setup() {
  Serial.begin(115200);
  loadBoardName();
  unsigned long started = millis();
  while (!Serial && millis() - started < 2500) { }
  emitPacket("hello", "\"ok\":true,\"message\":\"KOS firmware ready\"");
}

void loop() {
  while (Serial.available() > 0) {
    char c = (char)Serial.read();
    if (c == '\n') {
      inputLine[inputLength] = '\0';
      if (inputLength > 0) handleLine(inputLine);
      inputLength = 0;
    } else if (c != '\r') {
      if (inputLength < sizeof(inputLine) - 1) inputLine[inputLength++] = c;
      else { inputLength = 0; emitPacket("error", "\"ok\":false,\"message\":\"Command too long\""); }
    }
  }
  static unsigned long lastTelemetry = 0;
  if (millis() - lastTelemetry >= 1000) {
    lastTelemetry = millis();
    char extra[128];
    snprintf(extra, sizeof(extra), "\"payload\":{\"uptime_ms\":%lu,\"a0\":%d,\"d2\":%d}", (unsigned long)millis(), analogRead(A0), digitalRead(2));
    emitPacket("telemetry", extra);
  }
}
