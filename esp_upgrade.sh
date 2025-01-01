#* Upgrade of ESP version and active ESP sensors
# Pawelo 20230923, created based on esp_setup.sh
# Pawelo 20231205, added esp32-31
# Pawelo 20240408, added esp32-05
# Pawelo 20241222, added esp32-14, esp32-39
# Pawelo 20241223, compiled esp32-14 successfully
# Pawelo 20241231, added esp32-33 (s3) and esp32-34 (s2)
# Pawelo 20250101, added examples how to read logs

#*###########################
#*** OR Upgrade ESP Home on mac/win

# check current version
esphome version

python3.11 -m pip install --upgrade pip
pip3.11 install -U esphome
# platformio is updated by esphome to minimum version required anyway
# pip3.11 install -U platformio

# clean unnesecary packages
# pio system prune --dry-run
pio system prune

# check current version (after upgrade)
esphome version

#*###########################
#* Upgrade ESP devices via OTA
esphome -s devicename esp32-05 -s updates 1min -s room Shades -s mqtt_location outside -s mqtt_room shades -s room2 WinterGardenUpp -s mqtt_location2 home -s mqtt_room2 winter_garden_upp run esp32-05_Shades_WinterGardenUpp
esphome -s devicename esp12f-11 -s updates 30s -s room Entrance -s mqtt_room entrance -s room2 Entry -s mqtt_location2 outside -s mqtt_room2 entry run esp12f-11_Entrance_Entry
esphome -s devicename esp12f-15 -s updates 30s -s room Upstairs -s mqtt_room upstairs run esp12f-15_Upstairs
esphome -s devicename esp12f-21 -s updates 30s -s room Unrderfloor -s mqtt_location measures -s mqtt_room underfloor run esp12f-21_Underfloor
esphome -s devicename esp12f-25 -s updates 30s -s room AquariumWindow -s mqtt_location measures -s mqtt_room aquarium_window run esp12f-25_AquariumWindow
esphome -s devicename esp32-35 -s updates 1min -s room Pump -s mqtt_location measures -s mqtt_room pump -s room2 Garage -s mqtt_location2 outside -s mqtt_room2 garage run esp32-35_Pump_Garage
# esphome -s devicename esp32-35 -s updates 1min -s room Pump -s mqtt_location measures -s mqtt_room pump run esp32_display_lcd_pcf8574.yaml
# esphome -s devicename esp32-35 -s updates 1min -s room Pump -s mqtt_location measures -s mqtt_room pump run esp32_display_weact.yaml

#* Future devices via OTA (with "compile" instead of "run")
esphome -s devicename esp32-14 -s updates 30s -s room Salon -s mqtt_room salon compile esp32-14_Salon #! internal temp sensor is commented now
esphome -s devicename esp32-39 -s updates 1min -s room Attic -s mqtt_location home -s mqtt_room attic compile esp32-39_Attic

#* Test devices
esphome -s devicename esp12f-29 -s updates 30s -s room Test -s mqtt_location measures -s mqtt_room test run esp12f_dev.yaml
esphome -s devicename esp32-30 -s updates 1min -s room Test32 -s mqtt_location measures -s mqtt_room test32 -s room2 Test32b -s mqtt_location2 measures -s mqtt_room2 test32b run esp32_dev.yaml
# esphome -s devicename esp32-30 -s updates 1min -s room Test32D -s mqtt_location measures -s mqtt_room test32 -s room2 Test32DU -s mqtt_location2 measures -s mqtt_room2 test32b run esp32_dev_display.yaml
# esphome -s devicename esp32-30 -s updates 1min -s room Test32 -s mqtt_location measures -s mqtt_room test32 run esp32_display_weact.yaml
# esphome -s devicename esp32-30 -s updates 1min -s room Test32 -s mqtt_location measures -s mqtt_room test32 run esp32_THIWdb_SBYr_display.yaml
# esphome -s devicename esp32-30 -s updates 1min -s room Test32 -s mqtt_location measures -s mqtt_room test32 run esp32_dev.yaml

esphome -s devicename esp32-31 -s updates 15s -s room Test32c3 -s mqtt_location measures -s mqtt_room test32c3 run esp32c3_dev.yaml
esphome -s devicename esp32-32 -s updates 15s -s room Test32c3rgb -s mqtt_location measures -s mqtt_room test32c3rgb run esp32c3_dev.yaml
esphome -s devicename esp32-33 -s updates 1min -s room Test32s3rgb -s mqtt_location measures -s mqtt_room test32s3rgb run esp32s3_dev.yaml
esphome -s devicename esp32-34 -s updates 1min -s room Test32s2 -s mqtt_location measures -s mqtt_room test32s2 run esp32s2_dev.yaml

# minimal config for S2
esphome -s devicename esp32-34a run esp32s2_dev_minimal.yaml

esphome -s devicename esp32-32 -s updates 1min -s room Test32c3rgb -s mqtt_location measures -s mqtt_room test32c3rgb run esp32c3_dev__no_mqtt.yaml

# generic ESP32 boards - no
esphome -s devicename esp32-dev -s updates 1min -s room Dev32 -s mqtt_location measures -s mqtt_room dev32 -s room2 Dev32b -s mqtt_location2 measures -s mqtt_room2 dev32b run esp32_dev.yaml

esphome run mac_host.yaml

#*###########################
#* Checking ESP logs

# example og "logs" command
esphome -s devicename esp32-34 logs esp32s2_dev.yaml