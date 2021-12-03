FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://usbmods.cfg \
    file://moreusb.cfg \
    file://sensors.cfg \
    file://random.cfg \
    file://pci_usb3380.cfg \
    file://power.cfg \
    file://hwmon-jc42-Fix-name-to-have-no-illegal-characters.patch \
"

# The patch was suggested by Xilinx to speed up USB3; however, g_ether fails
# whenever I try to use it.
#
# file://0001-Change-bMaxBurst-and-qlen-to-the-highest-number.patch
