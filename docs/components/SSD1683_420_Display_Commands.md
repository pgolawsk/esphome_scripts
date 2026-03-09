# WeAct ePaper 4.2" (SSD1683) Display Controller Documentation

This document provides comprehensive documentation for the WeAct ePaper 4.2" BWR (Black-White-Red) display module based on the SSD1683 controller.

## Table of Contents

1. [Display Specifications](#display-specifications)
1. [SSD1683 Command Reference](#ssd1683-command-reference)
1. [Display Memory Structure](#display-memory-structure)
1. [Display Refresh Sequences](#display-refresh-sequences)
1. [Partial Update Scenarios](#partial-update-scenarios)
1. [Power Management](#power-management)
1. [Usage Examples](#usage-examples)

______________________________________________________________________

## Display Specifications

| Parameter         | Value                             |
| ----------------- | --------------------------------- |
| **Display Model** | WeAct 4.2" BWR E-Paper Module     |
| **Controller**    | SSD1683                           |
| **Resolution**    | 400 × 300 pixels                  |
| **Colors**        | Black, White, Red (3-Color)       |
| **Display Type**  | E-ink / E-Paper                   |
| **Interface**     | SPI (Serial Peripheral Interface) |
| **Panel Code**    | GDEY042Z98                        |

### Timing Specifications

| Operation                         | Time                   |
| --------------------------------- | ---------------------- |
| Power On                          | 100 ms                 |
| Power Off                         | 250 ms                 |
| Full Refresh (Normal)             | 25000 ms (~25 seconds) |
| Full Refresh (Fast)               | ~10 seconds            |
| Partial Refresh (BW Differential) | 1500 ms (~1.5 seconds) |

> **Note:** The SSD1683 supports **fast partial updates** using the `refresh_bw()` method, which takes only ~1.5 seconds! This is a significant advantage over SSD1680-based displays.

______________________________________________________________________

## SSD1683 Command Reference

This section documents all commands used to control the SSD1683 e-paper display controller.

### Command Overview Table

| Hex Code | Command Name                     | Description                                         | Data Bytes |
| -------- | -------------------------------- | --------------------------------------------------- | ---------- |
| `0x01`   | Driver Output Control            | Sets display resolution and gate scanning direction | 3          |
| `0x10`   | Deep Sleep Mode                  | Enters deep sleep power mode                        | 1          |
| `0x11`   | Data Entry Mode                  | Sets RAM entry mode and X/Y address increment       | 1          |
| `0x12`   | SWRESET                          | Software reset command                              | 0          |
| `0x18`   | Read Built-in Temperature Sensor | Reads internal temperature sensor                   | 1          |
| `0x1A`   | Temperature Sensor Write         | Writes temperature value to register                | 2          |
| `0x21`   | Display Update Control           | Controls display update sequence                    | 2          |
| `0x22`   | Display Update Sequence Options  | Initiates display refresh with options              | 1          |
| `0x24`   | Write Black RAM                  | Writes black/white pixel data                       | N          |
| `0x26`   | Write Red RAM                    | Writes red color pixel data                         | N          |
| `0x3C`   | Border Waveform Control          | Sets border behavior                                | 1          |
| `0x44`   | Set RAM X Start/End              | Sets RAM X address boundaries                       | 2          |
| `0x45`   | Set RAM Y Start/End              | Sets RAM Y address boundaries                       | 4          |
| `0x4E`   | Set RAM X Counter                | Sets RAM X address counter                          | 2          |
| `0x4F`   | Set RAM Y Counter                | Sets RAM Y address counter                          | 2          |
| `0x20`   | Master Activation                | Starts display update                               | 0          |

______________________________________________________________________

### Detailed Command Descriptions

#### 0x12 - SWRESET (Software Reset)

Performs a software reset of the controller. After this command, the display enters default state.

**Sequence:**

```cpp
_writeCommand(0x12);  // SWRESET
delay(10);            // Wait 10ms as per specification
```

______________________________________________________________________

#### 0x01 - Driver Output Control

Configures the display panel output parameters including resolution and scan direction.

**Parameters (4.2" GDEY042Z98):**

- Byte 0: (HEIGHT - 1) % 256 = (300 - 1) % 256 = 0x2D
- Byte 1: (HEIGHT - 1) / 256 = 1
- Byte 2: 0x00

**Sequence:**

```cpp
_writeCommand(0x01); // Driver output control
_writeData(0x2D);    // 300-1 = 0x12D = 0x2D (LSB)
_writeData(0x01);    // 300-1 = 0x12D = 0x01 (MSB)
_writeData(0x00);    // Reserved
```

______________________________________________________________________

#### 0x11 - Data Entry Mode

Sets the direction in which the RAM address pointer auto-increments when writing data.

**Parameters:**

- `0x03` = X increment, Y increment (normal mode)

**Sequence:**

```cpp
_writeCommand(0x11); // Data entry mode
_writeData(0x03);    // x increase, y increase
```

______________________________________________________________________

#### 0x3C - Border Waveform Control

Controls the border (waveform) behavior during display updates.

**Parameters:**

- `0x05` = Border follows LUT (Look-up table)

**Sequence:**

```cpp
_writeCommand(0x3C); // Border waveform
_writeData(0x05);    // Border setting
```

______________________________________________________________________

#### 0x18 - Read Built-in Temperature Sensor

Enables/disables the internal temperature sensor.

**Parameters:**

- `0x80` = Enable internal temperature sensor

**Sequence:**

```cpp
_writeCommand(0x18); // Temperature sensor
_writeData(0x80);   // Enable internal sensor
```

______________________________________________________________________

#### 0x1A - Temperature Sensor Write

Writes temperature value to register for fast refresh mode.

**Parameters:**

- Byte 0: Temperature value (e.g., 0x5A = 90)
- Byte 1: Reserved (0x00)

**Sequence:**

```cpp
_writeCommand(0x1A); // Write to temperature register
_writeData(0x5A);    // Temperature = 90
_writeData(0x00);
```

______________________________________________________________________

#### 0x44 - Set RAM X Start/End Address

Defines the column (X) address range for RAM access. X coordinates must be byte-aligned (multiples of 8).

**Parameters:**

- Byte 0: X start address / 8
- Byte 1: X end address / 8

**Sequence:**

```cpp
_writeCommand(0x44);         // Set RAM X
_writeData(x_start / 8);     // Start byte address
_writeData((x_end - 1) / 8); // End byte address
```

______________________________________________________________________

#### 0x45 - Set RAM Y Start/End Address

Defines the row (Y) address range for RAM access.

**Parameters:**

- Byte 0: Y start (LSB)
- Byte 1: Y start (MSB)
- Byte 2: Y end - 1 (LSB)
- Byte 3: Y end - 1 (MSB)

**Sequence:**

```cpp
_writeCommand(0x45);              // Set RAM Y
_writeData(y_start & 0xFF);        // Y start LSB
_writeData(y_start >> 8);          // Y start MSB
_writeData((y_end - 1) & 0xFF);    // Y end LSB
_writeData((y_end - 1) >> 8);     // Y end MSB
```

______________________________________________________________________

#### 0x4E - Set RAM X Counter

Sets the current RAM X address counter (pointer).

**Parameters:**

- Byte 0: X address / 8

**Sequence:**

```cpp
_writeCommand(0x4E);       // Set RAM X counter
_writeData(x / 8);        // Current X position
```

______________________________________________________________________

#### 0x4F - Set RAM Y Counter

Sets the current RAM Y address counter (pointer).

**Parameters:**

- Byte 0: Y address (LSB)
- Byte 1: Y address (MSB)

**Sequence:**

```cpp
_writeCommand(0x4F);       // Set RAM Y counter
_writeData(y & 0xFF);      // Y position LSB
_writeData(y >> 8);        // Y position MSB
```

______________________________________________________________________

#### 0x24 - Write Black/White RAM

Writes pixel data to the Black/White RAM plane.

- `0x00` = White pixel
- `0xFF` (all bits set) = Black pixel

**Sequence:**

```cpp
_writeCommand(0x24); // Write B/W RAM
// Write pixel data...
```

______________________________________________________________________

#### 0x26 - Write Red RAM

Writes pixel data to the Red color RAM plane.

- `0x00` = No red (shows B/W content)
- `0xFF` (all bits set) = Red pixel

**Sequence:**

```cpp
_writeCommand(0x26); // Write Red RAM
// Write pixel data...
```

______________________________________________________________________

#### 0x22 - Display Update Sequence Options

Initiates the display refresh sequence with various options. Must be followed by command 0x20.

**Parameters:**

- `0xC0` = Power on
- `0xC3` = Power off
- `0xF7` = Normal full refresh
- `0x91` = Load LUT for temperature (fast mode)
- `0xC7` = Fast full refresh
- `0xDC` = BW differential refresh (partial)

**Normal Full Refresh Sequence:**

```cpp
_writeCommand(0x22); // Display Update Sequence Options
_writeData(0xF7);    // Normal refresh
_writeCommand(0x20); // Master Activation
_waitWhileBusy("_Update_Full", full_refresh_time);
```

**Fast Full Refresh Sequence:**

```cpp
// Step 1: Set temperature
_writeCommand(0x1A); // Temperature register
_writeData(0x5A);    // 90 degrees
_writeData(0x00);

// Step 2: Load LUT
_writeCommand(0x22); // Display Update Sequence Options
_writeData(0x91);    // Load LUT
_writeCommand(0x20); // Master Activation
delay(2);

// Step 3: Fast refresh
_writeCommand(0x22);
_writeData(0xC7);    // Fast refresh
_writeCommand(0x20);
_waitWhileBusy("_Update_Fast", full_refresh_time);
```

**BW Differential Refresh (Fast Partial):**

```cpp
_writeCommand(0x22); // Display Update Sequence Options
_writeData(0xDC);    // BW differential
_writeCommand(0x20); // Master Activation
_waitWhileBusy("refresh_bw", partial_refresh_time); // ~1.5 seconds!
```

______________________________________________________________________

#### 0x20 - Master Activation

Triggers the display update sequence. This command initiates the physical display refresh after the update control has been set.

**Sequence:**

```cpp
_writeCommand(0x20); // Master Activation
_waitWhileBusy("_Update", full_refresh_time);
```

______________________________________________________________________

#### 0x10 - Deep Sleep Mode

Enters deep sleep mode for minimum power consumption. Requires hardware reset to wake.

**Parameters:**

- `0x11` = Enter deep sleep mode (SSD1683 uses 0x11, not 0x01 like SSD1680!)

**Sequence:**

```cpp
// Before entering sleep:
_PowerOff();               // Power off the display

// Enter deep sleep:
_writeCommand(0x10);        // Deep sleep mode
_writeData(0x11);          // Enter deep sleep (SSD1683 specific!)
_hibernating = true;       // Mark as hibernating

// To wake: Hardware reset required (toggle RST pin)
```

______________________________________________________________________

## Display Memory Structure

The SSD1683 has separate RAM planes for the 3-color display:

```text
┌─────────────────────────────────────────────┐
│              BLACK/WHITE RAM                 │
│         (0x24 Command - 400×300 bits)       │
│  1 bit per pixel: 1=Black, 0=White          │
│  Size: 400 × 300 / 8 = 15000 bytes          │
├─────────────────────────────────────────────┤
│              RED RAM                         │
│         (0x26 Command - 400×300 bits)       │
│  1 bit per pixel: 1=Red, 0=No Red          │
│  Size: 400 × 300 / 8 = 15000 bytes          │
├─────────────────────────────────────────────┤
│         Total Buffer: 30000 bytes            │
└─────────────────────────────────────────────┘
```

### Color Mapping Logic

When displaying content, the final pixel color is determined by combining both RAM planes:

| Black RAM | Red RAM | Display Color          |
| --------- | ------- | ---------------------- |
| 0         | 0       | White                  |
| 1         | 0       | Black                  |
| 0         | 1       | Red                    |
| 1         | 1       | Black (Red overwrites) |

______________________________________________________________________

## Display Refresh Sequences

### 1. Full Screen Refresh (Normal Mode)

Full refresh is recommended after power-on, after deep sleep, and periodically to prevent ghosting.

```cpp
void _InitDisplay() {
    // Step 1: Software Reset
    _writeCommand(0x12);  // SWRESET
    delay(10);
  
    // Step 2: Driver Output Control (300 gates)
    _writeCommand(0x01); // Driver output control
    _writeData(0x2D);    // 300-1 = 0x12D = 0x2D (LSB)
    _writeData(0x01);    // 300-1 = 0x12D = 0x01 (MSB)
    _writeData(0x00);    // Reserved
  
    // Step 3: Border Waveform
    _writeCommand(0x3C); // Border waveform
    _writeData(0x05);    // Border LUT
  
    // Step 4: Temperature Sensor
    _writeCommand(0x18); // Temperature sensor
    _writeData(0x80);   // Enable internal
  
    // Step 5: Set full RAM area
    _setPartialRamArea(0, 0, WIDTH, HEIGHT);
  
    _init_display_done = true;
}

void _Update_Full() {
    // Normal full refresh
    _writeCommand(0x22);
    _writeData(0xF7);    // Normal refresh
    _writeCommand(0x20);
    _waitWhileBusy("_Update_Full", full_refresh_time); // ~25 seconds
  
    _power_is_on = false;
}
```

______________________________________________________________________

### 2. Fast Full Refresh Mode

Uses temperature-based LUT for faster refresh (~10 seconds).

```cpp
void _Update_Fast() {
    // Step 1: Set temperature
    _writeCommand(0x1A); // Write to temperature register
    _writeData(0x5A);    // Temperature = 90
    _writeData(0x00);
  
    // Step 2: Load LUT
    _writeCommand(0x22); // Display Update Sequence Options
    _writeData(0x91);    // Load LUT for temperature value
    _writeCommand(0x20); // Master Activation
    delay(2);            // Small delay
  
    // Step 3: Fast refresh
    _writeCommand(0x22);
    _writeData(0xC7);    // Fast refresh
    _writeCommand(0x20);
    _waitWhileBusy("_Update_Fast", full_refresh_time);
  
    _power_is_on = false;
}
```

______________________________________________________________________

### 3. BW Differential Refresh (Fast Partial)

This is the key feature of SSD1683! It allows partial updates in just ~1.5 seconds.

```cpp
void refresh_bw(int16_t x, int16_t y, int16_t w, int16_t h) {
    // Ensure byte alignment
    x -= x % 8;
    w -= w % 8;
  
    // Limit to screen bounds
    int16_t x1 = x < 0 ? 0 : x;
    int16_t y1 = y < 0 ? 0 : y;
    int16_t w1 = x + w < int16_t(WIDTH) ? w : int16_t(WIDTH) - x;
    int16_t h1 = y + h < int16_t(HEIGHT) ? h : int16_t(HEIGHT) - y;
  
    // Set RAM window
    _setPartialRamArea(x1, y1, w1, h1);
  
    // Trigger BW differential refresh
    _writeCommand(0x22);
    _writeData(0xDC);    // BW differential
    _writeCommand(0x20);
  
    _waitWhileBusy("refresh_bw", partial_refresh_time); // ~1.5 seconds!
}
```

______________________________________________________________________

### 4. Using writeImageToPrevious / writeImageToCurrent

SSD1683 supports writing to different buffer states for differential updates:

```cpp
// Write to "previous" buffer (used for comparison in differential mode)
void writeImageToPrevious(const uint8_t* bitmap, int16_t x, int16_t y, int16_t w, int16_t h) {
    _writeImage(0x26, bitmap, x, y, w, h, invert, mirror_y, pgm);
}

// Write to "current" buffer
void writeImageToCurrent(const uint8_t* bitmap, int16_t x, int16_t y, int16_t w, int16_t h) {
    _writeImage(0x24, bitmap, x, y, w, h, invert, mirror_y, pgm);
}
```

______________________________________________________________________

## Partial Update Scenarios

### Scenario 1: Fast Partial Update with refresh_bw()

The SSD1683 supports fast partial updates using the `refresh_bw()` method:

```cpp
void updateTextFieldFast(const char* text, int x, int y, int w, int h) {
    // Ensure byte alignment
    x -= x % 8;
    w = (w + 7) / 8 * 8;
  
    // Write to black RAM
    writeImageToCurrent(text_bitmap, x, y, w, h);
  
    // Use fast partial refresh (~1.5 seconds!)
    refresh_bw(x, y, w, h);
}
```

______________________________________________________________________

### Scenario 2: Progress Bar with Fast Update

```cpp
void updateProgressBarFast(int percentage, int x, int y, int w, int h) {
    x -= x % 8;
    w = (w + 7) / 8 * 8;
  
    // Create progress bar bitmap
    uint8_t buffer[600]; // Example
    memset(buffer, 0x00, sizeof(buffer));
  
    int filledWidth = (w * percentage) / 100;
    for (int row = 0; row < h; row++) {
        for (int col = 0; col < filledWidth / 8; col++) {
            buffer[row * (w/8) + col] = 0xFF;
        }
    }
  
    // Write to current buffer
    writeImageToCurrent(buffer, x, y, w, h);
  
    // Fast partial refresh (~1.5 seconds!)
    refresh_bw(x, y, w, h);
}
```

______________________________________________________________________

### Scenario 3: Clock Display with Differential Update

```cpp
void updateClockDifferential(int hours, int minutes) {
    int x = 100;
    int y = 80;
    int w = 200;
    int h = 80;
  
    x -= x % 8;
    w = (w + 7) / 8 * 800;
  
    // Write to previous buffer first (background)
    writeImageToPrevious(backgroundBitmap, x, y, w, h);
  
    // Write to current buffer (new content)
    writeImageToCurrent(clockBitmap, x, y, w, h);
  
    // Use fast partial refresh
    refresh_bw(x, y, w, h);
}
```

______________________________________________________________________

## Power Management

### 1. Normal Power Off

Turns off panel driving voltages but keeps controller powered.

```cpp
void _PowerOff() {
    if (_power_is_on) {
        _writeCommand(0x22);
        _writeData(0xC3);    // Power off command
        _writeCommand(0x20);
        _waitWhileBusy("_PowerOff", power_off_time); // 250ms
    }
    _power_is_on = false;
}
```

______________________________________________________________________

### 2. Deep Sleep Mode

For minimum power consumption when display doesn't need to be updated for extended periods.

```cpp
void hibernate() {
    _PowerOff();
    if (_rst >= 0) {
        _writeCommand(0x10); // Deep sleep mode
        _writeData(0x11);    // Enter deep sleep (SSD1683 uses 0x11!)
        _hibernating = true;
        _init_display_done = false;
    }
}
```

**To Wake from Deep Sleep:**

- Hardware reset is required (toggle RST pin low → high)
- After reset, full re-initialization is needed

______________________________________________________________________

### 3. Power On Sequence

```cpp
void _PowerOn() {
    if (!_power_is_on) {
        _writeCommand(0x22);
        _writeData(0xC0);    // Power on
        _writeCommand(0x20);
        _waitWhileBusy("_PowerOn", power_on_time); // 100ms
    }
    _power_is_on = true;
}
```

______________________________________________________________________

## Usage Examples

### Using GxEPD2 Library

```cpp
#include <GxEPD2_3C.h>
#include <Fonts/FreeMonoBold12pt7b.h>

// Pin connections for ESP32
GxEPD2_3C<GxEPD2_420c_GDEY042Z98, GxEPD2_420c_GDEY042Z98::HEIGHT>
display(GxEPD2_420c_GDEY042Z98(5, 17, 16, 4));

void setup() {
    display.init(115200);
  
    // Enable fast full update (default)
    // Use display.selectFastFullUpdate(false) for extended temperature range
  
    // Full screen refresh
    display.setFullWindow();
    display.fillScreen(GxEPD_WHITE);
    display.setFont(&FreeMonoBold12pt7b);
    display.setTextColor(GxEPD_BLACK);
    display.setCursor(50, 100);
    display.print("Hello World!");
    display.refresh(); // Full refresh (~25s or ~10s fast)
  
    // Fast partial update example
    display.setPartialWindow(50, 100, 200, 50);
    display.fillRect(50, 100, 200, 50, GxEPD_WHITE);
    display.setCursor(50, 130);
    display.print("Updated!");
    display.refresh_bw(50, 100, 200, 50); // Fast partial (~1.5s)!
  
    // Deep sleep
    display.hibernate();
}

void loop() {
}
```

______________________________________________________________________

### Using ESPHome Component

```yaml
# ESPHome YAML Configuration
spi:
  clk_pin: 18
  mosi: 23
  miso: 19

display:
  - platform: epaper_spi
    id: my_display
    cs_pin: 5
    dc_pin: 16
    rst_pin: 17
    busy_pin: 4
    model: weact_4.2in_bwr
    lambda: |-
      it.print(0, 0, id(font), "Hello World!");
```

______________________________________________________________________

### Manual SPI Commands (Bare Metal)

```cpp
// Initialize display for 4.2" (GDEY042Z98)
void initDisplay() {
    digitalWrite(RST_PIN, LOW);
    delay(10);
    digitalWrite(RST_PIN, HIGH);
    delay(10);
  
    // Software reset
    sendCommand(0x12);
    delay(10);
  
    // Driver output control (300 gates)
    sendCommand(0x01);
    sendData(0x2D);  // (300-1) % 256
    sendData(0x01);  // (300-1) / 256
    sendData(0x00);
  
    // Border waveform
    sendCommand(0x3C);
    sendData(0x05);
  
    // Temperature sensor
    sendCommand(0x18);
    sendData(0x80);
}

// Write full screen
void writeFullScreen(uint8_t* blackData, uint8_t* redData) {
    // Set RAM area (full screen)
    sendCommand(0x11);
    sendData(0x03);
  
    sendCommand(0x44);
    sendData(0x00);
    sendData(49); // (400/8) - 1 = 50-1 = 49
  
    sendCommand(0x45);
    sendData(0x00);
    sendData(0x00);
    sendData(0x2C); // 300-1 = 299 = 0x12B = 0x2B
    sendData(0x01);
  
    // Write black data (15000 bytes)
    sendCommand(0x24);
    // transfer data...
  
    // Write red data (15000 bytes)
    sendCommand(0x26);
    // transfer data...
  
    // Trigger normal refresh
    sendCommand(0x22);
    sendData(0xF7);
    sendCommand(0x20);
  
    // Wait (~25 seconds)
    while (digitalRead(BUSY_PIN) == HIGH) {
        delay(10);
    }
}

// Fast partial refresh
void fastPartialRefresh(int x, int y, int w, int h) {
    x -= x % 8;
    w -= w % 8;
  
    // Set RAM window
    sendCommand(0x11);
    sendData(0x03);
    sendCommand(0x44);
    sendData(x / 8);
    sendData((x + w - 1) / 8);
    sendCommand(0x45);
    sendData(y & 0xFF);
    sendData(y >> 8);
    sendData((y + h - 1) & 0xFF);
    sendData((y + h - 1) >> 8);
  
    // Trigger BW differential refresh
    sendCommand(0x22);
    sendData(0xDC);
    sendCommand(0x20);
  
    // Wait (~1.5 seconds)
    while (digitalRead(BUSY_PIN) == HIGH) {
        delay(10);
    }
}
```

______________________________________________________________________

## Comparison: SSD1683 vs SSD1680 Display Families

| Feature         | 4.2" (SSD1683) | 2.9" (SSD1680) | 2.13" (SSD1680) |
| --------------- | -------------- | -------------- | --------------- |
| Resolution      | 400 × 300      | 128 × 296      | 128 × 250       |
| RAM Size        | 15000 bytes    | 4736 bytes     | 4000 bytes      |
| Fast Partial    | ✅ Yes (~1.5s) | ❌ No (~27s)   | ❌ No (~15s)    |
| Fast Full       | ✅ Yes (~10s)  | ❌ No          | ❌ No           |
| BW Differential | ✅ Yes         | ❌ No          | ❌ No           |
| Deep Sleep      | 0x11           | 0x01           | 0x01            |
| SPI Speed       | 25 MHz         | 30 MHz         | 30 MHz          |
| Full Refresh    | ~25s           | ~27s           | ~15s            |
| Partial Refresh | ~1.5s (fast)   | ~27s           | ~15s            |

______________________________________________________________________

## Troubleshooting

### Common Issues

1. Display not updating

   - Check SPI connections
   - Verify busy pin is working
   - Ensure proper power supply (3.3V)

1. Ghosting artifacts

   - Perform periodic full refresh
   - Full refresh takes ~25 seconds - don't interrupt

1. Fast partial not working correctly

   - Ensure coordinates are byte-aligned (x, w multiples of 8)
   - Use `refresh_bw()` method for fast partial updates

1. Deep sleep won't wake

   - Hardware reset required to wake from deep sleep
   - Check RST pin connection (SSD1683 uses 0x11 for deep sleep)

______________________________________________________________________

## References

- **SSD1683 Datasheet**: [`SSD1683_Datasheet.PDF`](WeActStudio.EpaperModule/Doc/SSD1683_Datasheet.PDF)
- **GxEPD2 Library**: <https://github.com/ZinggJM/GxEPD2>
- **GDEY042Z98 Panel**: <https://www.good-display.com/product/387.html>
- **WeAct Studio**: <https://github.com/WeActStudio>

______________________________________________________________________

*Document generated based on analysis of GxEPD2_420c_GDEY042Z98 implementation and SSD1683 controller datasheet.*
