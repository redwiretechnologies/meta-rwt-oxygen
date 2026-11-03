SUMMARY = "exmaple files for tunning oxygen and gnuradio"
HOMEPAGE = "https://github.com/redwiretechnologies"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"


DEPENDS = "python3"
RDEPNDS = "gnuradio"
SRC_URI = " file://rwt_fm_radio.grc \
            file://adsb_rx_rwt.grc \
            file://led_blink.py \
"


do_install() {
       install -d ${D}/home/root/examples
       install -m 0755 ${UNPACKDIR}/rwt_fm_radio.grc ${D}/home/root/examples
       install -m 0755 ${UNPACKDIR}/adsb_rx_rwt.grc ${D}/home/root/examples
       install -m 0755 ${UNPACKDIR}/led_blink.py ${D}/home/root/examples
}
FILES:${PN} = "/home/root/examples/* "
