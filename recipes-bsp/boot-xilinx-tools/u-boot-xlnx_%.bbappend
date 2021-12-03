FILESEXTRAPATHS_prepend := "${THISDIR}/u-boot-xlnx:"

COMPATIBLE_MACHINE = "oxygen"

do_configure[depends] += "device-tree-oxygen:do_deploy"

UBOOT_MAKE_TARGET_append = " EXT_DTB=${DEPLOY_DIR_IMAGE}/oxygen.dtb"


do_configure_append () {
	install ${WORKDIR}/platform-top.h ${S}/include/configs/
    install ${WORKDIR}/config.cfg ${S}/configs/${UBOOT_MACHINE}
}

SRC_URI += "\
     file://0001-zynqmp-Adding-environment-variable-for-device-type.patch \
     file://config.cfg \
     file://platform-top.h \
     "
