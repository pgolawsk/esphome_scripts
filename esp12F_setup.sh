#* Setup of ESP sensors
# Pawelo 20221111 first steps
# Pawelo 20221112, created based on https://www.youtube.com/watch?v=a3iay-g1AsI, https://github.com/geerlingguy/pico-w-garage-door-sensor, https://github.com/nygma2004/esphome

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
topic readwrite esp01/#
#pattern readwrite %c/#
#-------------------------
sudo service mosquitto restart


# read about mosquitto on http://www.steves-internet-guide.com/mosquitto_pub-sub-clients/
# subscribe to all MQTT topics:
mosquitto_sub -h localhost -t \# -d



##########################
#* Soldering the connections
# for ESP-12F, based on https://sktechworks.ca/2017/03/28/esp-12f-and-breakout-board/

# Minimum pinout to OPERATE
# VCC - 3.3V DC
# GND - GND
# GPIO0 - 10K resistor to 3.3V DC
# GPIO2 - 10K resistor to 3.3V DC - can be merged with GPIO0 if bootmode will not be enabled
# GPIO15 - 10K resistor to GND
# CH_PD/ED - 10K resistor to 3.3V DC
