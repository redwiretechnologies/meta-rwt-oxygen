SUMMARY = "Helper script to control USB-C OTG modes"
DESCRIPTION = "Helper script to control USB-C OTG modes"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${UNPACKDIR}/LICENSE;md5=51da0b8a3b91bf69984a5cdaed85e3e8"

DEPENDS = "libgpiod i2c-tools"

inherit systemd

SRC_URI = "\
	file://usbc_helper.c \
    file://usbc-helper.service \
    file://usbc-helper.conf \
    file://LICENSE \
	"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
LDFLAGS:append = " -lgpiod -li2c "

SYSTEMD_SERVICE:${PN} = "usbc-helper.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_compile() {
	${CC} -Wall  ${UNPACKDIR}/usbc_helper.c ${LDFLAGS} -o usbc_helper
}

do_install() {
    install -Dm 0644 ${UNPACKDIR}/usbc-helper.conf ${D}${sysconfdir}/usbc-helper.conf
    install -Dm 0755 ${B}/usbc_helper ${D}${bindir}/usbc_helper

    # For systemd
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        install -D -m 0644 ${UNPACKDIR}/usbc-helper.service ${D}${systemd_system_unitdir}/usbc-helper.service
        sed -i -e 's,@BINDIR@,${bindir},g' \
            ${D}${systemd_system_unitdir}/usbc-helper.service
    fi
}

FILES:${PN} = "\
        ${bindir}/usbc_helper \
        ${sysconfdir}/usbc-helper.conf \
        "
