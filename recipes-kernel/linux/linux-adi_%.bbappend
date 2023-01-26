FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRCREV = "${@ "cbdcc4022a5e9ff947533f0dc3542ff06cb5817d" if bb.utils.to_boolean(d.getVar('BB_NO_NETWORK')) else d.getVar('AUTOREV')}"

