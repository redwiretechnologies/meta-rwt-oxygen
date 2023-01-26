DESCRIPTION = "Temporary fix to resolve shutdown issues with rngd"
LICENSE = "MIT"
LIC_FILES_CHKSUM = " \
file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302 \
"

inherit systemd
SYSTEMD_SERVICE:${PN} = "rngd-reboot.service"
SYSTEMD_AUTO_ENABLE = "enable"

SRC_URI = "file://rngd-reboot.service"

S = "${WORKDIR}"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

do_install() {
    # For systemd
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        install -D -m 0644 ${S}/rngd-reboot.service ${D}${systemd_system_unitdir}/rngd-reboot.service
    fi
}
