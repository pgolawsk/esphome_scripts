# esphome

My configutation scripts for esp and similar devices within my home network, including multiple sensors, switches.

This repository contains YAML scripts for configuration of ESP devices (includes esp8266, esp32, bk7231n).

Author Pawel Golawski <pawel.golawski@2com.pl>

## Futures

* This is modular repository, which means that sensors, manipulators, ... are embed into particular device script via ```!include <file>``` statements. Usualy those are single line includes.
* Those includes may define or override variables, which make paricular configuration. For example for ```i2c.yaml``` variables given define GPIO pins which are serve as I2C interface.
* Always available components:
  * Wifi
  * OTA (Over The Air) updates
  * MQTT publish sensor values, like ```esp-xx/temperature```
  * Addittional MQTT topic for sensors with friendly structure, like ```home/office/temperature```
  * Logger via MQTT
  * Prometheus
  * Homeassistant API
  * Web server
  * Time (via SNTP)
  * Sun (to provide elevation, azimuth and sunrise sunset times)
* Optional components:
  * RTTTL - to play RTTTL melody via passive buzzer; melody can be recieved via MQTT (```esp-xx/play_rtttl``` topic)

## Available configurations

### Measures (```MM```)

All available measures

* ```T``` - Temperature
* ```H``` - Humidiy
* ```P``` - Pressure
* ```G``` - Gas Resistnance
* ```I``` - Illuminance
* ```C``` - CO2 (Carbon Dioxide)
* ```E``` - eCO2 (Equivalent Carbon Dioxide)
* ```D``` - Distance
* ```O``` - TVOC (Total Volatile Organic Compounds)
* ```W``` - Water Meter
* ```P``` - Presence (human)
* ```R``` - Current (DC)
* ```V``` - Voltage (DC)
* ```W``` - Power (DC)
* ```M``` - Motion
* ```U``` - Gestures
* ```B``` - RGB Colour

### Manipulators (```mm```)

All available manipulators

* ```1r``` - Single Switch/Relay
* ```2l``` - Double Ligiht Switch
* ```b``` - Buzzer
* ```d``` - Diode
* ```s``` - Switch

### Sensors (```SS```)

All available sensors

* ```S``` - SHTx30 - Temperature and Humidity
* ```B``` - BH1750 - Illuminance
* ```T``` - TCS3472 - Illuminance and Color(s)
* ```P``` - BME280 - Temperature, Humidity, Pressure
* ```G``` - BME680 - Temperature, Humidity, Pressure, Gas Ressistance
* ```C``` - SCD40 - CO2, Temperature, Humidity
* ```D``` - DS18B20 (Dallas) - Temperature
* ```O``` - SGP30 - TVOC and eCO2
* ```Y``` - YF-B10 G1 - Water Pulse sensor
* ```L``` - LD2410 - Radar sensor 24GHz
* ```E``` - INA226 - DC Current, Power, Voltage
* ```F``` - INA3221 - 3-channel DC Current, Power, Voltage
* ```A``` - APDS9660 - Illuminance, Color(s), Gesture and Motion

### Switches (```ss```)

All available switches boards

* ```a``` - AVT5713 - Double Light Switch Board
* ```x``` - Single Relay Board (generic from Aliexpress)
* ```b``` - 9032A/9025A - Active Buzzer 9mm diameteer x 3.2/2.5mm height
* ```r``` - 9032/9025 - Passive Buzzer 9mm diameteer x 3.2/2.5mm height

### Purpose (```PP```)

All available purposes. Those are changing the names of the manipulators to reflect their particular purpose.

* ```F``` - Fan
* ```G``` - Gate

## Script names

Script filenames reflect what sensors, switches and manipulators are included in particular one. The naming convention is ```board_MMmm_SSss__PP.yaml```, where:

* ```board``` is the type of ESP board/device
* ```MM``` are the MEASURES provided, like temperature, humidity, ...
* ```mm``` are the manipulators used, like diode, rtttl, ...
* ```SS``` are the SENSORS used, like SHT30, BH1750, ...
* ```ss``` are the switches used, like buzzer, AVT5713 board, ...
* ```PP``` is PURPOSE of the device, like fan or gate;

For example: ```esp12f_THIddb_STr.yaml``` script is for:

* measures:
  * ```T``` - Temperature
  * ```H``` - Humidiy
  * ```I``` - Illuminance
* manipulators:
  * ```d``` - diode
  * ```d``` - diode (2nd one)
  * ```b``` - buzzer
* sensors:
  * ```S``` - SHT30 - temperature and humidity
  * ```T``` - TCS3472 - illuminance and temperature color
* switches:
  * ```r``` - RTTTL

## Usage

### Requirements

You need to have

* ```python3``` installed, in minimum version ```3.10```
* ```esphome``` command installed, im minimum version ```2023.02```.

### Installation

Short instruction:

* To install please use follwing: ```pip3 install esphome```
* To install upgrade use follwing: ```pip3 install -U esphome```

To see full installation procedure please follow ```esp_setup.sh``` file and run specific commands. DO NOT RUN this script at once. The file includes:

* MQTT configuration, especially ACL
* Prometheus configuration
  * Example Grafana dashboard to display data from Prometheus is in ```Home Sensors-Grafana4Prometheus_dashboard.json``` file
* ```esphome``` commands to flash specific configurations

### Example ESP device flasing command

Before running it please:

* Copy ```secrets_example.yaml``` script into ```secrets.yaml``` and modify values for secret variables, like WiFi password
* Review the script actions. See ```esp12_dev.yaml``` as example as it contains almost all available configurations with ```!include``` files parameters. For full list of include file parameters please see inside specific include file.

#### Sample command

```esphome -s devicename esp12f_office -s updates 30s -s room Office -s mqtt_room office run esp12f_THIddb_STr.yaml```

To trigger only OTA update for particular IP please add ```--device 192.168.x.x``` at the end of above command.

##### Command parameters

The parameters are following ```-s``` argument. Those are:

* ```devicename``` - the name of the device, ```esp-xx``` is default
* ```updates``` - how frequently sensors are updated, ```30s``` is default
* ```room``` - friendly name of the room, ```Room``` is default
* ```mqtt_location``` - name of the location for MQTT, ```home``` is default
* ```mqtt_room``` - name of the room for MQTT, ```room``` is default

## Repo description

### Folders

* ```buttons``` - list of buttons intended to include them under ```button:``` section
* ```deprecated``` - contain all old versions (not modular)
* ```examples``` - example configurations, how to use set of scripts
* ```fans``` - list of switches intended to include them under ```fan:``` section
* ```fonts``` - list of fonts to draw on displays intended to include them under ```font:``` section
* ```includes``` - basic scripts for ESP boards, wifi, mqtt, ota, ...
  * ```boards``` scripts mat contain wiring instructions - please READ those
* ```interfaces``` - list of separate interfaces to include like ```i2c```, ```uart```, ```dallas```
* ```lights``` - list of switches intended to include them under ```light:``` section
* ```outputs``` - list of outputs intended to include them under ```output:``` section
* ```sensors``` - list of sensors intended to include them under:
  * ```binary_senor:``` section, those with filenames starting as ```binary_```
  * ```text_senor:``` section, those with filenames starting as ```text_```
  * ```sensor:``` section, all remaining files
* ```switches``` - list of switches intended to include them under ```switch:``` section

### Other

This is private repository, not intended to be public.

[//]: # (None at the moment)
