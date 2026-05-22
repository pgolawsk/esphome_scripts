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
