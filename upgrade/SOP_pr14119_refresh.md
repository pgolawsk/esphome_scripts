# SOP: Refresh PR#14119 + `local/preferences-virtual` on new ESPHome

Operational runbook for keeping the NVM / FRAM I2C component (PR#14119) and
its local NVS-delegation production variant in sync with new ESPHome stable
releases. **Run at least monthly, or whenever a new ESPHome stable lands.**

---

## What we maintain

| Branch (in `~/dev/esphome`) | Pushed to origin | Role |
|---|---|---|
| `pr/nvm-base` | yes | Public **PR#14119** — vanilla-compatible (no core ESPHome patch). Merge target for upstream. |
| `local/preferences-virtual` | yes (private use) | Production deployment — depends on the override headers in `~/dev/esphome_scripts/esphome-overrides/`. Restores `class PreferencesPartition : public ESP32Preferences` + NVS delegation for `safe_mode::RTC_KEY`. |

Override files (in `~/dev/esphome_scripts/esphome-overrides/`):
- `esphome/components/esp32/preferences.h` — un-final + virtual `make_preference`/`sync`/`reset`
- `esphome/components/esp32/preference_backend.h` — un-final + virtual `save`/`load`
- `refresh.sh` — symlinks every other esp32 component file to the pip-installed copy
- `.gitignore` — only the patched `.h` files + `refresh.sh` are version-controlled

The override is active because YAML's `external_components:` lists `[esp32]` with
`source: ../esphome-overrides/esphome/components`. ESPHome's `ComponentMetaFinder`
inserts at `sys.meta_path[0]`, so this overrides the pip-installed `esp32` for
the build.

---

## Golden rule for `pr/nvm-base`

**Never commit experimental work directly on `pr/nvm-base`.** It tracks a
public PR — its history must stay clean for review. Pattern:

1. Create a throw-away work branch from `pr/nvm-base`:
   ```bash
   git checkout -B wip/pr-refresh-<YYYY-MM-DD> pr/nvm-base
   ```
2. Iterate freely on `wip/pr-refresh-*`: rebase on the new ESPHome tag, fix
   compile errors, flash-test on `esp32-32`, repeat until green.
3. When verified, prepare clean commits (squash WIPs, write proper messages).
4. Cherry-pick *only* the clean commits onto `pr/nvm-base`.
5. Force-push `pr/nvm-base` (after `--force-with-lease` and **explicit user OK**
   if you're an agent — force-push is destructive on the public PR).
6. Delete the work branch.

`local/preferences-virtual` is private — direct work is acceptable, but still
worth using a `wip/local-refresh-*` branch if iterations get messy.

---

## Phase 0 — Pre-flight checks

```bash
cd ~/dev/esphome
git status              # clean working tree on both repos
git branch --show-current   # note current branch
cd ~/dev/esphome_scripts
git status              # clean
.venv/bin/esphome version   # note OLD version
```

Ping test device:
```bash
ping -c 2 esp32-32.lan  # MUST be reachable for OTA verify
```

If anything is dirty — commit, stash, or abort. Don't start a refresh on a
messy state.

---

## Phase 1 — Upgrade pip ESPHome

```bash
cd ~/dev/esphome_scripts
.venv/bin/pip install --upgrade esphome
.venv/bin/esphome version    # confirm NEW version
```

If pip fails on broken venv (Python interpreter mismatch — happened once when
homebrew rolled `python@3.14`): rebuild the `~/dev/esphome/.venv` using the
current `python3.14`:
```bash
cd ~/dev/esphome
rm -rf .venv && /opt/homebrew/bin/python3.14 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt -r requirements_dev.txt -r requirements_test.txt
```
(Only matters when running pre-commit hooks — they use that venv.)

---

## Phase 2 — Refresh override symlinks + drift check

```bash
cd ~/dev/esphome_scripts
./esphome-overrides/refresh.sh
```

The script:
- Recreates symlinks pointing to the new pip-installed `esp32` component
- Compares the *upstream* `preferences.h` / `preference_backend.h` against the
  cached `.preferences.h.upstream` / `.preference_backend.h.upstream` snapshots
- Prints `⚠ upstream <file> CHANGED since last refresh` with a diff if drifted

**If drift is reported**: manually merge the upstream changes into
`esphome-overrides/esphome/components/esp32/<file>` while preserving the
patch (un-final + virtual). Compare against `.<file>.upstream` (now refreshed
to the current pip copy).

Common drift patterns:
- Methods renamed → keep them virtual in our patched header
- New methods added → add them virtual in our header (otherwise our derived
  `PreferencesPartition` won't compile if it tries to override them)
- Members added → mirror them in our patched header

After resolving drift, re-run `./esphome-overrides/refresh.sh` — drift warning
should be gone.

---

## Phase 3 — Refresh `pr/nvm-base`

### 3a. Set up work branch

```bash
cd ~/dev/esphome
git fetch upstream --tags    # (origin = pgolawsk/esphome, upstream = esphome/esphome)
git tag | grep "<NEW.VERSION>"   # confirm tag exists, e.g. 2026.5.0

git checkout -B wip/pr-refresh-<YYYY-MM-DD> pr/nvm-base
git rebase <NEW.VERSION>     # e.g. 2026.5.0 (no v prefix in this repo's tags)
```

If rebase conflicts arise — most often in `nvm.cpp` near `App.register_component`
or in `__init__.py` schema validation — resolve based on:
- Issue A history (cv.use_id → cv.declare_id): keep `cv.declare_id`
- Issue B history (App.register_component): `register_component_` is protected,
  so drive `PreferencesPartition::setup()` from `NvmPlatform::setup()` instead

### 3b. Compile + flash test on esp32-32

The test config `0_DEV/esp32c3_dev.yaml` includes
`tests/test_nvm_fram_i2c.yaml` which already wires `external_components` to
both the override (`[esp32]`) and the local clone (`[nvm, fram_i2c]`).

```bash
cd ~/dev/esphome_scripts
esphome -s devicename esp32-32 -s updates 15s -s room Test32c3rgb \
  -s mqtt_location measures -s mqtt_room test32c3rgb \
  compile 0_DEV/esp32c3_dev.yaml
```

Iterate fixes on `wip/pr-refresh-*` until compile is green. Common breakage on
new ESPHome versions:
- `cv.declare_id` semantics tighten
- `Component` API shifts (e.g., `register_component_` access)
- Preferences API shifts → both override and PR architecture must stay
  consistent (the PR uses `NvmPreferenceObject` standalone — no inheritance —
  so it's resilient)

#### Pre-flight clang-tidy mental check

Local `esphome compile` does NOT run clang-tidy — but the upstream PR's CI
does, with `-warnings-as-errors`. Two recurring offenders bite every refresh
that touches the headers:

1. **`modernize-concat-nested-namespaces`** — every `.h`/`.cpp` must use
   `namespace esphome::nvm { ... }` (flat C++17 form), NOT
   `namespace esphome { namespace nvm { ... } }`. Closing comment is
   `}  // namespace esphome::nvm`.
2. **`bugprone-crtp-constructor-accessibility`** — any
   `template<typename Derived> class Mixin { ... };` must have a non-public
   default ctor + `friend Derived;`.

Eyeball any `.h` you touched against these two before committing. See
`memory/reference_esphome_pr_conventions.md` for the full rules and rationale.

Flash + boot verify:
```bash
ping -c 2 esp32-32.lan
esphome -s devicename esp32-32 -s updates 15s -s room Test32c3rgb \
  -s mqtt_location measures -s mqtt_room test32c3rgb \
  run 0_DEV/esp32c3_dev.yaml --device esp32-32.lan
```

Verify in the OTA log:
- `OTA successful`
- No `Guru Meditation` / `panic` / `abort` / `esp_image` errors
- `[I][safe_mode:091]: Boot seems successful; resetting boot loop counter` ~54s
  after boot — confirms safe_mode boot counter still works
- All FRAM partitions still report values (Pref Test Value, Raw Counter, KV
  Device Name etc.)

#### Verification realities — what the logs actually show

- **`esphome logs` over MQTT misses early boot.** It connects to a running
  device, so it typically does NOT capture the `safe_mode:091` reset marker.
  If you don't see it, that alone is not a failure — see other signals below.
- **Boot Count / Test Value do NOT change on their own.** Those text_sensors
  reflect partition contents and only update when the user **clicks the
  test rig button** to write a new value. If a value is stable across boots,
  that's correct (FRAM persistence). If a value matches the last manual click
  before reboot, partition reads are working.
- **Fastest signal: the on-board RGB LED.**
  - 🟢 **green** = preferences came up on **FRAM** (NVM partition active)
  - 🟠 **orange** = preferences came up on **NVS** (flash fallback)
  Glance at the LED right after the device joins WiFi to know which backend
  is active without parsing logs.
- **Stability proof if you can't see safe_mode:091:** 60s+ of continuous
  sensor updates over MQTT after flash, with no `Guru Meditation`/`panic`/
  `abort` in the captured log window, is strong evidence of a clean boot.

**Design note — `pr/nvm-base` does NOT replace `global_preferences`.**

This is intentional and keeps the PR vanilla-compatible (no patches to core
`esp32/preferences.h`). Consequences when testing against this branch:

- `restore_value: yes` on globals/numbers/sensors continues to use **NVS
  (flash)**. It is *not* automatically redirected to NVM/FRAM.
- To persist arbitrary state in NVM/FRAM, user code accesses the partition
  explicitly — typically from a lambda:
  ```yaml
  - lambda: |-
      auto pref = id(pref_store)->make_preference<float>(0xCAFEBABE);
      pref.save(&value);
  ```
- The "auto-install as `global_preferences`" behavior lives only on
  `local/preferences-virtual` (it requires un-`final`-ing `ESP32Preferences`
  + adding virtuals via the override headers).

When testing `0_DEV/esp32c3_dev.yaml` on `pr/nvm-base`, expect FRAM partitions
to report values only when accessed via `id(...)`, not via the global
preferences pool.

### 3c. Land clean commits on `pr/nvm-base`

Once `wip/pr-refresh-*` is green, prepare clean commits:

```bash
# Optional: squash messy iterations into logical commits
git rebase -i pr/nvm-base   # (only on wip/, never on pr/nvm-base)
```

Cherry-pick onto pr/nvm-base:
```bash
git checkout pr/nvm-base
git rebase <NEW.VERSION>    # if pr/nvm-base also needs the new tag base
# ...resolve any conflicts using the same logic as on wip/

# Or, if rebasing pr/nvm-base directly causes too much pain,
# manually apply the verified diffs by:
git diff <OLD.VERSION>..wip/pr-refresh-* -- esphome/components/nvm/ | git apply
git add esphome/components/nvm/...
git commit -m "fix: <description>"
```

Force-push:
```bash
# REQUIRES EXPLICIT USER CONSENT — do not auto-execute as agent
git push --force-with-lease origin pr/nvm-base
```

Verify on GitHub:
```bash
gh pr view 14119 --json headRefOid,state    # headRefOid must match local pr/nvm-base
```

Delete work branch:
```bash
git branch -D wip/pr-refresh-<YYYY-MM-DD>
```

#### PR title format — `Validate PR title` workflow

Upstream CI enforces a strict bracket-tag prefix. If `Validate PR title`
shows up red on the rollup, the title (not the diff) is the issue.

- **Format:** `[component][component2] Brief description` — separate
  brackets per component, **all** modified components must appear, order
  is irrelevant. NO `feat:`/`fix:`/`prefix:` style.
- **Title-only fixes do NOT need a push:**
  ```bash
  gh pr edit 14119 --title "[nvm][fram_i2c] Add NVM component with FRAM I2C platform" \
    --repo esphome/esphome
  ```
  GitHub fires a `pull_request: edited` event and the title check re-runs in
  ~10s.
- The failure log explicitly prints `Suggested: [a][b] <description>` —
  copy that bracket set verbatim if unsure.

See `memory/reference_esphome_pr_conventions.md` for the full convention.

### 3d. Don't intend to merge upstream? → Convert PR to Draft

If the goal of this refresh round is just keeping CI green (not actually
landing the PR), flip it to Draft so review is no longer required:

```bash
gh pr ready 14119 --undo --repo esphome/esphome
```

The PR stays open and CI keeps running on every push, but `mergeStateStatus`
no longer blocks on codeowner approval. Reverse with `gh pr ready 14119`
when you're ready to ask for review.

---

## Phase 4 — Refresh `local/preferences-virtual`

This branch carries one extra commit on top of `pr/nvm-base` (the NVS
delegation revert). After `pr/nvm-base` is updated, rebase it.

```bash
cd ~/dev/esphome
git checkout local/preferences-virtual
git rebase pr/nvm-base
```

Conflicts on rebase usually mean upstream ESPHome (or a fix landed on
`pr/nvm-base`) changed something in `nvm.h`/`nvm.cpp` that overlaps our NVS
delegation patch. Resolve manually:
- `class PreferencesPartition : public NvmDataPartition, public Component, public ESPPreferences` (NOT `NvmPreferencesMixin`)
- `nvs_preferences_{nullptr}` member preserved
- In `setup()`: `this->nvs_preferences_ = global_preferences; global_preferences = this;`
- In `make_preference(size_t, uint32_t)`: `if (type == safe_mode::RTC_KEY && this->nvs_preferences_ != nullptr) return this->nvs_preferences_->make_preference(length, type);`
- `class NvmPreferenceBackend : public ESPPreferenceBackend` (with `override` on save/load)

**Canonical conflict patterns seen in practice:**

1. **Namespace declaration** (top of `nvm.h` / `nvm.cpp`):
   ```
   <<<<<<< HEAD              <- new pr/nvm-base
   namespace esphome::nvm {
   =======
   namespace esphome {       <- old local commit, pre-modernization
   namespace nvm {
   >>>>>>> <local commit>
   ```
   → **Keep HEAD** (flat C++17 form). Same goes for the closing comment at
   the bottom: `}  // namespace esphome::nvm`.

2. **`NvmPreferenceObject` + `NvmPreferencesMixin` block** (around line 220 of
   `nvm.h`): the standalone object/mixin classes only exist on the vanilla
   `pr/nvm-base` design — `local/preferences-virtual` uses `ESPPreferences`
   inheritance directly, so this entire block has no place on local.
   → **Delete the HEAD block**, keep the local side (which is empty in that
   location). After resolution, verify nothing in `nvm.cpp` still references
   `NvmPreferenceObject` or `NvmPreferencesMixin` on local.

3. **`nvm::RTC_KEY` constant**: removed on both branches as of 2026-05 (PR
   #14121 merged → use `safe_mode::RTC_KEY`). Auto-merge handles this; if you
   see a conflict here, both deletions should win.

4. **`#include "esphome/components/safe_mode/safe_mode.h"` in `nvm.h`**: only
   exists on local (needed for the delegation `if (type == safe_mode::RTC_KEY)`
   check). Auto-merge usually keeps it; if conflicting, **keep the include**.

Compile + flash test (same commands as Phase 3b):
```bash
cd ~/dev/esphome_scripts
esphome ... compile 0_DEV/esp32c3_dev.yaml
ping -c 2 esp32-32.lan
esphome ... run 0_DEV/esp32c3_dev.yaml --device esp32-32.lan
```

Verify in the OTA log (in addition to Phase 3b checks — same MQTT-misses-
early-boot caveat applies):
- **RGB LED 🟢 green** = preferences came up on FRAM. This is the primary
  signal that the `local/preferences-virtual` delegation is active. If the
  LED is 🟠 **orange**, the NVM partition failed to initialize and the device
  fell back to NVS — investigate before declaring the rebase good.
- `Pref: Boot Count` / `Pref: Test Value` reflect FRAM partition contents,
  but only update when the user clicks the test rig button — they will not
  change on their own. A stable post-reboot value matching the last manual
  click before reboot proves partition reads work.
- `[I][safe_mode:091]: Boot seems successful; resetting boot loop counter`
  proves `RTC_KEY` is delegated correctly to NVS (otherwise safe_mode would
  be reading a FRAM value at pre-init when FRAM is not yet initialized,
  leading to boot loop after 8 reboots). MQTT logs likely won't capture this
  — the surrogate signal is "device is alive 60s+ after flash, RGB green,
  no `Guru Meditation`/`panic`/`abort` in the captured log window".

Push:
```bash
git push --force-with-lease origin local/preferences-virtual
```

---

## Phase 5 — Optionally flash production devices

Once `local/preferences-virtual` compiles + boots cleanly on esp32-32:

For each production device that uses NVM/FRAM (e.g., `esp32-35` Pump_Garage
with water meter pulse counter):

```bash
ping -c 2 esp32-XX.lan
esphome ... run 2_PROD/esp32-XX_<Device>.yaml --device esp32-XX.lan
```

Verify per-device that:
- Boot successful
- Sensor values restored from FRAM
- safe_mode reset fires after 60s
- Device-specific functionality works (e.g., water meter increments)

Mark device done in `upgrade/ESPHOME_<version>.md`.

---

## Troubleshooting

### Compile fails: `'register_component_' is private`
The override doesn't help here. `Application::register_component_` is
templated and protected — call `setup()` on `PreferencesPartition` directly
from `NvmPlatform::setup()` instead. See commit `9eb020a4a` for the pattern.

### Compile fails: `cannot derive from 'final' base`
Override didn't take effect. Verify:
```bash
ls -la ~/dev/esphome_scripts/esphome-overrides/esphome/components/esp32/preferences.h
# Should be a real file (not a symlink), with our LOCAL OVERRIDE comment header.

grep "external_components" 0_DEV/esp32c3_dev.yaml | head
# Should reference esphome-overrides AND list 'esp32' in components.

cat 0_DEV/.esphome/build/esp32-32/src/esphome/components/esp32/preferences.h | head -10
# Should show our patched version, not vanilla.
```

If the build still has vanilla — clean rebuild:
```bash
rm -rf 0_DEV/.esphome/build/esp32-32
esphome ... compile 0_DEV/esp32c3_dev.yaml
```

### `safe_mode:091` doesn't fire (boot loop after ~8 reboots)
This means `RTC_KEY` is going to FRAM instead of NVS. Check:
- `local/preferences-virtual` HEAD has `safe_mode::RTC_KEY` in
  `make_preference` delegation logic
- `nvs_preferences_` is non-null (i.e., setup() captured the original
  `global_preferences` BEFORE replacing it)
- `#include "esphome/components/safe_mode/safe_mode.h"` is in `nvm.h`

### Override drift not detected on refresh.sh re-run
Snapshot files (`.preferences.h.upstream`, `.preference_backend.h.upstream`)
are inside `esphome-overrides/esphome/components/esp32/` with leading dot —
gitignored. If accidentally committed, the cached state is stale. Delete and
re-run `refresh.sh`.

### pre-commit pylint fails: `FileNotFoundError: 'pylint'`
The ESPHome repo's `.venv` is broken (e.g., underlying Python version was
upgraded by homebrew). Rebuild it (see Phase 1 fallback).

---

## Quick reference: branches and what to do with them

```
~/dev/esphome
├── pr/nvm-base                  ← public PR#14119, vanilla-compatible
│                                  (rebase + force-push only after green test)
├── local/preferences-virtual    ← private production, NVS delegation
│                                  (rebase on pr/nvm-base after each refresh)
├── wip/pr-refresh-YYYY-MM-DD    ← throw-away during refresh, delete after
└── dev                          ← upstream tracking, untouched

~/dev/esphome_scripts
├── esphome-overrides/           ← override directory
│   ├── refresh.sh               ← run after every pip install -U esphome
│   └── esphome/components/esp32/
│       ├── preferences.h        ← patched, version-controlled
│       └── preference_backend.h ← patched, version-controlled
└── upgrade/
    ├── SOP_upgrade.md           ← general ESPHome upgrade SOP
    ├── SOP_pr14119_refresh.md   ← THIS file
    └── ESPHOME_<version>.md     ← per-version device tracking
```
