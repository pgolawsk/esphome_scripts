# ESPHome 2026.11.0 — Upgrade Impact for esphome_scripts

Covers changes from the installed version (**2026.10.2**) to **2026.11.0** (released 2026-11-18).
Use this file as a checklist when updating configs and reflashing devices.

> **Installed version:** 2026.10.2 (in `.venv`). **2026.11.0 not installed yet** — analysis only (2026-11-21), no compile or flash done. Pawelo decides on the upgrade.
> **Sources:** [changelog 2026.11.0](https://esphome.io/changelog/2026.11.0.html), [release blog](https://esphome.io/blog/2026/11/18/esphome-2026-11/).
> **Verification level:** the repo side is grep-verified. The ESPHome side was read through a web-fetch agent and is **partial**: the blog's "Breaking Changes" YAML section was not read, ~300 "All changes" entries were only partly read, and items tagged *[summary]* come from a model-extracted summary, not verbatim page text. Components with **no** changelog entry found in the read parts: `sht3xd`, `bh1750`, `scd4x`, `tcs34725`, `safe_mode`, `psram`. Absence of an entry is not proof of no change. Re-read the live pages before relying on exact wording or PR numbers.
> **Source conflict:** `esp32_hosted` moves to esp_hosted 3.0.10 (changelog, #21394) or 3.1.0 (blog). Irrelevant here (no `esp32_hosted` in repo).

---

## Breaking Changes

Verified against the actual repo (grep), not assumed.

| Change | Affects | Action required |
|--------|---------|----------------|
| **`remote_base`: NEC `command_repeats` now sends real repeat frames; `transmit_nec` accepts only 1–10 (0 and >10 rejected); `on_nec` always reports `command_repeats=1`** (#17663) | `buttons/rc_nec_button.yaml` (`remote_transmitter.transmit_nec`, `command_repeats: 1`) → Salon, Garage_Gate IR remotes. `command_repeats=1` strings in `buttons/set_*_ir_remote_rest.yaml` are comments only (IR dumps). | **No YAML change needed** (value 1 is valid). Behavior note: a frame with `command_repeats: 1` is now a real single send, check on site that TV/AV/Input remote buttons still act once (no double-trigger, no missed command). No `on_nec` lambda compares `command_repeats` (grep). |
| **`esp32_rmt`: RMT channel fit and sizes validated at config time** (#22172) | `esp32-14_Salon` (`remote_receiver` with `rmt_symbols: 64` + `remote_transmitter` + RGB light, ESP32-S3); `esp32-36_Garage_Gate` (IR includes commented out) | Run `esphome config` on Salon **first**. A conflict that used to build silently now fails at config time. |
| **`web_server`: `allowed_origins` option; applies to web OTA `/update`, index page, `/events` (ESP32), Prometheus `/metrics` for requests from a browser page on another site** | `includes/web_server.yaml` (v3) on all ESP32 boards; `includes/web_server_basic.yaml`; ESP8266 Prometheus (`includes/prometheus.yaml`, Office/Upstairs/Underfloor/Entrance/AquariumWindow) | **Likely no action.** Prometheus scrapes server-side (no `Origin` header, unaffected per blog). Needs `allowed_origins` only if a self-hosted HTML dashboard on another host reads `/events`, `/update` or `/metrics` from the browser. Pawelo to confirm there is none. |
| **`web_server`: numbers without state report `"state":"NA","value":"NaN"` instead of `0`** (#20973) | All devices with web_server, REST/JSON consumers | Check if anything parses the web_server JSON/REST value as a number (HA uses the API, not this). |
| **`web_server`: internal entities matched by URL only with `include_internal: true`** (#20883) | `includes/web_server.yaml` already sets `include_internal: true`. `web_server_basic.yaml`: **not verified** whether it sets it (see Pre-Flight). | **No action** for v3 files. Check `web_server_basic.yaml` only if its users rely on REST by URL for internal entities. |
| **`mqtt`: messages above 8 KB (ESP8266), 16 KB (LibreTiny), 32 KB (ESP32) dropped with a warning; new `max_payload_size`** | All devices (MQTT everywhere) | Low risk: repo payloads are short sensor values and small JSON. Watch for the drop warning in logs after flash. |
| **`mqtt`: `on_json_message` rejects deferring actions (`delay`, `wait_until`, `script.wait`)** (#20538) | **Not applicable** — not used (grep). |
| **`esphome: devices:` entries need `relation: via\|child`** (#21232) | **Not applicable** — repo's `devices:` is a substitution (free-text note), not the sub-devices block (grep: no `relation:`, no `esphome: devices:` list). |
| **ESP32: ESP-IDF minimum 5.1** (#21398) | All ESP32 | **No action.** Framework is `recommended` everywhere (`includes/board_esp32.yaml:64`, Jinja default); no pin to 5.0.x. |
| **`network`: `enable_ipv4` / `enable_ipv6` resolve from component needs** (#14526) | All | No action; IPv4 stays on unless OpenThread is used. Not used. |
| **`ethernet clk_mode` removed; `http_request` non-blocking in scripts; `lvgl update_on_release`; `nextion dump_device_info`; `dlms_meter`; `canbus`; `emontx`; `haier`; `hlw8012`/BK72xx inversion; `CB3S D12`; `deep_sleep wakeup_pin` on H2; `qspi_amoled`; Panasonic/MagiQuest IR; `color_bwr` e-paper mapping; `esp32_hosted`; OpenThread** | — | **Not applicable** — none used (grep), except the two below. |
| **`epaper_spi`: `color_bwr` models (WeAct 3C, Waveshare B/BWR, Inkplate 2) change color mapping; WeAct 3C and Waveshare 7.5" V2 BWR report `DISPLAY_TYPE_COLOR`** | `esp32-05_Shades_WinterGardenUpp`, `esp32-35_Pump_Garage` (model `weact-2.9in-3c`) | **Verify on the panel after flash**: colors (black/white/red) render as before. The blog lists "WeAct 3C" in the affected set; exact YAML-visible impact not read. esp32-35 is pinned on 2026.5.3, so only esp32-05 is in scope. |
| **`deep_sleep`: `wakeup_pin` only on certain ESP32 variants; `touch_wakeup` ESP32/S2/S3/P4** | — | **Not applicable** — `deep_sleep` appears only in a commented-out block in `includes/mqtt_on_message/log_level_set.yaml`. |
| **`display`: `on_page_change` trigger removed; `remote_transmitter` per-protocol action classes removed; `OneWireDevice::get_address_name()` removed** (code-level C++ API) | `lambda`s in repo | **No action expected** — repo has no custom C++ components using these (confirm by compile sweep). |

### Code-level API changes *[summary]*

"Undocumented API changes" in the blog (entity names/strings moved to flash, `uart.write` using `ApplyBytes`, UART switch/button payload setters taking pointer+length, `ProgmemStringRef` on ESP8266, `get_log_name()`) were not read. They matter only for custom C++ and for `lambda`s that touch component internals. **`esphome compile`, not `config`, is the detector** — see Pre-Flight.

### Override farm (`esphome-overrides/`, PR#14119 NVM/FRAM) — no change in decision

Only `esp32-35_Pump_Garage` and the FRAM rig `esp32-31` depend on the farm. **2026.11.0 does not add FRAM/NVM.** The release adds *preferences* work (`switch initial_state/restore_state` with flash or RTC storage #20978, `globals` RTC memory #13954, LibreTiny RTC preferences #21007), which touches `preferences` code and will widen the drift of the already-stale `.preferences.h.upstream` snapshots. **Keep esp32-35 on 2026.5.3** (see `project_pump_pinned_2026_5_3`). Before any `refresh.sh`: diff snapshots vs pip, per `feedback_refresh_sh_check_snapshots`.

---

## New Features Worth Exploring

| Feature | Rating | Why |
|---------|--------|-----|
| **OTA: UDP data-phase fallback on lossy links** (#20498); companion-client handshake timeouts 20 → 60 s, more attempts *[summary]* | ★★★ | Closest to the esp32-06 OTA-fallback problem (KI-2) and weak-WiFi devices (Pump, Attic). Not a verified fix for KI-2's `sram1_as_iram`/bootloader hypothesis, **do not count on it**. |
| **ESP8266 RAM diet** (entity names and strings in flash, switch lookup tables out of RAM #20398, ArduinoJson tables) *[summary]* | ★★★ | Office with Prometheus `/metrics` is heap-sensitive; compare free heap before/after on esp12f-29 and Office. |
| **`one_wire`/`ds18b20`: no more random watchdog resets on ESP8266** *[summary]* | ★★ | Underfloor (ESP8266 with DS18B20). Verify claim in changelog before quoting. |
| **MQTT: connects as soon as network is up; retained messages no longer lost on connect (ESP32)** *[summary]* | ★★ | Relevant to retained state topics at boot. |
| **WiFi: DHCP lease cache** (#17767), retries no longer wait 31 s with fixed `bssid:`/`channel:` missing from scan, device leaves WiFi before ESP32 reboot *[summary]* | ★★ | Faster boot-to-connected, fewer reconnect stalls. |
| **`logger`: boot log buffer replayed to log listeners** (`boot_log_buffer_size:`, `boot_log_level:`, `boot_logs:`, action `logger.replay_boot_logs:`) (#17666) | ★★★ | Captures pre-network log lines of the **current boot** (WARN+ by default) so they reach Loki. See "Experiment: boot log buffer → Loki" below. Opt-in, recommended to try on rigs after the upgrade. |
| **API: entities no longer stay unavailable in HA after restart/update** *[summary]* | ★★ | Matches the periodic `sensor.pump_water_total_all` unavailable warnings in the 24h log digest (may be related, unverified). |
| **`text_sensor` filters `throttle`, `throttle_with_priority`, `timeout`** (#21669); **`binary_sensor: uart`** (fires on a byte sequence, #14032) | ★ | Possible use in the Haba RS485 sniffer (esp32-32). |
| **`sun`: `next_sunrise`/`next_sunset` correct for far east/west** *[summary]* | ★ | `includes/sun.yaml`, `sensors/text_sun_*`; irrelevant at current location. |
| **`prometheus` datetime metrics** (#9941) | ★ | Not needed now. |
| **`i2s_audio` full duplex, `speaker` announcement volume, `media_player` constant bitrate** (#19959, #21002, #19962) | ★ | Salon media player; no action. |
| **`sht4x` serial number text sensor** (#22176) | — | SHT4x not used. |
| **ESP32 OpenThread border router, Zigbee sleepy end device, ULP, modem, `esp32_hosted`** | — | Not relevant. |
| **FRAM / NVM component** | — | **Not in this release.** |

## Experiment: boot log buffer → Loki (recommended, decided 2026-11-21)

Source: [PR #17666](https://github.com/esphome/esphome/pull/17666) (read verbatim) and `mqtt_client.cpp` at tag `2026.11.0`.

**Mechanism.** `boot_log_buffer_size` reserves a compile-time-sized RAM buffer (no heap) that records lines from logger start (level `boot_log_level`, WARN by default; per tag via `boot_logs`). `logger.replay_boot_logs:` sends the stored lines to the log listeners with an `@<ms>` prefix (time since boot). Capture stops at the first replay; lines that did not fit are counted in a warning. Unset = build identical to before in flash and RAM.

**Why it is not just a switch.** The PR example triggers the replay from `api: on_client_connected`, i.e. when HA connects. This repo ships logs to Loki over **MQTT** (default `log_topic`, picked up by `mqtt_logger`). `mqtt_client.cpp` registers its own logger callback (`add_log_callback`, line 147), so replay called from `mqtt: on_connect:` should reach the MQTT log topic. **Unverified**: the PR tested the API path only. Test on a rig.

**Limits.**
- RAM only, lost on reboot: you get pre-WiFi lines of the *current* boot, not of the previous crashed one. A reboot loop that dies before MQTT yields nothing. The previous crash is covered by the separate "crash info over MQTT" feature (#17935, not reviewed).
- Fixed RAM cost (buffer size). On ESP8266 (Office + Prometheus) compare free heap before/after.
- Replay once per boot.

**Result (2026-11-21, esp12f-29): works, with a delay.** Replay in `mqtt: on_connect:` without delay publishes nothing; with `- delay: 3s` first, 12 pre-WiFi lines (`@8742ms` … `@12638ms`) reach Loki. Cost +2 044 B RAM (Office simulation: eats the whole 11.0 RAM saving). Numbers and details in `MEMORY_LOG.md`. The plan below is superseded by that result; remaining decision is the buffer size and which boards get it.

**Made permanent in the shared includes (2026-11-21).** `includes/logger.yaml` now sets `boot_log_buffer_size: ${boot_buffer | default("2kB")}` and `boot_log_level: INFO`; `includes/mqtt.yaml` and `includes/mqtt_with_rtttl.yaml` run `delay: 3s`, the `uptime_ms` marker and `logger.replay_boot_logs:` in `on_connect`. Applies to every device that uses these includes (all PROD except Pump, which is on a pinned 5.3 checkout where neither option exists; compiling `2_PROD/esp32-35_Pump_Garage.yaml` from THIS repo on 5.3 would now fail with a schema error). These includes now require ESPHome 2026.11.0+ (the `min_version` default in the board files is still 2026.4.0, so an older ESPHome fails with a schema error, not a min_version message; raise the floor when 11.0 is rolled out everywhere). Also compiled OK: Entrance_Entry, Underfloor, AquariumWindow, esp32-05, esp32-06, `0_DEV/esp32c6_dev`, `esp32s3_dev`, `miniss_dev` (BK7231N). Compile OK on Office, Upstairs, Attic, Salon, Garage_Gate (rows in `MEMORY_LOG.md`). **Office is not flashed yet (done on site at Nieporęt): when flashing, first set `boot_buffer: "1kB"` for Office (logger include override with `vars`), check `lines dropped` in the replay header, that the device stays stable and that Prometheus `/metrics` is not truncated, and only then decide on 2 kB.** The decision to use 2 kB on ESP8266 rigs first, 1 kB on Office, is Pawelo's (2026-11-21). Bump `version:` of each device at its flash (functional change).

### How to read a replayed boot block (Loki)

Example from esp12f-29, 2026-11-21: `Replaying boot logs (666 bytes used, 0 lines dropped)` followed by lines like `@8809ms [I][wifi:1309]: Connecting to …`.

- **`@<ms>` = device uptime (millis) when the line was logged.** Nothing to add to the Loki time; read it as a boot timeline.
- **Loki timestamps of replayed lines are meaningless.** All get the replay time (publish moment). Only `@ms` gives real order and spacing.
- **Durations = differences of `@ms`.** Example: `setup()` 8747 → 8826 = 79 ms; WiFi 8809 → 12638 = 3.8 s; MQTT connected `@12721`.
- **Wall-clock boot time:** pick a line that also exists live (without `@`), e.g. `mqtt Connected` live at 18:42:51.317 and replayed as `@12721ms`: boot start = 18:42:51.317 − 12.721 s ≈ 18:42:38.6 (matched `Rebooting safely` at 18:42:38.466).
- **Duplicates are normal.** The buffer records until the replay (3 s after connect), so lines already published live (`mqtt Connecting/Connected`) appear twice.
- **`N lines dropped` > 0 = buffer too small.** Capture keeps the earliest lines and drops the later ones (logger.cpp: a record that does not fit is counted, not stored).
- **First `@ms` was 8742 on the first boot after OTA** (logger initialised 8.7 s after reset): probably the bootloader copying the new image; unverified, check on the next plain reboot.
- **Level label (fixed 2026-11-21):** Larry updated the `mqtt_logger` regex on `ppi41` to accept the `@<ms>ms ` prefix; replayed lines now carry `level=info` in Loki (blocks from before the fix, e.g. 19:04, stay without a level).
- **Uptime marker (esp12f-29 rig, 2026-11-21):** `mqtt: on_connect:` runs `delay: 3s`, then `lambda: ESP_LOGI("boot_replay", "uptime_ms=%u", (unsigned) millis());`, then `logger.replay_boot_logs:`. The marker is published live right before the replay (and is also captured in the buffer as `@<N>ms`). It lets a log pipeline put replayed lines on the real timeline: `boot_start = receive_time(marker) − uptime_ms`, line time = `boot_start + @ms`. Checked on the rig: marker at 19:04:23.608 with `uptime_ms=15779` gives boot start 19:04:07.829, the previous `Rebooting safely` was at 19:04:07.696. The pipeline side (`mqtt_logger` on `ppi41`, outside this repo) was done by Larry on 2026-11-21: verified on the rig, the 19:47 block has marker `uptime_ms=6284` at 19:47:39.556, `@80ms Log initialized` at 19:47:33.352 and `@3189ms wifi Connected` at 19:47:36.461, i.e. replayed lines sit on the real timeline and Loki order equals event order. The 19:40 block (just before the fix) still has replay-time stamps. The `Replaying boot logs (N bytes …)` header has no `@ms` and keeps the replay time; the marker appears twice (live, and as a buffered copy with `@ms`). Buffer use on the rig: 719 B of 2 kB, 0 lines dropped. Marker cost: +12 B RAM, +92 B flash vs the 3 s delay build (RAM 41 356 B, flash 585 704 B).
- Queries: only replayed lines `{mqtt_node="esp12f-29"} |~ "@\\d+ms"`; with the value extracted `… | regexp "@(?P<ms>\\d+)ms"`.

**Test plan (after upgrade, rigs first) — original plan.**
1. esp12f-29 (ESP8266) and esp32-30 (ESP32): in `includes/logger.yaml` add `boot_log_buffer_size: 2kB` (temporary, per rig or via vars) and `logger.replay_boot_logs:` in `mqtt: on_connect:`. Compile.
2. Reboot the rig; check Loki (`{mqtt_node="esp12f-29"}`) for lines with `@<ms>` stamps and for warnings logged before WiFi.
3. Compare free heap vs 2026.10.2 (ESP8266 especially).
4. If it works and heap allows: roll into the shared include for all boards (`includes/logger.yaml` is shared, so this is a multi-file change: `esphome compile` per family + ECHO). Pump (esp32-35, pinned 2026.5.3) is not in scope until it leaves 2026.5.3.

## Deprecations

- `ili9xxx`, `qspi_dbi`, `st7735`, `st7789v`, `rpi_dpi_rgb` scheduled for removal in **2027.5.0** *[summary]* — **not used** (grep: only `epaper_spi` displays in PROD).
- `esp32_hosted` `active_high: false` — not used.
- Still open from 2026.10: `esphome: platformio_options: build_flags` removed in **2026.12.0** — see `includes/board_esp8266.yaml:36-44` and `ESPHOME_2026.10.0.md`. **This is the next real deadline** (next release), independent of 2026.11.

---

## Pre-Flight Checks

```bash
cd ~/dev/esphome_scripts
grep -rn "allowed_origins" --include='*.yaml' .                                   # expect: none (not set anywhere today)
grep -n "include_internal" includes/web_server.yaml includes/web_server_basic.yaml  # basic: check if present
grep -rn "command_repeats" --include='*.yaml' 2_PROD buttons interfaces lights      # expect: only value 1 + IR-dump comments
grep -rn "on_json_message\|http_request\|clk_mode\|relation:" --include='*.yaml' 2_PROD includes   # expect: none
grep -rn "rmt_symbols" --include='*.yaml' 2_PROD interfaces includes               # Salon only
grep -n "platformio_options" -A3 includes/board_esp8266.yaml                       # deadline 2026.12.0
```

Compile sweep (per `Validation rigor` in `AGENTS.md`, `config` alone is **not** enough given the C++ API changes): `esphome config` on **Salon first** (RMT fit check), then `esphome compile` on one representative per family (ESP8266 `esp12f-29`, ESP32 `esp32-30`, ESP32-S3 Salon, ESP32-C3 Garage_Gate), then the `0_DEV` bulk sweep from `esp_upgrade.sh`.

## Devices to Reflash

Order follows `feedback_flash_order_simple_first` and `feedback_smoke_test_rigs_before_prod`: rigs first, simplest device within a chip family first, Office last. Expect most ESP8266 devices to need no on-site check beyond heap and boot.

| Priority | Device | Platform | Reason / what to verify |
|----------|--------|----------|--------------------------|
| 0 | esp12f-29 rig | ESP8266 | Gates all ESP8266 PROD. Compare free heap vs 2026.10.2 (RAM diet). |
| 0 | esp32-30 rig | ESP32 (ESP-IDF) | Gates ESP32 PROD (not S3/C3). |
| — | esp32-31 rig | ESP32-C3 + FRAM | Pump/NVM only; stays on 2026.5.3. |
| — | esp32-32 rig | ESP32-C3 + RS485 (Haba) | Experiments only, **do not reflash while Haba data collection runs** (S→o cycle observation, see `project_haba_sniffer_data_collection`). |
| 1 | esp12f-15 Upstairs | ESP8266 | Simplest first. |
| 2 | esp12f-25 AquariumWindow, esp12f-21 Underfloor, esp12f-11 Entrance_Entry | ESP8266 | Underfloor: DS18B20 stability. Entrance_Entry: doorbell input (still unchecked physically). |
| 3 | esp12f-10 Office | ESP8266 | Most sensor-heavy, Prometheus heap — last. |
| 4 | esp32-39 Attic, esp32-05 Shades | ESP32 | **esp32-05: verify ePaper colors (`color_bwr` mapping).** esp32-06 OTA fallback (KI-2) unresolved: do not retry OTA without Pawelo's decision. |
| 5 | esp32-36 Garage_Gate | ESP32-C3 (Arduino) | RMT validation (IR includes commented out, expected clean). |
| 6 | esp32-14 Salon | ESP32-S3 | **On site (Nieporęt):** IR remotes (NEC repeat semantics), volume/mute (still pending from 2026.10), RMT config passes. |
| — | esp32-35 Pump_Garage | ESP32 | **Stay on 2026.5.3.** |

MQTT `esp` account migration rides along with each flash per `feedback_mqtt_esp_creds_with_upgrade`.

## Upgrade steps still ahead (SOP)

Follow `upgrade/SOP_upgrade.md`; this file is the impact analysis only. Open items before starting:

1. Pawelo's go/no-go on upgrading to 2026.11.0 (no urgency: no security or must-have fix identified; 2026.12.0 deadline for `platformio_options: build_flags` can also be handled independently).
2. Re-read the blog "Breaking Changes" section and the unread parts of the changelog to close the coverage gaps listed at the top.
3. `./check_esphome_version.sh --auto` (or manual `pip install`), then Pre-Flight + compile sweep.
4. Check 2026.11.x patch releases before rollout; per `feedback_patch_release_sop`, update this file with dates instead of creating a new one for x.y.0 → x.y.z.
5. Update `upgrade/COMPONENTS.md` after the upgrade.
