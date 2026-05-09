#pragma once
#ifdef USE_ESP32

// LOCAL OVERRIDE — patched copy of upstream esp32/preference_backend.h
// Difference vs vanilla 2026.4.5:
//   - removed `final` from ESP32PreferenceBackend
//   - virtualized save / load + virtual destructor
// Purpose: allow nvm::NvmPreferenceBackend to derive from
// ESP32PreferenceBackend so ESPPreferenceObject(backend).save/load
// dispatches polymorphically to the FRAM-backed implementation.
// Sync this header with upstream when esphome version is upgraded.

#include <cstddef>
#include <cstdint>

namespace esphome::esp32 {

class ESP32PreferenceBackend {
 public:
  virtual bool save(const uint8_t *data, size_t len);
  virtual bool load(uint8_t *data, size_t len);
  virtual ~ESP32PreferenceBackend() = default;

  uint32_t key;
  uint32_t nvs_handle;
};

class ESP32Preferences;
ESP32Preferences *get_preferences();

}  // namespace esphome::esp32

namespace esphome {
using PreferenceBackend = esp32::ESP32PreferenceBackend;
}  // namespace esphome

#endif  // USE_ESP32
