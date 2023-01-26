SUMMARY = "Bitfiles and device-tree additions for running with gr-iio"
DESCRIPTION = "Bitfiles and device-tree additions for running with gr-iio"
SECTION = "bsp"

LICENSE = "MIT"
LIC_FILES_CHKSUM = " \
		file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302 \
		"

DTS_FILE = "griio.dts"
PERSONALITY = "griio"

FILESEXTRAPATHS:prepend := "${THISDIR}/bitfiles-griio:"

SRC_URI = " \
    file://2cg/system.xsa \
    file://2eg/system.xsa \
    file://3cg/system.xsa \
    file://3eg/system.xsa \
    file://4cg/system.xsa \
    file://4ev/system.xsa \
    file://griio.dts \
"

include bitfiles.inc
