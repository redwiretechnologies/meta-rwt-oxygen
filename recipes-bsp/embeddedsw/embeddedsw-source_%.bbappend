FILESEXTRAPATHS:prepend := "${THISDIR}/embeddedsw-source:"
FILESEXTRAPATHS:prepend := "${THISDIR}/fsbl-firmware:"

#mki: this override only works if meta-user layer has higher priority than meta-xilinx-tools
SRC_URI += " file://0001-te-install-general-hooks-zynqmp.patch \
             file://git/lib/sw_apps/zynqmp_fsbl/src \
             file://0001-moving-shutdown-to-power-on-MI032.patch "

#SRC_URI += "file://0001-moving-shutdown-to-power-on-MI032.patch "




