#* Upgrade of ESP version and active ESP sensors
# Pawelo, 20230923, created based on esp_setup.sh
# Pawelo, 20231205, added esp32-31
# Pawelo, 20240408, added esp32-05
# Pawelo, 20241222, added esp32-14, esp32-39
# Pawelo, 20241223, compiled esp32-14 successfully
# Pawelo, 20241231, added esp32-33 (s3) and esp32-34 (s2)
# Pawelo, 20250101, added examples how to read logs
# Pawelo, 20250101, added relay switches on esp01s circuit
# Pawelo, 20250109, added esp32-36 (c6) as TestC6 device
# Pawelo, 20250125, added esp32-39 as Attic device
# Pawelo, 20250125, added esp32-37 as TestS3SuperMini device
# Pawelo, 20250201, added esp32-38 as Test32ttgo device
# Pawelo, 20250201, moved some scripts to 0_DEV, 1_UAT or 2_PROD folders
# Pawelo, 20250202, added test of compile on each script in 0_DEV, 1_UAT, 2_PROD
# Pawelo, 20250203, exclude not ready (.yml) scripts from compilation tests
# Pawelo, 20250125, moved esp32-39 Attic device to 2_PROD
# Pawelo, 20250220, added venv creation for python3
# Pawelo, 20250221, added "esphome --version" prior testing cycles
# Pawelo, 20250615, moved esp12f-10 script to 2_PROD
# Pawelo, 20250823, added example of downgrade of esphome
# Pawelo, 20251225, reference to aliases for PROD devices from .dir_aliases file
# Pawelo, 20251230, use check_esphome_version.sh to verify if there is new ESPHome version

#*###########################
#* Check Python VENV
python --version
# Python 3.13.2

# if not VENV is active, activate it
source venv/bin/activate

pip install --upgrade pip
pip --version
# pip 25.0.1 from /Users/pawelo/dev/esphome_scripts/venv/lib/python3.13/site-packages/pip (python 3.13)
python --version
# Python 3.13.2

#*###########################
#* Upgrade ESP Home on mac/win

# check current version
esphome version

pip install --upgrade pip
pip install -U esphome
./check_esphome_version.sh

# platformio is updated by esphome to minimum version required anyway
# pip install -U platformio
# pip install esphome==2025.7.5

# clean unnecessary packages
pio system prune --dry-run
pio system prune

# check current version (after upgrade)
esphome version

#*###########################
#* Test if all devices compile with new version of ESP
#? uses "sh -c" to execute subcommands within "find -exec"
#? uses "basename" to get the filename without path and extension
#? uses tr to change uppercase to lowercase
#? sed s/_.*// to delete all after 1st underscore
#? sed s/_/-/g to replace underscores with dashes as those are used as DHCP hostname
#! some scripts were renamed to .yml from .yaml to exclude them from compilation tests
esphome --version && find 0_DEV -maxdepth 1 -type f -name "*.yaml" -exec echo ........ DEV COMPILE {} ....... \; -exec sh -c 'esphome -s devicename $(basename {} .yaml | tr "[:upper:]" "[:lower:]" | sed "s/_/-/g") compile {}' sh {} \;
esphome --version && find 1_UAT -maxdepth 1 -type f -name "*.yaml" -exec echo ........ UAT COMPILE {} ....... \; -exec sh -c 'esphome -s devicename $(basename {} .yaml | tr "[:upper:]" "[:lower:]" | sed "s/_.*// ; s/_/-/g") compile {}' sh {} \;
esphome --version && find 2_PROD -maxdepth 1 -type f -name "*.yaml" -exec echo ........ PROD COMPILE {} ....... \; -exec sh -c 'esphome -s devicename $(basename {} .yaml | tr "[:upper:]" "[:lower:]" | sed "s/_.*// ; s/_/-/g") compile {}' sh {} \;

#*###########################
#* Clean all build files and restore free space
#? uses "sh -c" to execute subcommands within "find -exec"
#? uses "basename" to get the filename without path and extension
#? uses tr to change uppercase to lowercase
#? sed s/_.*// to delete all after 1st underscore
#? sed s/_/-/g to replace underscores with dashes as those are used as DHCP hostname
#! some scripts were renamed to .yml from .yaml to exclude them from compilation tests
# esphome --version && find 0_DEV -maxdepth 1 -type f -name "*.yaml" -exec echo ........ DEV CLEAN {} ....... \; -exec sh -c 'esphome -s devicename $(basename {} .yaml | tr "[:upper:]" "[:lower:]" | sed "s/_/-/g") clean {}' sh {} \;
# esphome --version && find 1_UAT -maxdepth 1 -type f -name "*.yaml" -exec echo ........ UAT CLEAN {} ....... \; -exec sh -c 'esphome -s devicename $(basename {} .yaml | tr "[:upper:]" "[:lower:]" | sed "s/_/-/g") clean {}' sh {} \;
# esphome --version && find 2_PROD -maxdepth 1 -type f -name "*.yaml" -exec echo ........ PROD CLEAN {} ....... \; -exec sh -c 'esphome -s devicename $(basename {} .yaml | tr "[:upper:]" "[:lower:]" | sed "s/_/-/g") clean {}' sh {} \;
rm -rf .esphome
rm -rf 0_DEV/.esphome
rm -rf 1_UAT/.esphome
rm -rf 2_PROD/.esphome

############################
# In case this error you need to install ltchiptool manually
# INFO Resolving dependencies...
# Installing/updating ltchiptool
# ERROR: Invalid requirement: 'ltchiptool >= ^3.0.1, < 4.0': Expected end or semicolon (after name and no valid version specifier)
#     ltchiptool >= ^3.0.1, < 4.0
# pip install --upgrade setuptools wheel
pip install --upgrade "ltchiptool>=3.0.1,<4.0"


#*###########################
#* Upgrade PROD ESP devices via OTA
#! use aliases instead of below PROD, example esp10, esp05, ...
esphome -s devicename esp32-05 -s updates 1min -s room Shades -s mqtt_location outside -s mqtt_room shades -s room2 WinterGardenUpp -s mqtt_location2 home -s mqtt_room2 winter_garden_upp run 2_PROD/esp32-05_Shades_WinterGardenUpp.yaml
esphome -s devicename esp12f-10 -s updates 30s -s room Office -s mqtt_room office run 2_PROD/esp12f-10_Office.yaml
esphome -s devicename esp12f-11 -s updates 30s -s room Entrance -s mqtt_room entrance -s room2 Entry -s mqtt_location2 outside -s mqtt_room2 entry run 2_PROD/esp12f-11_Entrance_Entry.yaml
esphome -s devicename esp32-14 -s updates 30s -s room Salon -s mqtt_room salon run 2_PROD/esp32-14_Salon.yaml
esphome -s devicename esp12f-15 -s updates 30s -s room Upstairs -s mqtt_room upstairs run 2_PROD/esp12f-15_Upstairs.yaml
esphome -s devicename esp12f-21 -s updates 30s -s room Underfloor -s mqtt_location measures -s mqtt_room underfloor run 2_PROD/esp12f-21_Underfloor.yaml
esphome -s devicename esp12f-25 -s updates 30s -s room AquariumW -s mqtt_location measures -s mqtt_room aquarium_window run 2_PROD/esp12f-25_AquariumWindow.yaml
esphome -s devicename esp32-35 -s updates 1min -s room Pump -s mqtt_location measures -s mqtt_room pump -s room2 Garage -s mqtt_location2 outside -s mqtt_room2 garage run 2_PROD/esp32-35_Pump_Garage.yaml
esphome -s devicename esp32-36 -s updates 30s -s room Garage -s mqtt_location outside -s mqtt_room garage -s room2 Gate -s mqtt_location2 outside -s mqtt_room2 gate  run 2_PROD/esp32-36_Garage_Gate.yaml
esphome -s devicename esp32-39 -s updates 1min -s room Attic -s mqtt_location home -s mqtt_room attic run 2_PROD/esp32-39_Attic.yaml

#* Future devices via OTA (with "compile" instead of "run")
esphome -s devicename esp32-37 -s updates 1min -s room Garden -s mqtt_location outside -s mqtt_room garden -s room2 Gateway -s mqtt_location2 outside -s mqtt_room2 gateway compile 1_UAT/esp32-37_Garden_Gateway.yaml

#* New exploring devices
esphome -s devicename esp12f-29 -s updates 30s -s room Test -s mqtt_location measures -s mqtt_room test run 0_DEV/esp12f_dev.yaml
esphome -s devicename esp32-30 -s updates 1min -s room Test32 -s mqtt_location measures -s mqtt_room test32 -s room2 Test32b -s mqtt_location2 measures -s mqtt_room2 test32b run 0_DEV/esp32_dev.yaml
# esphome -s devicename esp32-30 -s updates 1min -s room Test32D -s mqtt_location measures -s mqtt_room test32 -s room2 Test32DU -s mqtt_location2 measures -s mqtt_room2 test32b run 0_DEV/esp32_dev_display.yaml
# esphome -s devicename esp32-30 -s updates 1min -s room Test32 -s mqtt_location measures -s mqtt_room test32 run 0_DEV/esp32_display_weact.yaml
# esphome -s devicename esp32-30 -s updates 1min -s room Test32 -s mqtt_location measures -s mqtt_room test32 run 0_DEV/esp32_THIWdb_SBYr_display.yaml
# esphome -s devicename esp32-30 -s updates 1min -s room Test32 -s mqtt_location measures -s mqtt_room test32 run 0_DEV/esp32_dev.yaml

esphome -s devicename esp32-31 -s updates 15s -s room Test32c3 -s mqtt_location measures -s mqtt_room test32c3 run 0_DEV/esp32c3_dev.yaml
esphome -s devicename esp32-32 -s updates 15s -s room Test32c3rgb -s mqtt_location measures -s mqtt_room test32c3rgb run 0_DEV/esp32c3_dev.yaml
esphome -s devicename esp32-33 -s updates 1min -s room Test32s3rgb -s mqtt_location measures -s mqtt_room test32s3rgb run 0_DEV/esp32s3_dev.yaml
esphome -s devicename esp32-34 -s updates 1min -s room Test32s2 -s mqtt_location measures -s mqtt_room test32s2 run 0_DEV/esp32s2_dev.yaml
esphome -s devicename esp32-36a -s updates 1min -s room Test32c6 -s mqtt_location measures -s mqtt_room test32c6 run 0_DEV/esp32c6_dev.yaml
esphome -s devicename esp32-37 -s updates 1min -s room Test32s3mini -s mqtt_location measures -s mqtt_room test32s3mini run 0_DEV/esp32s3supermini_dev.yaml
esphome -s devicename esp32-38 -s updates 1min -s room Test32ttgo -s mqtt_location measures -s mqtt_room test32ttgo run 0_DEV/esp32_display_ttgo.yaml

# minimal config for S2
esphome -s devicename esp32-34a run 0_DEV/esp32s2_dev_minimal.yaml

esphome -s devicename esp32-32 -s updates 1min -s room Test32c3rgb -s mqtt_location measures -s mqtt_room test32c3rgb run 0_DEV/esp32c3_dev__no_mqtt.yaml

# generic ESP32 boards - no
esphome -s devicename esp32-dev -s updates 1min -s room Dev32 -s mqtt_location measures -s mqtt_room dev32 -s room2 Dev32b -s mqtt_location2 measures -s mqtt_room2 dev32b run 0_DEV/esp32_dev.yaml

# relay switches on esp01s circuit
esphome -s devicename esp01s-100 -s updates 1min -s room "Kitchen" -s mqtt_room kitchen_fan -s off_delay 5min run 0_DEV/esp01s_1r_x__F.yaml

esphome run 0_DEV/mac_host.yaml

#*###########################
#* Checking ESP logs

# example og "logs" command
esphome -s devicename esp32-34 logs 0_DEV/esp32s2_dev.yaml