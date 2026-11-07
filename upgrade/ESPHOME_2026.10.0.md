# ESPHome 2026.10.0 — Upgrade Impact for esphome_scripts

Covers changes from the last installed version (**2026.8.2**) to **2026.10.0** (released 2026-10-21; 2026.9.x patches are folded in). Patches **2026.10.1** (2026-10-27) and **2026.10.2** (2026-11-02, latest) reviewed 2026-11-07, see "Patch releases" below.
Use this file as a checklist when updating configs and reflashing devices.

> **Installed version:** 2026.10.2 (in `.venv`) — upgraded 2026-11-07 (analysis 2026-10-23). **Rollout status 2026-11-07:** rigs esp12f-29 and esp32-30 + esp12f-15, -25, -21, -11 flashed and verified; esp12f-10 Office deliberately deferred; esp32-36 and esp32-14 flashed (Salon IR + volume/mute checks pending on site); esp32-06 OTA fell back to 2026.8.2 (KI-2, open); esp32-39, -05 not started; esp32-32 (FRAM, Pump-only) not flashed.
> **Sources:** esphome.io changelog 2026.10.0 (full page), PR descriptions #18997, #19100, #19101, #19307, #19886, upstream source at tag `2026.10.0` (`esp8266/__init__.py`, `core/config.py`, `esp32/preferences.h`).
> **Verification:** the ESP8266 native toolchain is now verified by compile + bench run (see "Rollout results"). The remaining "No action" items for ESP32 are still grep/source-reading results, not build results.

---

## Breaking Changes

Verified against the actual repo (grep), not assumed.

| Change | Affects | Action required |
|--------|---------|----------------|
| **ESP8266: native `arduino` toolchain is now the default** (#19886; PlatformIO toolchain deprecated, removed in 2027.4.0) | All 5 ESP8266 PROD devices (esp12f-10, 11, 15, 21, 25) + ESP8266 rig esp12f-29 | **Compile + bench test required.** `framework.version: recommended` (3.1.2) and board `esp12e` are supported by the native toolchain; no custom `source:` / `platform_version` / `toolchain:` anywhere (grep). Open risk: see "`platformio_options` under native toolchain" below. |
| **`esphome: platformio_options: build_flags` deprecated under native toolchains** (removal in **2026.12.0**) | `includes/board_esp8266.yaml:36-44` — `-DVTABLES_IN_FLASH` and `-DPIO_FRAMEWORK_ARDUINO_MMU_CACHE16_IRAM32_SECHEAP_NOTSHARED` (heap/cache tuning for the Prometheus `/metrics` endpoint, 20250720) | Compile prints a deprecation warning; flags are still forwarded as plain `-D` defines. Migrate to `esphome: build_flags:` (same list) — can be done before the upgrade, `esphome->build_flags` already exists in 2026.8.2. **Whether the `PIO_FRAMEWORK_ARDUINO_MMU_*` macro still selects the 16 kB cache / 32 kB IRAM layout on the native path is unverified** — it was a PlatformIO-builder macro. Compare free heap before/after on esp12f-29 / Office. |
| **`light`: `restore_mode` → `restore_state`** (#18997) | `lights/led_rgb.yaml:28` (Salon RGB), `0_DEV/*_dev.yaml` | **No action.** `restore_mode` keeps working unchanged (only deprecated in docs). The one behavior change hits configs with `initial_state: {state: ...}` and no `restore_mode` — grep finds **no `initial_state` anywhere** in `2_PROD`, `lights`, `includes`, `0_DEV`. |
| **`remote_receiver`: RMT ring buffer sized from `receive_symbols`** (#19100) | `interfaces/ir_receiver.yaml` → active only on `esp32-14_Salon` (`rmt_symbols: 64`, no `buffer_size`) | Low risk. Ring is now 4 slots × (64×4+16 B) ≈ 1.1 kB; a NEC frame (~34 symbols) fits one slot. **Verify after flash that IR remote codes still arrive** (IR dump in log). Garden_Gateway / Garage_Gate include is commented out. |
| **`remote_receiver`: `buffer_size` = bytes on pulse-ring targets** (#19101) | ESP8266 / non-RMT targets | **Not applicable** — no `buffer_size` set anywhere (grep); `ir_receiver__arduino.yaml` is not included by any active PROD file. |
| **`speaker` media player: volume and mute independent; `codec_support_enabled` removed** (#19307, #18412, #19074) | `esp32-14_Salon` (`i2s/set_i2s_media_player.yaml`, MAX98357A) | `codec_support_enabled` — not used (grep). Behavior: volume 0 no longer reports "muted", changing volume while muted keeps mute, boot no longer forces mute for saved volume 0. No `on_mute`/`on_unmute` automations in the repo. **Check the media player in HA after flash** (volume slider + mute button). |
| **`epaper_spi`: reTerminal Sticky / SSD1677 changes** (#19213) | `esp32-05`, `esp32-35` use `epaper_spi` with model `weact-2.9in-3c` | **Not applicable** — breaking change is limited to reTerminal Sticky (SSD1677). |
| **`serial_proxy`, `sendspin` switch, `hoermann_hcp`, `usb_host`, `host` platform, `teleinfo`** | — | **Not applicable** — none used (grep). `host` is only built if someone runs it locally. |
| **ESP32: mbedTLS trimmed to client-only defaults** (#19088) | All ESP32 PROD (MQTT client, API, OTA) | Low risk — repo only uses TLS as a client. No ESP32 runs an HTTPS server. Watch MQTT/OTA reconnect in the first boot log. |
| **ESP32: recommended Arduino bumped to 3.3.12 / PlatformIO 6.2.0** (#19417) | `esp32-36_Garage_Gate`, `esp32-35_Pump_Garage` (Arduino framework, `framework_version: recommended`) | Recompile sweep covers it. esp32-35 stays pinned (see below). |

### `platformio_options` under native toolchain (ESP8266) — details

From upstream `core/config.py` (`_add_platformio_options`) at 2026.10.0: under a native toolchain `build_flags` is deprecated-but-forwarded (`cg.add_build_flag`), `build_unflags` / `lib_deps` / `lib_ignore` are translated, and only `board_build.f_cpu`, `board_build.ldscript`, `board_upload.maximum_size` are honored from the rest; everything else logs `... is ignored when building with the native 'arduino' toolchain`. This repo sets only `build_flags`, so nothing is silently dropped — but the *effect* of the MMU macro on the memory map is the thing to measure.

Fallback if the native toolchain behaves worse (heap, crashes): add `toolchain: platformio` under `esp8266:` in `includes/board_esp8266.yaml` (works until 2027.4.0, prints a deprecation warning).

### Override farm (`esphome-overrides/`, PR#14119 NVM/FRAM) — expected drift

Checked ahead of time against upstream `2026.10.0` (snapshot diff, per `feedback_refresh_sh_check_snapshots`):

- `.preferences.h.upstream` and `.preference_backend.h.upstream` **differ from 2026.10.0**: upstream added RTC-backed preference storage (`USE_ESP32_RTC_PREFERENCES`, `rtc_offset`, `in_flash`, `load_from_key`). `refresh.sh` will report `⚠ CHANGED` → a manual rebase of the two patched headers is required before any FRAM build compiles.
- Farm is also missing two new sibling files (`atexit_stubs.cpp`, `vasprintf_stubs.cpp`) — `refresh.sh` re-symlinks them.
- The snapshot already differs from pip 2026.8.2, i.e. the drift Pawelo declined to fix on 2026-10-08 (`esp32-35` pinned on 2026.5.3). **2026.10.0 does not change that decision**: FRAM/NVM is not in the changelog and PR#14119 is closed upstream.
- Consequence: only `esp32-35_Pump_Garage` and the FRAM rig `esp32-32` depend on the farm. Everything else upgrades normally. Keep `esp32-35` on 2026.5.3.

---

## New Features Worth Exploring

| Feature | Rating | Why |
|---------|--------|-----|
| **Native ESP8266 toolchain** — fresh build 17.8 s → 9.2 s, warm ccache 7.6 s → 2.8 s (#19886 numbers); runs natively on Apple Silicon (no Rosetta) | ★★★ | Faster 5-device sweep; removes the Rosetta dependency on pMacM5. |
| **Compressed OTA uploads** (#19037, ESP8266/ESP32/LibreTiny) | ★★ | Faster OTA on weak WiFi (Pump, Attic). Automatic, no config. |
| **`esp32: skip-bootloader` for OTA-only builds** (#19925) | ★★ | Handy in the bootloader-refresh procedure (esp32-05/06 lessons). |
| **Outgoing API connections / HA onboarding wizard** (#18919, #19966) | ★ | Not needed; devices keep the current HA link. |
| **`suspend_loop` / `loop_interval`** (#18136) | ★ | Possible power/CPU savings later; nothing to do now. |
| **`i2s_audio` software volume ramping** (#19302) | ★ | Less clicking on Salon speaker. |
| **FRAM / NVM component** | — | **Not in this release.** Do not wait for it in 2026.10.x. |

## Positive Fixes

- ESP8266: UART software-serial RX ISR no longer blocks for a whole byte (#18519); `spi` writes avoid a heap copy (#19265); log strings kept in flash (#19577); ArduinoJson float tables in flash (#20416).
- ESP8266 `wifi`: failed attempt no longer poisons the next one (#20183) — relevant to flaky-WiFi devices.
- `remote_receiver` wakes the main loop on RMT frame (#19102).
- `esp32`: NVS cache in PSRAM when guaranteed (#19378); UART flushed before sleep on IDF 6 (#18975).
- Many `register_apply_action` / user-provided-constructor refactors — flash/RAM savings, no config impact.

---

## Patch releases 2026.10.1 / 2026.10.2 (reviewed 2026-11-07)

Source: GitHub release notes only (esphome.io has no section for patches). No change is marked breaking; "fix" below is inferred from PR titles, not verified in source. **Target version for the upgrade is 2026.10.2.**

| Release | Item | Relevance |
|---------|------|-----------|
| 10.2 | **#22111 `ota`: workaround for LibreTiny OTA bricking RTL8710B on compressed update** | Highest-severity item, but **not applicable** — no LibreTiny RTL8710B device in the repo (BK7231N is a different chip family). Relevant to compressed OTA only on LibreTiny. |
| 10.2 | #21786 `esp32`/`audio_http`: keep TLS 1.3 working | Not used (Salon uses I2S speaker, no `audio_http`). No action. |
| 10.2 | #21967 core: Apple Silicon `cc1plus` wrapper started via `sh` when Python path has a space | Build-tool fix, relevant to pMacM5 only if the venv path has a space. Not our case. |
| 10.2 | #21705 `http_request`: macOS host build + precompiled header; #22114 `host`: download in Device Builder; #22077 `bluetooth_proxy` | Not used. |
| 10.1 | #21328 `mqtt`: resend fan state when first publish fails | We use no `fan:` over MQTT in PROD. Generic MQTT path unchanged. |
| 10.1 | #21300 `esp32_hosted`: keep OTA watchdog timeout | Not used (no hosted coprocessor). |
| 10.1 | #21317 core: version-less library deps resolved like PlatformIO; #21627 precompiled header off with ccache < 4.7; #21307 lambda code emitted after user includes | Build-system. **Watch in the compile sweep** (library resolution, `includes/` with C++ headers). No config action. |
| 10.1 | #21358 `light` / #21359 `climate` StringRef overloads; #21625 / #21623 core float/Color fixes; #21397 `ledc`; #21457 `esp32_ble`; #21373 `http_request`; #21396, #21713 | Internal / not used. |

Net: **nothing in 10.1 / 10.2 changes the 10.0 plan** (ESP8266 native-toolchain bench test, Salon IR + media player checks, override-farm rebase, Pump pinned). Not touched by either patch: ESP8266 toolchain, `platformio_options`, wifi, api, remote_receiver, speaker, epaper_spi, preferences/NVS, prometheus, web_server, sensors, logger, time.

## Pre-Flight Checks

```bash
cd ~/dev/esphome_scripts
grep -rn "initial_state" --include='*.yaml' 2_PROD lights includes 0_DEV        # expect: none
grep -rn "buffer_size" --include='*.yaml' 2_PROD interfaces includes 0_DEV      # expect: none
grep -rn "codec_support_enabled" --include='*.yaml' .                           # expect: none
grep -rn "toolchain:\|platform_version\|source:" --include='*.yaml' 2_PROD includes | grep -v "^\S*:[0-9]*:\s*#"
grep -n "platformio_options" -A3 includes/board_esp8266.yaml                    # the deprecated build_flags
```

## Devices to Reflash

Order follows `feedback_flash_order_simple_first`: rigs first, simplest device within a chip family first, Office (most sensors) last.

| Priority | Device | Platform | Reason / what to verify |
|----------|--------|----------|--------------------------|
| 0 | **esp12f-29 rig** | ESP8266 | **Done 2026-11-07** — first native-toolchain build, no Rosetta needed. Gates all ESP8266 PROD. |
| 0 | **esp32-30 rig** | ESP32 (ESP-IDF) | **Done 2026-11-07** — `0_DEV/esp32_dev.yaml` (plain dev kit, no FRAM, status LED on GPIO4), host `esp32-30.nam`. Gates ESP32 PROD (does not cover S3/C3). |
| — | esp32-32 rig | ESP32-C3 + FRAM | Reserved for Pump / NVM tests only (not a general smoke-test rig); needs the override-farm rebase before any FRAM build. Not flashed. |
| 1 | esp12f-15 Upstairs | ESP8266 | **Done 2026-11-07.** |
| 2 | esp12f-25 AquariumWindow, esp12f-21 Underfloor, esp12f-11 Entrance_Entry | ESP8266 | **Done 2026-11-07** (all three). Doorbell input on esp12f-11 reports state 0; physical press not tested. |
| 3 | esp12f-10 Office | ESP8266 | **Pending (deferred by Pawelo 2026-11-07).** Most sensor-heavy, Prometheus `/metrics` heap sensitivity — last. This is the real test of the MMU build-flags question. |
| 4 | esp32-39 Attic, esp32-06 Garden_Gateway, esp32-05 Shades | ESP32 | mbedTLS trim; watch MQTT/OTA reconnect. **esp32-06: OTA 2026-11-07 fell back to 2026.8.2 silently, see KI-2 in `KNOWN_ISSUES.md` (sram1_as_iram vs bootloader hypothesis). Left on 2026.8.2, working. esp32-39, esp32-05 not attempted** (-05 probably the same). |
| 5 | esp32-36 Garage_Gate | ESP32-C3 (Arduino) | **Done 2026-11-07** (Arduino 3.3.12). First needed `sram1_as_iram` removed from `board_esp32_variant.yaml`, see KI-3. Heap free 168 963 → 169 444 B, max block unchanged 114 688 B. |
| 6 | esp32-14 Salon | ESP32-S3 | **Flashed 2026-11-07** (OTA 70 s; verified new image, no rollback; hash `0xe9f2082a`). Heap free 140 587 → 151 444 B, max block 131 070 → 139 264 B; RAM 39.6% / flash 33.7%. Temperature, illuminance and WiFi report; media player restores (IDLE, volume 0.5, not muted). **Still to verify by Pawelo on site (Nieporęt): IR remote codes arrive; volume slider + mute button in HA.** |
| — | **esp32-35 Pump_Garage** | ESP32 | **Stay on 2026.5.3** (override farm drift, FRAM not upstream). |

MQTT `esp` account migration (anonymous list from Larry, 2026-10-19) rides along with each flash per `feedback_mqtt_esp_creds_with_upgrade`: esp12f-10/11/15/21/25, esp32-05/06/14/32/36 (esp32-39 status unknown).

## Rollout results (2026-11-07, ESP8266)

Built on 2026.10.2 (native `arduino` toolchain; no Rosetta needed, which 2026.8.2 required). All OTA flashes succeeded first try. "Before" = Prometheus 2-day average (long uptime); "after" = `/metrics` ~30 s after boot, so the comparison favours "after" and is only a regression screen, not a leak test.

| Device | Heap free before → after | Max block before → after | RAM / Flash |
|--------|--------------------------|--------------------------|-------------|
| esp12f-29 rig (+BH1750 added) | 28 760 → 29 984 B (vs 2026.5.3, 1 sample) | 25 536 → 22 664 B | 50.9% / 55.7% |
| esp12f-15 Upstairs | 31 443 → 34 080 B | 26 734 → 29 808 B | 46.5% / 48.8% |
| esp12f-25 AquariumWindow | 30 442 → 32 448 B | 16 035 → 25 240 B | 46.7% / 52.2% |
| esp12f-21 Underfloor | 30 192 → 32 968 B | 25 759 → 29 144 B | 46.9% / 52.4% |
| esp12f-11 Entrance_Entry | 29 408 → 32 392 B | 24 483 → 28 632 B | 47.2% / 52.6% |

- esp12f-15 followed for ~2 h in Prometheus: heap free 34 016 → 33 496 B, max block 29 808 → 29 352 B (single 456 B step at the last sample; no trend visible). Recheck after a longer uptime.
- Compile warning seen before the migration: `esphome->platformio_options->build_flags is deprecated ... removed in 2026.12.0`. **Migrated 2026-11-07 (`1eca4b8`):** both flags now sit under `esphome: build_flags:` in `includes/board_esp8266.yaml`; the warning is gone and the MMU/VTABLES defines in `build.ninja` plus firmware sizes are identical (compile-checked on esp12f-29 and esp12f-15). Treated as a refactor, so no `version:` bump and no reflash needed; the already flashed ESP8266 devices carry the same binary content.
- Rig esp32-30 (ESP32, `esp32_dev.yaml`, ESP-IDF) flashed OTA on 2026.10.2 (38 s): RAM 28.9% / flash 59.5%, heap free ~219 kB, max block 110 592 B. No prior heap history exists (rigs are not scraped by Prometheus under `.nam` names), so no before/after comparison. Framework switch Arduino → ESP-IDF over OTA worked.
- Rig esp12f-29 was reached at `esp12f-29.nam` (Namysłowska). Prometheus showed `up=0` because it scrapes the bare name `esp12f-29:80`; esp32-32 was not checked under `.nam`.
- The MMU question is answered, see "MMU flag test" below. What stays open: whether the flag matters for Office's `/metrics` output.

### MMU flag test (esp12f-29 rig, 2026-11-07)

Question: does `-DPIO_FRAMEWORK_ARDUINO_MMU_CACHE16_IRAM32_SECHEAP_NOTSHARED` still do anything on the native toolchain, and are its values just the defaults?

- **It is honoured.** `esphome/build_gen/arduino8266.py` has an `_MMU_VARIANTS` table that translates the knob into `MMU_*` defines (a transliteration of `platformio-build.py`). `build.ninja` of esp12f-15 and esp12f-29 shows `MMU_ICACHE_SIZE=0x4000`, `MMU_IRAM_SIZE=0x8000`, `MMU_SEC_HEAP_SIZE=0x4000`, `MMU_SEC_HEAP=0x40108000`.
- **It is not the default.** Without the flag the generator uses `_MMU_DEFAULT`: `MMU_ICACHE_SIZE=0x8000`, `MMU_IRAM_SIZE=0x8000`, no secondary heap. So the flag trades 16 kB of cache for a 16 kB secondary (IRAM) heap.
- **`-DVTABLES_IN_FLASH` is redundant.** The generator falls back to `VTABLES_IN_FLASH` when no `VTABLES_IN_*` knob is given (`arduino8266.py:383`). Kept anyway; removing it changes nothing.
- **Measurement.** Same code built twice (flag removed temporarily, then restored), flashed OTA, sampled at +60/120/180 s after a fresh boot:

| | without flag | with flag |
|---|---|---|
| Heap free | 30 632 B | 30 632 B |
| Heap max block | 26 688 B | 26 688 B |
| RAM / flash | 41 704 B / 581 948 B | 41 704 B / 581 964 B |

- **Conclusion.** The flag changes the CPU memory map but not main-heap numbers; the extra pool is separate and only used when code selects it explicitly. The heap gains after the upgrade are therefore not caused by this flag. Whether it helps the original problem (`/metrics` truncated on a heap-starved device) cannot be shown on the rig: test on Office (esp12f-10) with the flag removed and `/metrics` size/completeness compared. Until then the flag is kept.


## Upgrade steps still ahead (SOP)

1. `pip install -U esphome` → `bash esphome-overrides/refresh.sh` (expect `⚠ CHANGED`, see above).
2. Update `COMPONENTS.md` (installed version, snapshot date, mention native ESP8266 toolchain).
3. Compile sweep: one ESP8266 PROD (`esp12f-10`), one ESP32 (`esp32-39`), ESP32-S3 (`esp32-14`), ESP32-C3 (`esp32-36`); then `find 0_DEV -name "*.yaml"` sweep.
4. Rig smoke tests → PROD flash in the order above.
