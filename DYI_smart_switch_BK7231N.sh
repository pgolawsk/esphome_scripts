#* DYY Smart Switch flashing with OpenBeken
# Pawelo, 20230311, created based on https://www.elektroda.pl/rtvforum/topic3912748.html
#TODO: maybe it will work with ESPHome as well, see https://docs.libretuya.ml/docs/projects/esphome/
#TODO https://github.com/openshwprojects/OpenBK7231T_App/blob/main/README.md#flashing-for-bk7231n

########################
#* Install LibreTuya
#! Not working - awaiting for oficial integration libretuya with ESPHome
platformio platform install -f https://github.com/kuba2k2/libretuya

mkdir libretuya
cd libretuya
mkdir esphome
cd esphome
git clone https://github.com/kuba2k2/libretuya-esphome
cd libretuya-esphome

########################
#* Install OpenBeken - via UART

# 1. Create directory for binaries
mkdir openbeken_bin
cd openbeken_bin

# 2. Download latest release from https://github.com/openshwprojects/OpenBK7231T_App/releases
# ...
# ❯ ls
# OpenBK7231N_QIO_1.15.580.bin OpenBK7231N_UG_1.15.580.bin

# 3. Install bk7231tools
pip install bk7231tools

# 4. Connect UART to USB, solder the wires as described in https://www.elektroda.pl/rtvforum/topic3912748.html

# 5. Download current firmware
#! Not working - maybe tuya cloudcutter would work
# bk7231tools read_flash -d /dev/ttyUSB0 -s 0 -l 0x200000 dump.bin
bk7231tools read_flash -d /dev/tty.usbserial-A50285BI -s 0 -l 0x200000 dump.bin


# 6. Flash new firmware
# write stock app (from full dump)
# start=0x11000, skip=0x11000, length=0x121000
bk7231tools write_flash -d /dev/tty.usbserial-A50285BI -s 0x11000 -S 0x11000 -l 0x121000 OpenBK7231N_QIO_1.15.580.bin

########################
#* Install OpenBeken - via Tuya CloudCutter
#! Not working
# As per instructions from https://github.com/tuya-cloudcutter/tuya-cloudcutter/blob/main/HOST_SPECIFIC_INSTRUCTIONS.md

# use stanalone Raspbeery with ubuntu
ssh rpi_ubuntu

# prepare tuya-cloudcutter
git clone https://github.com/tuya-cloudcutter/tuya-cloudcutter

cd tuya-cloudcutter

sudo docker build --network=host -t cloudcutter .

# download your device .json configuration
# look for specific device on https://github.com/tuya-cloudcutter/tuya-cloudcutter.github.io/tree/master/devices
# For Mini Smart Swith this is https://raw.githubusercontent.com/tuya-cloudcutter/tuya-cloudcutter.github.io/master/devices/aubess-16a-mini-smart-switch.json
# curl -O https://raw.githubusercontent.com/tuya-cloudcutter/tuya-cloudcutter.github.io/master/devices/aubess-16a-mini-smart-switch.json

# determine your specific device name https://github.com/tuya-cloudcutter/tuya-cloudcutter.github.io/tree/master/devices
# aubess-16a-mini-smart-switch

# display wifi interfaces
rfkill

sudo rfkill unblock wlan

rfkill

# download OpenBeken firmware to flash
#! get version for cloudcutter - "UG"
# curl -O https://raw.githubusercontent.com/openshwprojects/OpenBK7231T_App/releases/download/1.15.581/OpenBK7231N_UG_1.15.581.bin
cd custom-firmware
wget https://github.com/openshwprojects/OpenBK7231T_App/releases/download/1.15.581/OpenBK7231N_UG_1.15.581.bin
cd ..

# install NetworkManager
sudo apt-get install network-manager
sudo systemctl start NetworkManager.service

# configure DHCP client daemon
sudo vi /etc/dhcpcd.conf
#--------------------- add this
denyinterfaces wlan0
#---------------------

# configure NetworkManager
sudo vi /etc/NetworkManager/NetworkManager.conf
#--------------------- add this
[main]
plugins=ifupdown,keyfile
dhcp=internal

[ifupdown]
managed=true
#---------------------

# detaching from tuya cloud
sudo ./tuya-cloudcutter.sh -s <SSID> <SSID_password>
# flashing custom firmware
sudo ./tuya-cloudcutter.sh -p aubess-16a-mini-smart-switch -f OpenBK7231N_UG_1.15.581.bin

#!Error: Connection activation failed: (11) 802.1X supplicant took too long to authenticate.