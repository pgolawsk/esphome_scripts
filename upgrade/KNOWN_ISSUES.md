# Known Issues — cross-version

Persistent log of ESPHome bugs/quirks that are **not tied to a single version** and that recur across upgrades. Unlike `ESPHOME_<version>.md` (which is per-release and gets pruned), this file is long-lived. Add an entry whenever a rig test or PROD flash surfaces a behavior that is upstream's fault (or a known limitation), so future upgrade cycles don't re-investigate it from scratch.

Each entry: symptom, where observed, root cause, whether it blocks, workaround, upstream links, status.

---

## KI-1 — web_server v3: debug sensors transiently duplicated / missing on page reload

- **Symptom:** On the device's own web_server (v3) UI, after a manual page reload, a debug sensor (e.g. `Heap Free`) disappears and another (e.g. `Loop Time`) appears duplicated. Left alone, the page self-refreshes after ~1 min and shows all sensors correctly with no duplication.
- **Where observed:** esp32-32 rig (ESP32-C3, ESP-IDF, web_server v3), during 2026.5.0 upgrade smoke test. Not version-specific — a pre-existing web_server v3 frontend bug.
- **Scope:** Device web_server UI only. Home Assistant and MQTT are unaffected. Purely cosmetic and self-correcting.
- **Root cause:** The web_server v3 frontend keys/sorts entities by `web_server_sorting_weight`, falling back to `name` when weights are equal/unset. While SSE state events stream in after a reload, entities with equal sort keys can momentarily collide — one entity renders in another's slot and a third drops, until the list reconciles on the next full event cycle. Aggravated by frequent `update_interval` (the rig runs `interfaces/debug.yaml` at `update_interval: 5s`); more frequent updates = wider collision window. The repo's `sensors/debug.yaml` is correct — no config fix required.
- **Blocks upgrade?** No. Cosmetic, transient, self-resolving.
- **Workaround (optional, only if it bothers):**
  - Give each debug sub-sensor (`free`/`block`/`loop_time`) a distinct `web_server_sorting_weight` so they never collide on the sort key (documented workaround for the upstream issues below), or
  - Increase the debug `update_interval` (5s on the rig is deliberately aggressive; PROD rarely runs debug continuously).
- **Upstream:** `esphome/esphome-webserver` #122, #125, #160 (#125 closed, #122/#160 open as of 2026-05).
- **Status:** Open upstream. Documented here; no repo change.

---

## KI-2 — esp32-06 (classic ESP32): OTA to 2026.10.2 reports success but the device silently boots the old image

- **Symptom:** `esphome upload` ends `OTA successful`; Loki shows `Update complete` → `Rebooting safely` → MQTT `Connected` → `safe_mode: Boot seems successful`. Afterwards `/metrics` still reports `2026.8.2 (config hash 0xdb387cc3, built 2026-09-20)` — the pre-OTA image. The new image (`firmware.ota.bin`, 2026.10.2) was uploaded correctly. Nothing about the failed boot reaches MQTT/Loki (early crash, before logging).
- **Where observed:** `esp32-06_Garden_Gateway` (bare WROOM-32, no USB port), 2026-11-07, first OTA with the repo's `includes/board_esp32.yaml` carrying `sram1_as_iram: true` (added 2026-10-04, `33c88f1`). Same signature as `esp32-39_Attic` in 2026.8.2 (two OTAs "silently fell back").
- **Probable cause (hypothesis, NOT verified):** `sram1_as_iram: true` on a device whose bootloader was written (USB, 2026-09-20, 2026.8.2 build) before the option existed. ESPHome's `application.cpp` warns that enabling it with an old bootloader hard-bricks the device; here the rollback-capable bootloader reverted to the previous image instead. Counter-point: that bootloader is IDF >= 5.2, so it should count as "modern" — which is why this is only a hypothesis. `esp32-39` (fresh USB flash on 2026-10-04 *with* the option) is the only classic-ESP32 PROD known to carry a bootloader built with it.
- **Likely also affects:** `esp32-05` (bootloader refreshed over OTA 2026-09-20, also before the option). Unverified. `esp32-35` Pump is pinned on 2026.5.3 and its board file does not set the option.
- **Blocks upgrade?** For esp32-06 (and probably -05): yes, until resolved. The device is safe — it keeps running 2026.8.2.
- **Test (cheap, rollback protects it):** build esp32-06 with `sram1_as_iram: false` and OTA it. Needs a per-device switch in `includes/board_esp32.yaml` (e.g. `sram1_as_iram: ${sram1_as_iram | default(true)}`). If it boots 2026.10.2, the hypothesis holds.
- **Fallback:** full USB flash (CH340 adapter, as on 2026-09-20) with the option on, which writes a bootloader built with it.
- **Status:** Open. Pawelo is thinking it over (2026-11-07); no repo change made.

---

## KI-3 — `sram1_as_iram` in `includes/board_esp32_variant.yaml` broke every C3/S2/C6 config on 2026.10.2

- **Symptom:** `esphome config|compile` fails: `'sram1_as_iram' is only supported on ESP32.` for `esp32-36_Garage_Gate` (C3), `esp32c3_dev`, `esp32s2_dev`, `esp32c6_dev`.
- **Root cause:** the option was added to the variant board file on 2026-10-04 (`33c88f1`) but ESPHome only accepts it on the classic ESP32.
- **Fix:** removed from `includes/board_esp32_variant.yaml` (`9c8cf5b`); it stays in `board_esp32.yaml`. Verified by compiling and flashing esp32-36.
- **Status:** Resolved 2026-11-07. `esp32s2_dev.yaml` / `esp32c6_dev.yaml` not re-compiled afterwards.
