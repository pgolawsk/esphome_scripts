#pragma once
#ifdef USE_ESP32

// LOCAL OVERRIDE — patched copy of upstream esp32/preferences.h
// Difference vs vanilla 2026.4.5:
//   - removed `final` from ESP32Preferences
//   - virtualized make_preference / sync / reset + virtual destructor
// Purpose: allow nvm::PreferencesPartition to derive from ESP32Preferences
// and replace global_preferences (transparent FRAM persistence + NVS
// delegation for safe_mode boot counter).
// Sync this header with upstream when esphome version is upgraded.

#include "esphome/core/preference_backend.h"

namespace esphome::esp32 {

struct NVSData;

class ESP32Preferences : public PreferencesMixin<ESP32Preferences> {
 public:
  using PreferencesMixin<ESP32Preferences>::make_preference;
  void open();
  virtual ESPPreferenceObject make_preference(size_t length, uint32_t type, bool in_flash) {
    return this->make_preference(length, type);
  }
  virtual ESPPreferenceObject make_preference(size_t length, uint32_t type);
  virtual bool sync();
  virtual bool reset();
  virtual ~ESP32Preferences() = default;

  uint32_t nvs_handle;

 protected:
  bool is_changed_(uint32_t nvs_handle, const NVSData &to_save, const char *key_str);
};

void setup_preferences();

}  // namespace esphome::esp32

DECLARE_PREFERENCE_ALIASES(esphome::esp32::ESP32Preferences)

#endif  // USE_ESP32
