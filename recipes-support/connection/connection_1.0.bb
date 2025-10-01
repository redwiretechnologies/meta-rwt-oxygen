SUMMARY = "Connection file to describe hardware."
LICENSE = "MIT"
LIC_FILES_CHKSUM = " \
file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302 \
"


SRC_URI = "\
    file://connection_def.json \
    "
S = "${WORKDIR}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

INSANE_SKIP:${PN} += "empty-dirs"
do_install() {
    install -Dm 0644 ${S}/connection_def.json ${D}/${libdir}/firmware/rwt/connection_def.json
}

FILES:${PN} = "\
    ${libdir}/firmware/rwt/connection_def.json \
    "
