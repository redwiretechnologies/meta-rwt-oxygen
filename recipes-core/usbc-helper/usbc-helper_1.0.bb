SUMMARY = "Helper script to control USB-C OTG modes"
DESCRIPTION = "Helper script to control USB-C OTG modes"
LICENSE = "GPLv3"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"

DEPENDS ="libgpiod i2c-tools"

inherit systemd

SRC_URI = "\
	file://usbc_helper.c \
    file://usbc-helper.service \
    file://usbc-helper.conf \
    file://LICENSE \
	"
S = "${WORKDIR}"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
LDFLAGS_append = " -lgpiod -li2c "

SYSTEMD_SERVICE_${PN} = "usbc-helper.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_compile() {
	${CC} -Wall usbc_helper.c ${LDFLAGS} -o usbc_helper
}

do_install() {
    install -Dm 0644 ${S}/usbc-helper.conf ${D}${sysconfdir}/usbc-helper.conf
    install -Dm 0755 ${S}/usbc_helper ${D}${bindir}/usbc_helper

    # For systemd
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        install -D -m 0644 ${S}/usbc-helper.service ${D}${systemd_system_unitdir}/usbc-helper.service
        sed -i -e 's,@BINDIR@,${bindir},g' \
            ${D}${systemd_system_unitdir}/usbc-helper.service
    fi
}

FILES_${PN} = "\
        ${bindir}/usbc_helper \
        ${sysconfdir}/usbc-helper.conf \
        "
