inherit deploy

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

COMPATIBLE_MACHINE = "oxygen"

SRC_URI:append = " \
        file://oxygen-pcw.dtsi \
        file://oxygen.dts \
        file://usb-host.dts \
        file://usb-peripheral.dts \
        file://BISMUTH-1_0-0.dts \
        file://BISMUTH-2_0-0.dts \
        file://SELENIUM-1_0-0.dts \
        file://TELLURIUM-1_0-0.dts \
        file://ARGON-1_0-0.dts \
"
INSANE_SKIP:${PN} ="installed-vs-shipped"
FILES:${PN} +=  " ${libdir}/firmware/rwt/*.dtbo "

DEPENDS += "python3-dtc-native"

PROVIDES = "virtual/dtb"
BASE_DTS = "oxygen"

DTB_FILE_NAME = "${BASE_BTS}.dtb"
DTB_BASE_NAME ?= "${MACHINE}-system${IMAGE_VERSION_SUFFIX}"
KERNEL_DEVICETREE = "${BASE_BTS}.dtb"

do_install:append() {
    for DTB_FILE in `ls *.dtbo`; do
        install -Dm 0644 ${B}/${DTB_FILE} ${D}/${libdir}/firmware/rwt/${DTB_FILE}
    done
}

do_deploy:append() {
    install -Dm 0633 ${B}/oxygen.dtb ${DEPLOYDIR}/oxygen.dtb
    for DTB_FILE in `ls *.dtbo`; do
      install -Dm 0633 ${B}/${DTB_FILE} ${D}/${libdir}/firmware/rwt/${DTB_FILE}
    done
#    if [ -e "${DEPLOYDIR}/devicetree/${DTB_FILE_NAME}" ]; then
#            # We need the output to be system.dtb for WIC setup to match XSCT flow
#            ln -sf devicetree/${DTB_FILE_NAME} ${DEPLOYDIR}/${DTB_BASE_NAME}.dtb
#            ln -sf devicetree/${DTB_FILE_NAME} ${DEPLOYDIR}/${MACHINE}-system.dtb
#            ln -sf devicetree/${DTB_FILE_NAME} ${DEPLOYDIR}/system.dtb
#    else
#            bberror "Expected filename ${DTB_FILE_NAME} doesn't exist in ${DEPLOYDIR}/devicetree"
#    fi
}
