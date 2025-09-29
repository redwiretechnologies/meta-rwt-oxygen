FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://1-3-spi-dt-bindings-nxp-sc18is602-convert-binding-to-YAML.patch \
            file://2-3-spi-dt-bindings-nxp-sc18is602-add-compatible-for-SC18IS606.patch \
            file://usbmods.cfg \
            file://moreusb.cfg \
            file://sensors.cfg \
            file://random.cfg \
            file://pci_usb3380.cfg \
            file://power.cfg  \
            "
KERNEL_VERSION_SANITY_SKIP="1"
# The patch was suggested by Xilinx to speed up USB3; however, g_ether fails
# whenever I try to use it.
#
# file://0001-Change-bMaxBurst-and-qlen-to-the-highest-number.patch
