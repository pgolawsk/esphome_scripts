#* Setup of Air Quality Monitor PT02 via RS485
# Pawelo 20221117, created based on https://github.com/epsilonrt/mbpoll/
# Pawelo 20221118, further experiments


pip3 install modbus_cli

# mbpool is MODBUS server simulator
sudo apt install mbpoll

# discover the device id
for i in {1..247}; do mbpoll -a $i -b 38400 -u /dev/ttyUSB0; done

# test the onnection
mbpoll -a 33 -b 38400 -t 3 -r 1 -c 2 /dev/ttyUSB0


#####################
# on MAcOS, based on https://github.com/SciFiDryer/ModbusMechanic#latest-release
# 1. install java
# 2. download ModBusMechanic https://github.com/SciFiDryer/ModbusMechanic/releases/download/v2.3/ModbusMechanic.v2.3.zip
# 3. unpack to ~/ModBusMechanic

cd ~/ModBusMechanic

# run from CLI
sudo java -jar ModbusMechanic.jar
