inherit deploy

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

COMPATIBLE_MACHINE = "oxygen"

SRC_URI:append = " \
        file://oxygen-pcw.dtsi \
        file://oxygen.dts \
        file://usb-host.dts \
        file://usb-peripheral.dts \
        file://Bismuth-1_0-0.dts \
        file://Bismuth-2_0-0.dts \
        file://Selenium-1_0-0.dts \
        file://Tellurium-1_0-0.dts \
        file://Argon-1_0-0.dts \
"
INSANE_SKIP:${PN} ="installed-vs-shipped"
FILES:${PN} +=  " ${libdir}/firmware/rwt/*.dtbo "

DTB_FILE_NAME = "oxygen.dtb"
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
