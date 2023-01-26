FPGA_MNGR_RECONFIG_ENABLE = '1'
# specify BIF common attribute for FSBL
BIF_COMMON_ATTR = ""
BIF_DEVICETREE_ATTR = "device-tree-oxygen"
# specify BIF partition attributes required for BOOT.bin
BIF_PARTITION_ATTR:zynqmp = "fsbl pmufw arm-trusted-firmware u-boot-xlnx"

# specify BIF partition attributes for FSBL
# bootloader is FSBL. Location where FSBL binary is present and dependency to build FSBL
BIF_PARTITION_ATTR[fsbl] = "bootloader, destination_cpu=a53-0"
BIF_PARTITION_IMAGE[fsbl] = "${DEPLOY_DIR_IMAGE}/fsbl-${MACHINE}.elf"
BIF_PARTITION_DEPENDS[fsbl] = "virtual/fsbl:do_deploy"

# specify BIF partition attributes for PMU Firmware
# destination cpu for PMU. Location where PMU binary is present and dependency to build PMU Firmware
BIF_PARTITION_ATTR[pmufw] = "destination_cpu=pmu"
BIF_PARTITION_IMAGE[pmufw] = "${DEPLOY_DIR_IMAGE}/pmu-firmware-${MACHINE}.elf"
BIF_PARTITION_DEPENDS[pmufw] = "virtual/pmu-firmware:do_deploy"

# specify BIF partition attributes for ATF
# destination cpu for ATF, security levels. Location where ATF binary is present (dependency is not required as ATF is always built for ZU+, see zcu102-zynqmp.conf)
#BIF_PARTITION_ATTR[atf] = "destination_cpu=a53-0,exception_level=el-3,trustzone"
#BIF_PARTITION_IMAGE[atf] = "${DEPLOY_DIR_IMAGE}/arm-trusted-firmware.elf"
#BIF_PARTITION_DEPENDS[atf] = "arm-trusted-firmware:do_deploy"
BIF_PARTITION_ATTR[arm-trusted-firmware] ?= "destination_cpu=a53-0,exception_level=el-3,trustzone"
BIF_PARTITION_IMAGE[arm-trusted-firmware] ?= "${RECIPE_SYSROOT}/boot/arm-trusted-firmware.elf"

# specify BIF partition attributes for u-boot
# destination cpu for u-boot, security levels. Location where u-boot binary is present (dependency is not required as u-boot is always built for ZU+, see zcu102-zynqmp.conf)
BIF_PARTITION_ATTR[u-boot-xlnx] = "destination_cpu=a53-0,exception_level=el-2"
BIF_PARTITION_IMAGE[u-boot-xlnx] = "${DEPLOY_DIR_IMAGE}/u-boot-${MACHINE}.elf"
BIF_PARTITION_DEPENDS[u-boot-xlnx] = "virtual/bootloader:do_deploy"
