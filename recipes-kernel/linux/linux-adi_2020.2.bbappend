FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://usbmods.cfg \
            file://moreusb.cfg \
            file://sensors.cfg \
            file://random.cfg \
            file://pci_usb3380.cfg \
            file://power.cfg \
            file://0001-allow-for-larger-gain-table-set.patch \
            file://hwmon-jc42-Fix-name-to-have-no-illegal-characters.patch \
            file://perf-fix-build-with-binutils.patch \
            file://0001-perf-bench-Share-some-global-variables-to-fix-build-.patch \
            file://0001-perf-tests-bp_account-Make-global-variable-static.patch \
            file://0001-perf-cs-etm-Move-definition-of-traceid_list-global-v.patch \
            file://0001-libtraceevent-Fix-build-with-binutils-2.35.patch \
            "

# The patch was suggested by Xilinx to speed up USB3; however, g_ether fails
# whenever I try to use it.
#
# file://0001-Change-bMaxBurst-and-qlen-to-the-highest-number.patch
