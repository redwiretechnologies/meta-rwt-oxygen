FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://usbmods.cfg \
            file://moreusb.cfg \
            file://sensors.cfg \
            file://random.cfg \
            file://pci_usb3380.cfg \
            file://power.cfg \
            file://0001-allow-for-larger-gain-table-set.patch \
            "
SRCREV = "${@ "cbdcc4022a5e9ff947533f0dc3542ff06cb5817d" if bb.utils.to_boolean(d.getVar('BB_NO_NETWORK')) else d.getVar('AUTOREV')}"
# The patch was suggested by Xilinx to speed up USB3; however, g_ether fails
# whenever I try to use it.
#
# file://0001-Change-bMaxBurst-and-qlen-to-the-highest-number.patch
