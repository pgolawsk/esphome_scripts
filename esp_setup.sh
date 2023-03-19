#* Setup of ESP sensors
# Pawelo 20221111 first steps
# Pawelo 20221112, created based on https://www.youtube.com/watch?v=a3iay-g1AsI, https://github.com/geerlingguy/pico-w-garage-door-sensor, https://github.com/nygma2004/esphome
# Pawelo 20221115, added prometheus setup, based on https://esphome.io/components/prometheus.html
# Pawelo 20221127, changed prometheus/mosquitto setups, after renaming all devices from espXX to esp12f-XX
# Pawelo 20221201, added OPTIONAL section with how to reprogram soldered esp12f module
# Pawelo 20221203, added ESP1 links in OPTIONAL section
# Pawelo 20221230, added flashing for Entrance room ("THIPG" measures and "d" switch) on esp12f
# Pawelo 20230101, added flashing for generic esp board with esp-32
# Pawelo 20230101, added flashing for Upstairs room ("THP" measires) on esp12f
# Pawelo 20230107, changed default update_interval to 30s (from 1min) to synchronize with prometheus
# Pawelo 20230108, moved esp12f tests to esp12f_dev.yaml script
# Pawelo 20230112, added flashing for generic esp32-cam-mb board
# Pawelo 20230305, upgrade esphome to 2023.2 version and platformio

#TODO: Read more complicated AIQ measurement on https://github.com/nkitanov/iaq_board
#TODO: Read about speaker with PAM8403 (amplifier) connection to ESP826 on: https://www.instructables.com/MQTT-Audio-Notifier-for-ESP8266-Play-MP3-TTS-RTTL/
#TODO: For automation on esp board read https://github.com/esphome/esphome-docs/blob/current/guides/automations.rst
#TODO: Water meter base on pulse counter https://www.pieterbrinkman.com/2022/02/02/build-a-cheap-water-usage-sensor-using-esphome-home-assistant-and-a-proximity-sensor/
#TODO: Add capture logs from the devices via Loki - read: https://github.com/lux4rd0/mqtt-logger
#? For MDI icons see there https://pictogrammers.github.io/@mdi/font/2.0.46/ or https://mdisearch.com

#######################
#* Configure new network for sensors at home
# based on: https://wiki.teltonika-networks.com/view/How_to_set_up_a_guest_WiFi_network_on_RUTX

#######################
#* Install ESPHome on ESP-12F board
# based on: https://esphome.io/index.html

# using Chrome or EDGE, visit: https://esphome.github.io/esp-web-tools/
# click "Connect" button to flash ESP with basic firmware

# then connect to wifi SENSORS
# and assign static ip for ESP board

#######################
#* Install ESP Home on mac/win

# assuming python3 is installed
pip3 install esphome

#######################
#*** OR Upgrade ESP Home on mac/win
pip3 install -U esphome
pip3 install -U platformio

#######################
# Create YAML file
# based on https://www.youtube.com/watch?v=a3iay-g1AsI
esphome wizard name.yml

# based on https://github.com/geerlingguy/pico-w-garage-door-sensor
# 1. check/create secrets.yaml

# 2. write config file for ESP device

# 3. compile and install over USB/OTA
esphome run name.yml

# 3a. compile and install over OTA directly to the IP
esphome run name.yml --device 192.168.x.x

# 4. Configure MQTT acl on MQTT server
sudo vi /etc/mosquitto/acl
#------------------------- add following to entitle devide to log data under it's topic
topic readwrite esp12f-10/#
#...
#pattern readwrite %c/#
#-------------------------

# restart mosquitto service to apply changes
sudo service mosquitto restart

# read about mosquitto on http://www.steves-internet-guide.com/mosquitto_pub-sub-clients/
# subscribe to all MQTT topics:
mosquitto_sub -h localhost -v -t \#

# subscribe to home/xxxxxx/xxxx MQTT topics:
mosquitto_sub -v -t home/#


##########################
#* Soldering the connections
# for ESP-12F, based on https://sktechworks.ca/2017/03/28/esp-12f-and-breakout-board/

# Minimum pinout to OPERATE
#? See pinout there https://randomnerdtutorials.com/esp8266-pinout-reference-gpios/
# VCC - 3.3V DC
# GND - GND
# GPIO0 - 10K resistor to 3.3V DC
# GPIO2 - 10K resistor to 3.3V DC - can be merged with GPIO0 if bootmode will not be enabled
# GPIO15 - 10K resistor to GND
# CH_PD/ED - 10K resistor to 3.3V DC

###########################
#* Install the firmwares (wired or OTA)
#*! RUN those commmands to compile and deliver updates to esp12f devices with sensors, switches, ...
#? --device is optional - if not given and device name can be found by dns then it will be flashed OTA anyway:)
#? 30s is 30 seconds and it's optimal as the same interval is setup on prometheus (could be 10s, 1min, 5min, ...)
# esphome -s devicename esp12f-10 -s updates 30s -s room Office -s mqtt_room office run esp12f_TH_S.yaml --device 192.168.x.x
# GROUND Floor
esphome -s devicename esp12f-10 -s updates 30s -s room Office -s mqtt_room office run esp12f_THICDV2lbd_BCEar.yaml --device 192.168.x.x
esphome -s devicename esp12f-11 -s updates 30s -s room Entrance -s mqtt_room entrance run esp12f_THIPGbdss_BGr__G.yaml --device 192.168.x.x
# esphome -s devicename esp12f-12 -s updates 30s -s room Kitchen -s mqtt_room kitchen run esp12f_dev.yaml --device 192.168.x.x
# esphome -s devicename esp12f-13 -s updates 30s -s room Salon -s mqtt_room salon run esp12f_dev.yaml --device 192.168.x.x
# esphome -s devicename esp12f-14 -s updates 30s -s room Toilet -s mqtt_room toilet run esp12f_dev.yaml --device 192.168.x.x
# esphome -s devicename esp12f-20 -s updates 30s -s room Dining -s mqtt_room dining run esp12f_dev.yaml --device 192.168.x.x
# 1ST Floor
esphome -s devicename esp12f-15 -s updates 30s -s room Upstairs -s mqtt_room upstairs run esp12f_THP_P.yaml --device 192.168.x.x
# esphome -s devicename esp12f-16 -s updates 30s -s room Aquarium -s mqtt_room aquarium run esp12f_dev.yaml --device 192.168.x.x
# esphome -s devicename esp12f-17 -s updates 30s -s room Forest -s mqtt_room forest run esp12f_dev.yaml --device 192.168.x.x
# esphome -s devicename esp12f-18 -s updates 30s -s room Bedroom -s mqtt_room bedroom run esp12f_dev.yaml --device 192.168.x.x
# esphome -s devicename esp12f-19 -s updates 30s -s room Bathroom -s mqtt_room bathroom run esp12f_dev.yaml --device 192.168.x.x

# MEASURES devices
esphome -s devicename esp12f-21 -s updates 30s -s room Unrderfloor -s mqtt_location measures -s mqtt_room underfloor run esp12f_THdb_SDr.yaml --device 192.168.x.x
esphome -s devicename esp12f-25 -s updates 30s -s room AquariumWindow -s mqtt_location measures -s mqtt_room aquarium_window run esp12f_THIddb_STr.yaml --device 192.168.x.x

# TEST devices
esphome -s devicename esp12f-29 -s updates 30s -s room Test  -s mqtt_location measures -s mqtt_room test run esp12f_dev.yaml --device 192.168.x.x
#esphome -s devicename esp12f-28 -s updates 30s -s room TestSwitch  -s mqtt_location measures -s mqtt_room test_switch run esp12f_THI2lbd_SBar.yaml --device 192.168.x.x
esphome -s devicename esp12f-28 -s updates 30s -s room TestSwitch2 -s mqtt_location measures -s mqtt_room test_switch2 run esp12f_THICDV2lbd_BCDar.yaml --device 192.168.x.x

# esphome -s devicename esp12f-11 -s updates 30s -s room Kitchen -s mqtt_room kitchen run esp12f_THI_SB.yaml --device 192.168.x.x


#*! RUN those commmands to compile and deliver updates to esp01s relay switches
#? --device is optional - if not given and device name can be found by dns then it will be flashed OTA anyway:)
esphome -s devicename esp01s-100 -s updates 1min -s room "Kitchen" -s mqtt_room kitchen_fan -s off_delay 5min run esp01s_1r__F.yaml --device 192.168.x.x


#*! RUN those commmands to compile and deliver updates to esp32 devices wit sensors, switches, ...
#? --device is optional - if not given and device name can be found by dns then it will be flashed OTA anyway:)
esphome -s devicename esp32-30 -s updates 1min -s room Test32 -s mqtt_location measures -s mqtt_room test32 run esp32_dev.yaml --device 192.168.x.x

esphome -s devicename esp32-40 -s updates 1min -s room Test32cam -s mqtt_location measures -s mqtt_room test32cam run esp32_cam.yaml --device 192.168.x.x

esphome -s devicename esp32-50 -s updates 60s -s room Display -s mqtt_location measures -s mqtt_room display run esp32_display.yaml --device 192.168.x.x

esphome -s devicename miniss-200 -s updates 60s -s room TestMiniSS -s mqtt_location measures -s mqtt_room test_miniss run miniss_dev.yaml --device 192.168.x.x

###########################
#* Set up Prometheus scraping
# open your prometheus.yaml config file and put there below lines
sudo vi prometheus.yaml
#---------------------------
  - job_name: 'esphome'
    static_configs:
#      - targets: ['esp12f-10:80','esp12f-11:80']
      - targets:
          - 'esp12f-10:80'
          - 'esp12f-11:80'
          - ...
        labels:
          node: 'esp'
#---------------------------

#once done restart the prometheus
docker-compose restart prometheus

# see in the logs if scraping is in place
docker-compose logs prometheus


###########################
#* Set up values display in Grafana
# while using Prometheus datasource check if new measures are available - filter by label: node=esp

#TODO Create dashboard for ESP values in Grafana


###########################
###########################
#* OPTIONAL
###########################
###########################
#* Programmming of soldered esp12f module, read https://www.hackster.io/brian-lough/3-simple-ways-of-programming-an-esp8266-12x-module-c514ee
#* 8 cables needed AND
# A. breadboard, RX, TX, GND connect to USB to serial converter
#* B. development board for esp01 to esp12 - connect 8 cables using development board pins to program it

# backup current firmware
esptool.py --port /dev/cu.usbserial-22120 read_flash 0x00000 0x100000 image1M.bin

# upload new ESPHome firmware with OTA
esphome -s devicename esp12f-13 -s updates 1min -s room TestSwitch -s mqtt_room test_switch run esp12f_TH2L_SA.yaml

# any further upload can be done via OTA:) with no soldering again

###########################
###########################
#* ESP01 consideration as switch relay - read this: https://www.forward.com.au/pfod/ESP8266/GPIOpins/ESP8266_01_pin_magic.html
# https://www.circuitschools.com/measure-ac-current-by-interfacing-acs712-sensor-with-esp32/
# https://www.esphome-devices.com/devices/ESP-01S-1-channel-relay