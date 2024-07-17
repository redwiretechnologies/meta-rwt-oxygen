DESCRIPTION = "Temporary fix to resolve shutdown issues with rngd"
LICENSE = "MIT"
LIC_FILES_CHKSUM = " \
file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302 \
"

inherit systemd
SYSTEMD_SERVICE:${PN} = "rngd-reboot.service"
SYSTEMD_AUTO_ENABLE = "enable"

SRC_URI = "file://rngd-reboot.service"

FILES:${PN} += "${systemd_system_unitdir}/rngd-reboot.service"

do_install() {
    # For systemd
        install -d ${D}/${systemd_unitdir}/system
        install -D -m 0644 ${WORKDIR}/rngd-reboot.service ${D}${systemd_system_unitdir}/rngd-reboot.service
    
}
