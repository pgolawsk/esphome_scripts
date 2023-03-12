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

