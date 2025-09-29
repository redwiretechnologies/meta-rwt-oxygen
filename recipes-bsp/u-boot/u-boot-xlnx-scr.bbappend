FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot-xlnx-scr:"
SRC_URI += " file://boot.cmd.sd.oxygen \
           "

BOOTMODE = "sd"
BOOTFILE_EXT = ".oxygen"
COMPATIBLE_MACHINE = "oxygen"
KERNEL_BOOTCMD:oxygen ?= "booti"
