# Memory Log — RAM / flash / heap per device and ESPHome version

Purpose: one place to compare memory use across ESPHome releases and build parameters (savings or regressions), per device. Especially watch **esp12f-10 Office** (ESP8266, many sensors, Prometheus `/metrics`, heap-starved).

**Convention (every upgrade / flash, Pawelo 2026-11-21):** after a compile and after a flash, append rows here with the ESPHome version, the build parameters that matter (flags, buffer sizes, framework), static RAM/flash from the build output, and runtime heap (free + max block). Never overwrite old rows; add new ones. Static numbers come from the compile summary (`RAM: ... used N bytes`, `Flash: ... used N bytes`). Static RAM is `.data` + `.bss` only; the free heap at runtime is what is left, minus stack and runtime allocations, so **static delta ≈ heap delta** for a fixed config, but only a heap measurement proves it.

How to measure runtime heap: `esphome logs <yaml> --device <host>` (the `debug` platform prints `Heap Free` / `Heap Max Block` every update), or Prometheus for long uptime. State the sample time, because heap settles after boot and an attached API client costs memory.

## Static build size (compile output)

ESP8266 total RAM 81 920 B, flash 1 044 464 B.

| Date | ESPHome | Device (config) | Build parameters | RAM used | Flash used | Notes |
|------|---------|-----------------|------------------|----------|------------|-------|
| 2026-11-21 | 2026.10.2 | esp12f-10 Office (`2_PROD/esp12f-10_Office.yaml`) | current repo (MMU flag off), native toolchain | 39 748 B (48.5%) | 554 264 B (53.1%) | baseline, compiled in a separate venv |
| 2026-11-21 | **2026.11.0** | esp12f-10 Office | same | **37 300 B (45.5%)** | 556 660 B (53.3%) | RAM −2 448 B (−6.2%), flash +2 396 B vs 10.2. Compile only, not flashed (deferred) |
| 2026-11-21 | 2026.11.0 | esp12f-10 Office + boot log buffer 2 kB (`boot_log_level: INFO`, replay in `mqtt on_connect`) | + `logger: boot_log_buffer_size: 2kB` | 39 344 B | 558 016 B | RAM +2 044 B vs 11.0 plain: eats the whole 11.0 saving (−404 B vs 10.2). Simulation, compile only |
| 2026-11-21 | 2026.11.0 | esp12f-10 Office, boot buffer permanent in shared includes (2 kB) | repo state after the change, compile only, **not flashed** (flash at the Nieporęt site, start with `boot_buffer: "1kB"`) | 39 356 B (48.0%) | 558 092 B (53.4%) | RAM +2 056 B vs plain 11.0 (37 300 B); −392 B vs 10.2 (39 748 B) |
| 2026-11-21 | 2026.11.0 | esp12f-15 Upstairs, boot buffer 2 kB | same | 38 480 B (47.0%) | 515 476 B (49.4%) | RAM +2 056 B, flash +1 432 B vs plain 11.0 |
| 2026-11-21 | 2026.11.0 | esp32-39 Attic, boot buffer 2 kB | same | 54 400 B (30.1%) | 1 071 035 B (58.4%) | RAM +2 040 B, flash +1 252 B vs plain 11.0 |
| 2026-11-21 | 2026.11.0 | esp32-14 Salon, boot buffer 2 kB | same | 132 643 B (38.8%) | 1 320 343 B (33.6%) | RAM +2 040 B, flash +1 228 B vs plain 11.0 |
| 2026-11-21 | 2026.11.0 | esp32-36 Garage_Gate, boot buffer 2 kB | same | 114 996 B (35.8%) | 1 227 674 B (66.9%) | RAM +2 040 B, flash +1 462 B vs plain 11.0 |
| 2026-11-07 | 2026.10.2 | esp12f-29 rig (`0_DEV/esp12f_dev.yaml`, with BH1750) | MMU flag on/off gave same RAM | 41 704 B (50.9%) | 581 964 B (55.7%) | from `ESPHOME_2026.10.0.md` |
| 2026-11-21 | **2026.11.0** | esp12f-29 rig | current repo | **39 300 B (48.0%)** | 584 288 B (55.9%) | RAM −2 404 B, flash +2 324 B vs 10.2. Flashed |
| 2026-11-21 | 2026.11.0 | esp12f-29 rig + boot log buffer 2 kB (INFO), no delay on replay | experiment | 41 312 B (50.4%) | 585 228 B (56.0%) | replay without `delay` did not reach Loki |
| 2026-11-21 | 2026.11.0 | esp12f-29 rig + boot log buffer 2 kB (INFO), `delay: 3s` before replay | experiment, flashed (rig currently runs this) | 41 344 B (50.5%) | 585 612 B (56.1%) | replay reached Loki |
| 2026-11-21 | 2026.11.0 | esp12f-29 rig + boot log buffer 2 kB (INFO), `delay: 3s`, `uptime_ms` marker line before replay | experiment, flashed (rig currently runs this) | 41 356 B (50.5%) | 585 704 B (56.1%) | +12 B RAM, +92 B flash vs the build without marker |
| 2026-11-07 | 2026.10.2 | esp12f-15 Upstairs | — | 46.5% | 48.8% | % only, from `ESPHOME_2026.10.0.md` |
| 2026-11-21 | **2026.11.0** | esp12f-15 Upstairs | — | 36 424 B (44.5%) | 514 044 B (49.2%) | compile only |
| 2026-11-07 | 2026.10.2 | esp12f-25 AquariumWindow | — | 46.7% | 52.2% | % only |
| 2026-11-21 | **2026.11.0** | esp12f-25 AquariumWindow | — | 35 988 B (43.9%) | 548 008 B (52.5%) | compile only |
| 2026-11-07 | 2026.10.2 | esp12f-21 Underfloor | — | 46.9% | 52.4% | % only |
| 2026-11-21 | **2026.11.0** | esp12f-21 Underfloor | — | 35 932 B (43.9%) | 549 372 B (52.6%) | compile only |
| 2026-11-21 | 2026.10.2 | esp12f-21 Underfloor (before flash, Prometheus) | long uptime | 31 632 B | 27 024 B | baseline right before the 11.0 flash; device carried an old stored Soft WDT crash dump (RTC, WiFi stack), no reboot loop; metrics complete |
| 2026-11-21 | **2026.11.0** | esp12f-21 Underfloor, boot buffer 2 kB, **flashed (PROD)** | ~1.5 min after boot (Prometheus) | 32 536 B | 25 264 B | +904 B free, −1 760 B max block vs 10.2 sample (max block is fragmentation-sensitive, recheck after ≥ 2 h). Static 37 988 B (46.4%) / 550 788 B. Replay in Loki OK (714 B, 0 dropped), stale crash dump gone |
| 2026-11-07 | 2026.10.2 | esp12f-11 Entrance_Entry | — | 47.2% | 52.6% | % only |
| 2026-11-21 | **2026.11.0** | esp12f-11 Entrance_Entry | — | 36 428 B (44.5%) | 552 124 B (52.9%) | compile only |

ESP8266 pattern on 11.0: static RAM drops about 2–3 percentage points (≈ 1.6–2.4 kB) on every device; flash is flat to +0.3 pt. Consistent with the changelog's ESP8266 RAM reduction.

### ESP32 family (compile sweep on 2026.11.0, 2026-11-21)

No 2026.10.2 static baselines exist for ESP32 except Salon (% only, from `ESPHOME_2026.10.0.md`); the 2026.10.0 notes recorded heap for the rest. `esphome config` on Salon passed (new RMT fit check OK).

| Date | ESPHome | Device | Build parameters | RAM used | Flash used | Notes |
|------|---------|--------|------------------|----------|------------|-------|
| 2026-11-21 | 2026.11.0 | esp32-39 Attic | ESP-IDF, recommended | 52 360 B (29.0% of 180 736) | 1 069 783 B (58.3% of 1 835 008) | compile only |
| 2026-11-21 | 2026.11.0 | esp32-05 Shades_WinterGardenUpp | ESP-IDF, recommended | 64 584 B (35.7%) | 1 340 179 B (73.0%) | compile only; highest flash use of the set |
| 2026-11-21 | 2026.11.0 | esp32-06 Garden_Gateway | ESP-IDF, recommended | 53 580 B (29.6%) | 1 124 451 B (61.3%) | compile only; still on 2026.8.2 on the device (KI-2) |
| 2026-11-21 | 2026.11.0 | esp32-36 Garage_Gate (ESP32-C3) | Arduino, recommended | 112 956 B (35.2% of 321 296) | 1 226 212 B (66.8%) | compile only |
| 2026-11-07 | 2026.10.2 | esp32-14 Salon (ESP32-S3) | — | 39.6% | 33.7% | % only |
| 2026-11-21 | 2026.11.0 | esp32-14 Salon | — | 130 603 B (38.2% of 341 760) | 1 319 115 B (33.5% of 3 932 160) | compile only; RAM −1.4 pt vs 10.2 |
| 2026-11-21 | **2026.11.0** | esp32-30 rig (`0_DEV/esp32_dev.yaml`) | ESP-IDF, plain build, no boot buffer | 51 896 B (28.7% of 180 736) | 1 093 339 B (59.6% of 1 835 008) | flashed OTA, boot OK (safe_mode counter reset ~25 s after boot) |
| 2026-11-21 | 2026.11.0 | esp32-30 rig + boot log buffer 2 kB (INFO), `delay: 3s`, `uptime_ms` marker | experiment, flashed (rig currently runs this) | 53 944 B (29.8%) | 1 094 515 B (59.6%) | RAM +2 048 B, flash +1 176 B vs plain 11.0 |
| 2026-11-21 | 2026.11.0 | esp32-30 rig + boot buffer 2 kB + `flash_chip: generic` (temp copy of board_esp32.yaml) | experiment, flashed (rig currently runs this) | 53 385 B (29.5%) | 1 092 472 B (59.5%) | vs boot-buffer build without it: RAM −559 B, flash −2 043 B; IRAM 78 659 B (45.7%); `[W][app:188] Set flash_chip` warning gone |
| — | 2026.5.3 | esp32-35 Pump_Garage | pinned, FRAM override farm | not compiled | not compiled | stays on 5.3 |

## Runtime heap (flashed devices)

| Date | ESPHome | Device | Sample time | Heap free | Max block | Notes |
|------|---------|--------|-------------|-----------|-----------|-------|
| 2026-11-07 | 2026.10.2 | esp12f-29 rig | idle +60–180 s | 30 632 B | 26 688 B | MMU flag test, same either way |
| 2026-11-07 | 2026.10.2 | esp12f-29 rig | ~30 s after boot | 29 984 B | 22 664 B | rollout sample |
| 2026-11-21 | **2026.11.0** | esp12f-29 rig | ~25 s after boot, API client attached | 31 544 B | 25 600 B | one sample, plain build |
| 2026-11-21 | 2026.11.0 | esp12f-29 rig + boot buffer 2 kB | ~1 s / ~16 s after API attach | 27 944 B / 29 504 B | 25 816 B | −2 040 B vs plain at comparable time, equals the buffer; max block unchanged |
| 2026-11-07 | 2026.10.2 | esp12f-15 Upstairs | ~30 s after boot | 34 080 B | 29 808 B | from `ESPHOME_2026.10.0.md` |
| 2026-11-21 | 2026.10.2 | esp12f-15 Upstairs (before flash) | ~12–27 s after API attach | 32 648 B / 32 632 B | 28 712 B | baseline taken right before the 11.0 flash |
| 2026-11-21 | **2026.11.0** | esp12f-15 Upstairs, boot buffer 2 kB, **flashed (PROD)** | ~14–44 s after boot, API client attached | 32 808 B / 32 784 B | 28 952 B | +152 B heap, +240 B max block vs 10.2: 11.0's RAM saving (~2.4 kB) cancels the 2 kB buffer. Replay in Loki (`logs.lan`) OK: 714 B used, 0 dropped, `level=info`, corrected times. Static 38 480 B / 515 476 B |
| 2026-11-07 | 2026.10.2 | esp12f-25 AquariumWindow | ~30 s | 32 448 B | 25 240 B | same source |
| 2026-11-07 | 2026.10.2 | esp12f-21 Underfloor | ~30 s | 32 968 B | 29 144 B | same source |
| 2026-11-07 | 2026.10.2 | esp12f-11 Entrance_Entry | ~30 s | 32 392 B | 28 632 B | same source |
| 2026-11-07 | 2026.10.2 | esp32-30 rig | — | ~219 kB | 110 592 B | ESP-IDF |
| 2026-11-21 | **2026.11.0** | esp32-30 rig | ~5–40 s after boot, API client attached | 218 484 B | 110 592 B | vs ~219 kB / 110 592 B on 10.2: flat |
| 2026-11-21 | 2026.11.0 | esp32-30 rig + boot buffer 2 kB | ~30–35 s after boot, API client attached | 216 376 B / 216 364 B | 110 592 B | −2 108 B vs plain, equals the buffer; max block unchanged; 0.1% of ESP32 heap |
| 2026-11-21 | 2026.11.0 | esp32-30 rig + boot buffer 2 kB + `flash_chip: generic` | ~5–20 s after boot | 218 248 B / 218 244 B | 110 592 B | +1 868 B vs boot-buffer build without `flash_chip` (216 376 B); ≈ plain 11.0 (218 484 B) |
| 2026-11-07 | 2026.10.2 | esp32-36 Garage_Gate | — | 169 444 B | 114 688 B | |
| 2026-11-07 | 2026.10.2 | esp32-14 Salon | — | 151 444 B | 139 264 B | RAM 39.6% / flash 33.7% |

esp12f-10 Office has no heap record on 2026.10.x (flash deferred). **Before flashing Office on 11.0, record its current heap and `/metrics` completeness from Prometheus, then flash, then record again after ≥ 2 h.**

## Experiment: boot log buffer (2026-11-21, esp12f-29)

`logger: boot_log_buffer_size: 2kB`, `boot_log_level: INFO`, and `logger.replay_boot_logs:` in `mqtt: on_connect:` (temporary copies of the includes, removed afterwards).

- Replay called directly in `on_connect` publishes nothing: the MQTT log callback publishes only when the client is `is_connected()`, which is not yet true inside the backend `on_connect` callback. With `- delay: 3s` before the action it works.
- Result in Loki (`logs.nam`, `{mqtt_node="esp12f-29"}`): "Replaying boot logs (666 bytes used, 0 lines dropped)" followed by 12 lines stamped `@<ms>` from `Log initialized @8742ms` to `wifi Connected @12638ms`. Pre-network lines of the current boot, as intended.
- Cost: +2 044 B static RAM (the 2 kB buffer plus bookkeeping), +1 324 B flash. Free heap −2 040 B, max block unchanged. On Office this cancels the whole 11.0 RAM saving.
- Decision pending: consider 1 kB, or `boot_log_level: WARN` (default), or rollout to ESP32 only. 666 B used by INFO capture on the rig suggests 1 kB is enough for INFO on a small config; Office has more setup lines.
- Pipeline follow-up (2026-11-21): Larry's `mqtt_logger` change on `ppi41` verified in Loki: replayed lines have `level=info` and corrected timestamps (boot start = marker time − `uptime_ms`). Buffer use on the rig after the marker: 719 B of 2 kB, 0 lines dropped, which supports trying 1 kB for INFO on small configs (Office not measured).
- esp32-30 (2026-11-21): same buffer/delay/marker recipe works on ESP-IDF. Replay in Loki: 12 lines `@141ms`..`@4051ms` with `level=info` (a `warning` line keeps `level=warning`), corrected timestamps (boot ≈ 20:34:27.84, `@141ms` stamped 20:34:27.983), `Replaying boot logs (869 bytes used, 0 lines dropped)`. 869 B used on ESP32 (more setup lines than the ESP8266 rig's 719 B), so 1 kB is tight there; on ESP32 the 2 kB cost is negligible, so ESP32 rollout is cheap and ESP8266 is the open question.
