inherit deploy

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

COMPATIBLE_MACHINE = "oxygen"

SRC_URI:append = " \
        file://oxygen-pcw.dtsi \
        file://oxygen.dts \
        file://usb-host.dts \
        file://usb-peripheral.dts \
        file://hppersonality.dts \
"
INSANE_SKIP:${PN} ="installed-vs-shipped"
FILES:${PN} +=  " ${libdir}/firmware/rwt/*.dtbo "

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
}
