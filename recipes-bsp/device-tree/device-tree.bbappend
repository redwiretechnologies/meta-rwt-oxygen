FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
COMPATIBLE_MACHINE = "oxygen"

SRC_URI:append = " \
        file://oxygen-pcw.dtsi \
        file://oxygen.dts \
        file://usb-host.dts \
        file://usb-peripheral.dts \
        file://hppersonality.dts \
"

FILES:${PN} +=  " /lib/firmware/rwt/*.dtbo "

do_install:append() {
    for DTB_FILE in `ls *.dtbo`; do
        install -Dm 0644 ${B}/${DTB_FILE} ${D}/lib/firmware/rwt/${DTB_FILE}
    done
}

do_deploy:append() {
    install -Dm 0633 ${B}/oxygen.dtb ${DEPLOYDIR}/oxygen.dtb
    for DTB_FILE in `ls *.dtbo`; do
      install -Dm 0633 ${B}/${DTB_FILE} ${DEPLOYDIR}/lib/firmware/rwt/${DTB_FILE}
    done
}


FPGA_MNGR_RECONFIG_ENABLE = "1"
# common zynq include
#SRC_URI_append_zynq = " file://zynq-7000-qspi-dummy.dtsi"

# device tree sources for the various machines
COMPATIBLE_MACHINE = "oxygen"
DTC_FLAGS:append = " -@"

