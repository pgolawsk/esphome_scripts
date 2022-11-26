#* Setup of Air Quality Monitor PT02 via RS485
# Pawelo 20221117, created based on https://github.com/epsilonrt/mbpoll/
# Pawelo 20221118, further experiments
# Pawelo 20221122, further experiments with mbpool -l (pool time) -o (timeout)
# Pawelo 20221123, further experiments tuya-convert


pip3 install modbus_cli

# mbpool is MODBUS server simulator
sudo apt install mbpoll

# discover the device id
for i in {1..247}; do mbpoll -a $i -b 38400 -u /dev/ttyUSB0; done
for i in {1..247}; do mbpoll -a $i -b 4800 -l 100 -o 0.1 -1 -u /dev/ttyUSB0; done

# test the onnection
mbpoll -a 33 -b 38400 -t 3 -r 1 -c 2 /dev/ttyUSB0

mbpoll -0 -m rtu -u -l 100 -o 0.1 /dev/ttyUSB0

#####################
# on MAcOS, based on https://github.com/SciFiDryer/ModbusMechanic#latest-release
# 1. install java
# 2. download ModBusMechanic https://github.com/SciFiDryer/ModbusMechanic/releases/download/v2.3/ModbusMechanic.v2.3.zip
# 3. unpack to ~/ModBusMechanic

cd ~/ModBusMechanic

# run from CLI
sudo java -jar ModbusMechanic.jar

#! NOT CONENCTED - probably the sensor communication is broken:(

#*Tuya convert experiment, based on: https://lukasz.oksejuk.pl/2020/10/27/tasmota-wgrywanie-za-pomoca-tuya-convert/ and https://github.com/ct-Open-Source/tuya-convert
# clone tuya convert repo
git clone https://github.com/ct-Open-Source/tuya-convert
cd tuya-convert
./install_prereq.sh

# backup stock firmware
rfkill unblock all
ifconfig wlan0 up

# start flashing
./start_flash.sh