# WeAct ePaper 2.13" (SSD1680) Display Controller Documentation

This document provides comprehensive documentation for the WeAct ePaper 2.13" BWR (Black-White-Red) display module based on the SSD1680 controller.

## Table of Contents

1. [Display Specifications](#display-specifications)
2. [SSD1680 Command Reference](#ssd1680-command-reference)
3. [Display Memory Structure](#display-memory-structure)
4. [Display Refresh Sequences](#display-refresh-sequences)
5. [Partial Update Scenarios](#partial-update-scenarios)
6. [Power Management](#power-management)
7. [Usage Examples](#usage-examples)

---

## Display Specifications

| Parameter | Value |
|-----------|-------|
| **Display Model** | WeAct 2.13" BWR E-Paper Module |
| **Controller** | SSD1680 |
| **Resolution** | 128 × 250 pixels |
| **Visible Resolution** | 122 × 250 pixels |
| **Colors** | Black, White, Red (3-Color) |
| **Display Type** | E-ink / E-Paper |
| **Interface** | SPI (Serial Peripheral Interface) |
| **Panel Code** | GDEY0213Z98 |

### Timing Specifications

| Operation | Time |
|-----------|------|
| Power On | 100 ms |
| Power Off | 150 ms |
| Full Refresh | 15000 ms (~15 seconds) |
| Partial Refresh | 15000 ms (~15 seconds) |

> **Note:** The SSD1680 does not support fast partial updates. Both full and partial refresh take approximately 15 seconds (faster than the 2.9" version).

---

## SSD1680 Command Reference

This section documents all commands used to control the SSD1680 e-paper display controller.

### Command Overview Table

| Hex Code | Command Name | Description | Data Bytes |
|----------|--------------|-------------|------------|
| `0x01` | Driver Output Control | Sets display resolution and gate scanning direction | 3 |
| `0x10` | Deep Sleep Mode | Enters/exits deep sleep power mode | 1 |
| `0x11` | Data Entry Mode | Sets the way X/Y address increments | 1 |
| `0x12` | SWRESET | Software reset command | 0 |
| `0x18` | Read Built-in Temperature Sensor | Reads internal temperature sensor | 1 |
| `0x21` | Display Update Control | Controls display update sequence | 2 |
| `0x22` | Display Update Control | Initiates display refresh | 1 |
| `0x24` | Write Black RAM | Writes black/white pixel data | N |
| `0x26` | Write Red RAM | Writes red color pixel data | N |
| `0x3C` | Border Waveform Control | Sets border behavior | 1 |
| `0x44` | Set RAM X Start/End | Sets RAM X address boundaries | 2 |
| `0x45` | Set RAM Y Start/End | Sets RAM Y address boundaries | 4 |
| `0x4E` | Set RAM X Counter | Sets RAM X address counter | 2 |
| `0x4F` | Set RAM Y Counter | Sets RAM Y address counter | 2 |
| `0x20` | Activate | Starts display update | 0 |

---

### Detailed Command Descriptions

#### 0x12 - SWRESET (Software Reset)

Performs a software reset of the controller. After this command, the display enters default state.

**Sequence:**

```cpp
_writeCommand(0x12);  // SWRESET
delay(10);            // Wait 10ms as per specification
```

---

#### 0x01 - Driver Output Control

Configures the display panel output parameters including resolution and scan direction.

**Parameters (2.13" GDEY0213Z98):**
- Byte 0 (0xF9): MUX gates (250 gates = 0xF9 + 1)
- Byte 1 (0x00): GDR (0 = CSS, 1 = GDR)
- Byte 2 (0x00): SM (Scan mode)

**Sequence:**

```cpp
_writeCommand(0x01); // Driver output control
_writeData(0xF9);    // 250 MUX gates
_writeData(0x00);    // GDR
_writeData(0x00);    // Scan direction
```

---

#### 0x11 - Data Entry Mode

Sets the direction in which the RAM address pointer auto-increments when writing data.

**Parameters:**
- `0x03` = X increment, Y increment (default for this display)

**Sequence:**

```cpp
_writeCommand(0x11); // Data entry mode
_writeData(0x03);    // X+1, Y+1 increment
```

---

#### 0x3C - Border Waveform Control

Controls the border (waveform) behavior during display updates.

**Parameters:**
- `0x05` = Border follows LUT (Look-up table)

**Sequence:**

```cpp
_writeCommand(0x3C); // Border waveform
_writeData(0x05);    // Border setting
```

---

#### 0x18 - Read Built-in Temperature Sensor

Enables/disables the internal temperature sensor.

**Parameters:**
- `0x80` = Enable internal temperature sensor

**Sequence:**

```cpp
_writeCommand(0x18); // Temperature sensor
_writeData(0x80);   // Enable internal sensor
```

---

#### 0x21 - Display Update Control

Controls various display update options.

**Parameters:**
- Byte 0: Display update option
- Byte 1: Enable RAM content (0x80 = enable)

**Sequence:**

```cpp
_writeCommand(0x21); // Display update control
_writeData(0x00);    // Option
_writeData(0x80);    // Enable RAM content
```

---

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

---

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
_writeData((y_end - 1) >> 8);      // Y end MSB
```

---

#### 0x4E - Set RAM X Counter

Sets the current RAM X address counter (pointer).

**Parameters:**
- Byte 0: X address / 8

**Sequence:**

```cpp
_writeCommand(0x4E);       // Set RAM X counter
_writeData(x / 8);         // Current X position
```

---

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

---

#### 0x24 - Write Black/White RAM

Writes pixel data to the Black/White RAM plane.

- `0x00` = White pixel
- `0xFF` (all bits set) = Black pixel

**Sequence:**

```cpp
_writeCommand(0x24); // Write B/W RAM
for (uint32_t i = 0; i < WIDTH * HEIGHT / 8; i++) {
    _writeData(black_data[i]); // Black=1, White=0
}
```

---

#### 0x26 - Write Red RAM

Writes pixel data to the Red color RAM plane.

- `0x00` = No red (shows B/W content)
- `0xFF` (all bits set) = Red pixel

**Note:** The data is inverted in the GxEPD2 library (`~color_value`), so:
- `0xFF` input becomes `0x00` = No red
- `0x00` input becomes `0xFF` = Red

**Sequence:**

```cpp
_writeCommand(0x26); // Write Red RAM
for (uint32_t i = 0; i < WIDTH * HEIGHT / 8; i++) {
    _writeData(~color_data[i]); // Red=1, No red=0 (inverted)
}
```

---

#### 0x22 - Display Update Control (Initiate Refresh)

Initiates the display refresh sequence. Must be followed by command 0x20 to activate.

**Parameters:**
- `0xF7` = Full refresh: Enable RAM content, enable bypass mode
- `0xF8` = Power on (used before refresh)
- `0x83` = Power off (used after refresh)

**Full Refresh Sequence:**

```cpp
_writeCommand(0x22); // Display update control
_writeData(0xF7);    // Enable RAM, bypass mode
_writeCommand(0x20); // Activate
_waitWhileBusy();    // Wait for completion (~15s)
```

**Power On Sequence:**

```cpp
_writeCommand(0x22);
_writeData(0xF8);    // Power on
_writeCommand(0x20);
_waitWhileBusy("_PowerOn", power_on_time);
```

**Power Off Sequence:**

```cpp
_writeCommand(0x22);
_writeData(0x83);    // Power off
_writeCommand(0x20);
_waitWhileBusy("_PowerOff", power_off_time);
```

---

#### 0x20 - Activate

Triggers the display update sequence. This command initiates the physical display refresh after the update control has been set.

**Sequence:**

```cpp
_writeCommand(0x20); // Activate display update
_waitWhileBusy("_Update", full_refresh_time);
```

---

#### 0x10 - Deep Sleep Mode

Enters deep sleep mode for minimum power consumption. Requires hardware reset to wake.

**Parameters:**
- `0x01` = Enter deep sleep mode

**Sequence:**

```cpp
// Before entering sleep:
_PowerOff();               // Power off the display

// Enter deep sleep:
_writeCommand(0x10);        // Deep sleep mode
_writeData(0x01);          // Enter deep sleep
_hibernating = true;       // Mark as hibernating

// To wake: Hardware reset required (toggle RST pin)
```

---

## Display Memory Structure

The SSD1680 has separate RAM planes for the 3-color display:

```
┌─────────────────────────────────────────────┐
│              BLACK/WHITE RAM                 │
│         (0x24 Command - 128×250 bits)       │
│  1 bit per pixel: 1=Black, 0=White          │
│  Size: 128 × 250 / 8 = 4000 bytes          │
├─────────────────────────────────────────────┤
│              RED RAM                         │
│         (0x26 Command - 128×250 bits)       │
│  1 bit per pixel: 1=Red, 0=No Red          │
│  Size: 128 × 250 / 8 = 4000 bytes          │
├─────────────────────────────────────────────┤
│         Total Buffer: 8000 bytes            │
└─────────────────────────────────────────────┘
```

### Color Mapping Logic

When displaying content, the final pixel color is determined by combining both RAM planes:

| Black RAM | Red RAM | Display Color |
|-----------|---------|---------------|
| 0 | 0 | White |
| 1 | 0 | Black |
| 0 | 1 | Red |
| 1 | 1 | Black (Red overwrites) |

---

## Display Refresh Sequences

### 1. Full Screen Refresh (Complete Update)

Full refresh is recommended after power-on, after deep sleep, and periodically to prevent ghosting.

```cpp
void _InitDisplay() {
    // Step 1: Software Reset
    _writeCommand(0x12);  // SWRESET
    delay(10);
  
    // Step 2: Driver Output Control (250 gates for 2.13")
    _writeCommand(0x01); // Driver output control
    _writeData(0xF9);    // 250 gates
    _writeData(0x00);    // GDR
    _writeData(0x00);    // SM
  
    // Step 3: Data Entry Mode
    _writeCommand(0x11); // Data entry mode
    _writeData(0x03);    // X+, Y+
  
    // Step 4: Border Waveform
    _writeCommand(0x3C); // Border waveform
    _writeData(0x05);    // Border LUT
  
    // Step 5: Temperature Sensor
    _writeCommand(0x18); // Temperature sensor
    _writeData(0x80);   // Enable internal
  
    // Step 6: Display Update Control
    _writeCommand(0x21); // Display update control
    _writeData(0x00);
    _writeData(0x80);
  
    // Step 7: Set full RAM area
    _setPartialRamArea(0, 0, WIDTH, HEIGHT);
}

void _Update_Full() {
    // Step 1: Set update control
    _writeCommand(0x22);
    _writeData(0xF7);    // Enable RAM, bypass mode
  
    // Step 2: Activate
    _writeCommand(0x20);
  
    // Step 3: Wait for completion (~15 seconds)
    _waitWhileBusy("_Update_Full", full_refresh_time);
  
    _power_is_on = false;
}
```

**Flow Diagram:**

```
┌─────────────┐
│   Power On  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  SWRESET    │  (0x12)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Configure │  (0x01, 0x11, 0x3C, 0x18, 0x21)
│   Display   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Write Black │  (0x24)
│     RAM     │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Write Red   │  (0x26)
│     RAM     │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Trigger    │  (0x22 → 0x20)
│  Refresh    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│Wait Busy    │  (~15 seconds)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│Display Shows│
│ New Image   │
└─────────────┘
```

---

### 2. Partial Update (Window Refresh)

Partial update allows updating only a region of the display. This is faster for small changes but may cause ghosting over time.

```cpp
void _setPartialRamArea(uint16_t x, uint16_t y, uint16_t w, uint16_t h) {
    // Set X boundaries
    _writeCommand(0x44);
    _writeData(x / 8);
    _writeData((x + w - 1) / 8);
  
    // Set Y boundaries
    _writeCommand(0x45);
    _writeData(y % 256);
    _writeData(y / 256);
    _writeData((y + h - 1) % 256);
    _writeData((y + h - 1) / 256);
  
    // Set X counter
    _writeCommand(0x4E);
    _writeData(x / 8);
  
    // Set Y counter
    _writeCommand(0x4F);
    _writeData(y % 256);
    _writeData(y / 256);
}

void _Update_Part() {
    // Same as full update for this controller
    _writeCommand(0x22);
    _writeData(0xF7);
    _writeCommand(0x20);
    _waitWhileBusy("_Update_Part", partial_refresh_time);
    _power_is_on = false;
}
```

**Important Notes for Partial Updates:**
1. Coordinates must be byte-aligned (x and w must be multiples of 8)
2. For SSD1680, partial refresh takes ~15 seconds (same as full refresh)
3. This display does NOT support fast partial update
4. Periodic full refresh is recommended to prevent ghosting

---

## Partial Update Scenarios

### Scenario 1: Updating a Text Field

```cpp
void updateTextField(const char* text, int x, int y, int w, int h) {
    // Ensure x and w are byte-aligned
    x -= x % 8;
    w = (w + 7) / 8 * 8;
  
    // Initialize partial mode
    _Init_Part();
  
    // Set the RAM window
    _setPartialRamArea(x, y, w, h);
  
    // Write black data (text)
    _writeCommand(0x24);
    for (uint32_t i = 0; i < w * h / 8; i++) {
        _writeData(text_bitmap[i]);
    }
  
    // Write red data (optional highlights)
    _writeCommand(0x26);
    for (uint32_t i = 0; i < w * h / 8; i++) {
        _writeData(~red_highlight[i]);
    }
  
    // Trigger partial refresh
    _Update_Part();
}
```

---

### Scenario 2: Updating a Progress Bar

```cpp
void updateProgressBar(int percentage, int x, int y, int w, int h) {
    // Byte-align coordinates
    x -= x % 8;
    w = (w + 7) / 8 * 8;
  
    _Init_Part();
    _setPartialRamArea(x, y, w, h);
  
    // Create progress bar bitmap
    uint8_t buffer[320]; // Example for 128x20 area
    memset(buffer, 0x00, sizeof(buffer));
  
    int filledWidth = (w * percentage) / 100;
    for (int row = 0; row < h; row++) {
        for (int col = 0; col < filledWidth / 8; col++) {
            buffer[row * (w/8) + col] = 0xFF;
        }
    }
  
    // Write black RAM
    _writeCommand(0x24);
    _writeData(buffer, sizeof(buffer));
  
    // Write red RAM (optional)
    _writeCommand(0x26);
  
    _Update_Part();
}
```

---

### Scenario 3: Clock Display Update

```cpp
void updateClock(int hours, int minutes) {
    // Create a 64x32 window for clock (smaller than 2.9")
    int x = 32;
    int y = 80;
    int w = 64;
    int h = 32;
  
    x -= x % 8;
    w = (w + 7) / 8 * 8;
  
    _Init_Part();
    _setPartialRamArea(x, y, w, h);
  
    // Generate clock bitmap (pseudocode)
    uint8_t clockBitmap[256]; // 64 * 32 / 8
    drawClockDigits(clockBitmap, hours, minutes);
  
    // Write black (digits)
    _writeCommand(0x24);
    _writeData(clockBitmap, sizeof(clockBitmap));
  
    // Write red (optional red elements)
    _writeCommand(0x26);
  
    _Update_Part();
}
```

---

## Power Management

### 1. Normal Power Off

Turns off panel driving voltages but keeps controller powered.

```cpp
void _PowerOff() {
    if (_power_is_on) {
        _writeCommand(0x22);
        _writeData(0x83);    // Power off command
        _writeCommand(0x20);
        _waitWhileBusy("_PowerOff", power_off_time);
    }
    _power_is_on = false;
}
```

---

### 2. Deep Sleep Mode

For minimum power consumption when display doesn't need to be updated for extended periods.

```cpp
void hibernate() {
    _PowerOff();
    if (_rst >= 0) {
        _writeCommand(0x10); // Deep sleep mode
        _writeData(0x01);    // Enter deep sleep
        _hibernating = true;
    }
}
```

**To Wake from Deep Sleep:**
- Hardware reset is required (toggle RST pin low → high)
- After reset, full re-initialization is needed

---

### 3. Power On Sequence

```cpp
void _PowerOn() {
    if (!_power_is_on) {
        _writeCommand(0x22);
        _writeData(0xF8);    // Power on
        _writeCommand(0x20);
        _waitWhileBusy("_PowerOn", power_on_time);
    }
    _power_is_on = true;
}
```

---

## Usage Examples

### Using GxEPD2 Library

```cpp
#include <GxEPD2_3C.h>
#include <Fonts/FreeMonoBold9pt7b.h>

// Pin connections for ESP32
// CS=5, DC=17, RST=16, BUSY=4
GxEPD2_3C<GxEPD2_213_Z98c, GxEPD2_213_Z98c::HEIGHT>
display(GxEPD2_213_Z98c(5, 17, 16, 4));

void setup() {
    display.init(115200);

    // Full screen refresh
    display.setFullWindow();
    display.fillScreen(GxEPD_WHITE);
    display.setFont(&FreeMonoBold9pt7b);
    display.setTextColor(GxEPD_BLACK);
    display.setCursor(10, 50);
    display.print("Hello World!");
    display.refresh();
  
    // After display shows content, go to deep sleep
    display.hibernate();
}

void loop() {
    // Not used - single shot display
}
```

---

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
    model: weact_2.13in_bwr
    lambda: |-
      it.print(0, 0, id(font), "Hello World!");
```

---

### Manual SPI Commands (Bare Metal)

```cpp
// Initialize display for 2.13" (GDEY0213Z98)
void initDisplay() {
    digitalWrite(RST_PIN, LOW);
    delay(10);
    digitalWrite(RST_PIN, HIGH);
    delay(10);
  
    // Software reset
    sendCommand(0x12);
    delay(10);
  
    // Driver output control (250 gates for 2.13")
    sendCommand(0x01);
    sendData(0xF9);
    sendData(0x00);
    sendData(0x00);
  
    // Data entry mode
    sendCommand(0x11);
    sendData(0x03);
  
    // Border waveform
    sendCommand(0x3C);
    sendData(0x05);
  
    // Temperature sensor
    sendCommand(0x18);
    sendData(0x80);
  
    // Display update control
    sendCommand(0x21);
    sendData(0x00);
    sendData(0x80);
}

// Write full screen
void writeFullScreen(uint8_t* blackData, uint8_t* redData) {
    // Set RAM area
    sendCommand(0x44);
    sendData(0x00);
    sendData(0x10); // (128/8) - 1 = 16
  
    sendCommand(0x45);
    sendData(0x00);
    sendData(0x00);
    sendData(0xFA); // 250 - 1 = 249 = 0xFA
    sendData(0x00);
  
    // Write black data (4000 bytes for 128x250)
    sendCommand(0x24);
    for (int i = 0; i < 4000; i++) {
        sendData(blackData[i]);
    }
  
    // Write red data
    sendCommand(0x26);
    for (int i = 0; i < 4000; i++) {
        sendData(~redData[i]); // Inverted
    }
  
    // Trigger refresh
    sendCommand(0x22);
    sendData(0xF7);
    sendCommand(0x20);
  
    // Wait for busy to go low (~15 seconds)
    while (digitalRead(BUSY_PIN) == HIGH) {
        delay(10);
    }
}
```

---

## Comparison: 2.13" vs 2.9" SSD1680 Displays

| Feature | 2.13" (GDEY0213Z98) | 2.9" (GDEM029C90) |
|---------|---------------------|--------------------|
| Resolution | 128 × 250 | 128 × 296 |
| Visible Resolution | 122 × 250 | 128 × 296 |
| RAM Size (Black) | 4000 bytes | 4736 bytes |
| RAM Size (Red) | 4000 bytes | 4736 bytes |
| Total Buffer | 8000 bytes | 9472 bytes |
| Driver Output (0x01) | 0xF9 | 0x27 |
| Full Refresh Time | ~15 seconds | ~27 seconds |
| Partial Refresh Time | ~15 seconds | ~27 seconds |
| Panel Code | GDEY0213Z98 | GDEM029C90 |

---

## Troubleshooting

### Common Issues

1. **Display not updating**
   - Check SPI connections
   - Verify busy pin is working
   - Ensure proper power supply (3.3V)

2. **Ghosting artifacts**
   - Perform periodic full refresh
   - Full refresh takes ~15 seconds - don't interrupt

3. **Partial update not working**
   - Ensure coordinates are byte-aligned (x, w multiples of 8)
   - Note: This controller doesn't support fast partial updates

4. **Deep sleep won't wake**
   - Hardware reset required to wake from deep sleep
   - Check RST pin connection

---

## References

- **SSD1680 Datasheet**: [`SSD1680_Datasheet.pdf`](WeActStudio.EpaperModule/Doc/SSD1680_Datasheet.pdf)
- **GxEPD2 Library**: https://github.com/ZinggJM/GxEPD2
- **GDEY0213Z98 Panel**: https://www.good-display.com/product/392.html
- **WeAct Studio**: https://github.com/WeActStudio

---

*Document generated based on analysis of GxEPD2_213_Z98c implementation and SSD1680 controller datasheet.*
