SUMMARY = "Bitfiles and device-tree additions for running the default GnuRadio image."
DESCRIPTION = "Bitfiles and device-tree additions for running default GnuRadio image."
SECTION = "bsp"

LICENSE = "MIT"
LIC_FILES_CHKSUM = " \
        file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302 \
        "

DTS_FILE = "default.dts"
PERSONALITY = "default"

FILESEXTRAPATHS_prepend := "${THISDIR}/bitfiles-default:"

SRC_URI = " \
    file://2cg/system.xsa \
    file://2eg/system.xsa \
    file://3cg/system.xsa \
    file://3eg/system.xsa \
    file://4cg/system.xsa \
    file://4ev/system.xsa \
    file://default.dts \
"

include bitfiles.inc
