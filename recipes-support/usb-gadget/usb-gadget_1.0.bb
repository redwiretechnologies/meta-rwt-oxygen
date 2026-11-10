SUMMARY = "USB NCM network gadget through configfs, with jumbo frames"
DESCRIPTION = "Creates the device's USB Ethernet (NCM) gadget through configfs at boot (usb-gadget.service), \
with fixed MAC addresses, a larger maximum frame size (MTU 9000) and a deeper USB queue. \
Settings: /etc/default/usb-gadget."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://usb-gadget-configfs.sh \
    file://usb-gadget.conf \
    file://usb-gadget.service \
"

# Yocto 5.1 (styhead) and later unpack local files into UNPACKDIR.
# For 5.0 (scarthgap) and older, use:  S = "${WORKDIR}"
S = "${WORKDIR}"

inherit systemd
SYSTEMD_SERVICE:${PN} = "usb-gadget.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_install() {
    install -D -m 0755 ${S}/usb-gadget-configfs.sh ${D}${sbindir}/usb-gadget-configfs
    install -D -m 0644 ${S}/usb-gadget.conf ${D}${sysconfdir}/default/usb-gadget
    install -D -m 0644 ${S}/usb-gadget.service ${D}${systemd_system_unitdir}/usb-gadget.service
}

CONFFILES:${PN} = "${sysconfdir}/default/usb-gadget"

# The gadget modules when they're built as modules. Recommended rather than required, so a kernel
# with them built in also works.
RRECOMMENDS:${PN} = "kernel-module-libcomposite kernel-module-usb-f-ncm kernel-module-u-ether"
