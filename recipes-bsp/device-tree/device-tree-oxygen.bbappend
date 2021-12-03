inherit deploy

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

COMPATIBLE_MACHINE = "oxygen"

SRC_URI = " \
        file://oxygen-pcw.dtsi \
        file://oxygen.dts \
        file://usb-host.dts \
        file://usb-peripheral.dts \
"

FILES_${PN} +=  " /lib/firmware/rwt/*.dtbo "

do_install_append() {
    for DTB_FILE in `ls *.dtbo`; do
        install -Dm 0644 ${B}/${DTB_FILE} ${D}/lib/firmware/rwt/${DTB_FILE}
    done
}

do_deploy_append() {
    install -Dm 0633 ${B}/oxygen.dtb ${DEPLOYDIR}/oxygen.dtb
}
