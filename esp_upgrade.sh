#* Upgrade of ESP version and active ESP sensors
# Pawelo 20230923, created based on esp_setup.sh

#######################
#*** OR Upgrade ESP Home on mac/win
pip3 install -U esphome
pip3 install -U platformio

# clean unnesecary packages
# pio system prune --dry-run
pio system prune

#* Upgrade ESP devices via OTA
esphome -s devicename esp12f-11 -s updates 30s -s room Entrance -s mqtt_room entrance run esp12f_THIPGbdss_BGr__G.yaml
esphome -s devicename esp12f-15 -s updates 30s -s room Upstairs -s mqtt_room upstairs run esp12f_THP_P.yaml
esphome -s devicename esp12f-21 -s updates 30s -s room Unrderfloor -s mqtt_location measures -s mqtt_room underfloor run esp12f_THdb_SDr.yaml
esphome -s devicename esp12f-25 -s updates 30s -s room AquariumWindow -s mqtt_location measures -s mqtt_room aquarium_window run esp12f_THIddb_STr.yaml
esphome -s devicename esp32-35 -s updates 1min -s room Pump -s mqtt_location measures -s mqtt_room pump run esp32_THIWdb_SBYr.yaml
# esphome -s devicename esp32-35 -s updates 1min -s room Pump -s mqtt_location measures -s mqtt_room pump run esp32_display_lcd_pcf8574.yaml
# esphome -s devicename esp32-35 -s updates 1min -s room Pump -s mqtt_location measures -s mqtt_room pump run esp32_display_weact.yaml

#* Test devices
esphome -s devicename esp12f-29 -s updates 30s -s room Test -s mqtt_location measures -s mqtt_room test run esp12f_dev.yaml
#esphome -s devicename esp32-30 -s updates 1min -s room Test32 -s mqtt_location measures -s mqtt_room test32 run esp32_display_weact.yaml
esphome -s devicename esp32-30 -s updates 1min -s room Test32 -s mqtt_location measures -s mqtt_room test32 run esp32_dev.yaml