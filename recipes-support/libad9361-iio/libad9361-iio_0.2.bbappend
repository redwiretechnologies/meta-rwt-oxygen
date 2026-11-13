SUMMARY = "Library to manage multi-chip sync on FMCOMMS5 platforms with multiple AD9361 devices"
LIC_FILES_CHKSUM = "file://LICENSE;md5=40d2542b8c43a3ec2b7f5da31a697b88"
BRANCH = "main"

# If we are in an offline build we cannot use AUTOREV since it would require internet!
SRCREV = "${@ "7d8e7cadd07636cafb7a87d6bcdcc4dd4fcca9b3" if bb.utils.to_boolean(d.getVar('BB_NO_NETWORK')) else d.getVar('AUTOREV')}"
PV:append = "+git${SRCPV}"

SRC_URI = "git://github.com/analogdevicesinc/libad9361-iio.git;protocol=https;branch=${BRANCH}"


DEPENDS += "libiio python3-libiio"

inherit cmake pkgconfig
