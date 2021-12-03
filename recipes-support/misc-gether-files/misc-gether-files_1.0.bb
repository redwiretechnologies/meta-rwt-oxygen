SUMMARY = "Miscellaneous files required to get gether running at boot."
LICENSE = "MIT"
LIC_FILES_CHKSUM = " \
file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302 \
"

RDEPENDS_${PN} = "networkmanager"

SRC_URI = "\
    file://usb0 \
    file://mass_storage.bin \
    file://gadget.conf \
    file://modprobe_gether.conf \
    file://modprobe_gmulti.conf \
    "
S = "${WORKDIR}"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"


do_install() {
    install -Dm 0644 ${S}/gadget.conf ${D}${sysconfdir}/modules-load.d/gadget.conf
    install -Dm 0600 ${S}/usb0 ${D}${sysconfdir}/NetworkManager/system-connections/usb0
    install -Dm 0644 ${S}/modprobe_gether.conf ${D}${sysconfdir}/modprobe.d/gether.conf
    install -Dm 0644 ${S}/modprobe_gmulti.conf ${D}${sysconfdir}/modprobe.d/gmulti.conf
    install -Dm 0644 ${S}/mass_storage.bin ${D}/media/mass_storage.bin
}

FILES_${PN} = "\
    ${sysconfdir}/modules-load.d/gadget.conf \
    ${sysconfdir}/modprobe.d/gether.conf \
    ${sysconfdir}/modprobe.d/gmulti.conf \
    ${sysconfdir}/NetworkManager/system-connections/usb0 \
    /media/mass_storage.bin \
    "
