
INHIBIT_DEFAULT_DEPS = "1"
DEPENDS += "dtc-native unzip-native device-tree-oxygen"

COMPATIBLE_MACHINE ?= "oxygen"
PACKAGE_ARCH = "${MACHINE_ARCH}"

#XSCTH_SCRIPT = "${WORKDIR}/multipleHDF.tcl"
#XSCTH_BUILD_CONFIG ?= 'Release'

#inherit deploy xsctbase xsctyaml

FILES:${PN} = " \
    /lib/firmware/rwt/${PERSONALITY}/overlay.dtbo \
    /lib/firmware/rwt/${PERSONALITY}/*/download.bin"

FILESEXTRAPATHS:prepend := "${THISDIR}/bitfiles:"

S = "${WORKDIR}"
B = "${WORKDIR}/build"

SRC_URI:append := " \
    file://bootgen.bif \
    file://oxygen-transceiver-i2c.dtsi \
    file://oxygen-transceiver-spi.dtsi \
    "
YAML_OVERLAY_CUSTOM_DTS = "pl-final.dts"
DTS_FILES_PATH ?= "${S}"
DTS_INCLUDE ?= "${DTS_FILES_PATH}"
DT_PADDING_SIZE ?= "0x1000"
#DEVICETREE_FLAGS ?= " 
#  -R 8 -p ${DT_PADDING_SIZE} -b 0 
#    ${@' '.join(['-i %s' % i for i in d.getVar('DTS_INCLUDE', True).split()])} 
#               "
#DEVICETREE_OFLAGS ?= "-@ -H epapr"
#DEVICETREE_PP_FLAGS ?= " 
#   -nostdinc -Ulinux -x assembler-with-cpp 
#   ${@' '.join(['-I%s' % i for i in d.getVar('DTS_INCLUDE', True).split()])} 
#    "

DEVICETREE_FLAGS ?= " \
                 -R 8 -p ${DT_PADDING_SIZE} -b 0 -@ -H epapr \
                 ${@' '.join(['-i %s' % i for i in d.getVar('DTS_INCLUDE').split()])} \
                 "
DEVICETREE_PP_FLAGS ?= " \
                 -nostdinc -Ulinux -x assembler-with-cpp \
                 ${@' '.join(['-I%s' % i for i in d.getVar('DTS_INCLUDE').split()])} \
                 "



do_compile() {
    DTS_NAME=`basename -s .dts ${DTS_FILE}`
    #${BUILD_CPP} ${DEVICETREE_PP_FLAGS} -o ${DTS_NAME}.pp ${DTS_FILES_PATH}/${DTS_FILE}
    #dtc ${DEVICETREE_OFLAGS} -I dts -O dtb ${DEVICETREE_FLAGS} -o overlay.dtbo 
    #dtc  ${DEVICETREE_OFLAGS} -I dts -O dtb -@ ${DEVICETREE_FLAGS} -o overlay.dtbo ${DTS_NAME}.pp
    ${BUILD_CPP} ${DEVICETREE_PP_FLAGS} -o ${DTS_NAME}.pp ${DTS_FILES_PATH}/${DTS_FILE}
    dtc ${DEVICETREE_FLAGS} -I dts -O dtb -o overlay.dtbo ${DTS_NAME}.pp
    
    
    all_xsas=${S}/*/system.xsa
    for xsa in ${all_xsas}; do
        bitfile=$(unzip -l ${xsa} | awk '{print $NF}' | grep ".bit$")
        device=$(dirname ${xsa} | xargs -n1 basename)

        unzip -o ${xsa} ${bitfile} -d ${B}/${device}/
        mv ${B}/${device}/${bitfile} ${B}/${device}/download.bit

        (cd ${B}/${device} && ${XILINX_SDK_TOOLCHAIN}/bin/bootgen -image ${S}/bootgen.bif -arch zynqmp -w -o download.bin)
    done
}

do_install() {
    install -d ${D}/lib/firmware/rwt/${PERSONALITY}
    install -Dm 0644 ${B}/overlay.dtbo ${D}/lib/firmware/rwt/${PERSONALITY}/

    all_bitfiles=${B}/*/download.bin
    for bf in ${all_bitfiles}; do
        device=$(dirname ${bf} | xargs -n1 basename)
        install -d ${D}/lib/firmware/rwt/${PERSONALITY}/${device}/
        install -Dm 0644 ${bf} ${D}/lib/firmware/rwt/${PERSONALITY}/${device}/
    done
}
