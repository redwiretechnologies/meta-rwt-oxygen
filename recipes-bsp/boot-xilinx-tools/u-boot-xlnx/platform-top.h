#ifndef PLATFORM_TOP_H
#define PLATFORM_TOP_H

#define CONFIG_EXTRA_ENV_SETTINGS               \
    "sdbootdev=1\0" \
    "kernel_load_address=0x80000\0" \
    "devicetree_load_address=0x4000000\0" \
    "bitfile_load_address=0x4000000\0" \
    "machine_name=oxygen\0" \
    "uenvcmd=run bootkernel\0" \
    "devicetree_image=oxygen.dtb\0" \
    "kernel_image=image\0" \
    "bootargs=earlycon clk_ignore_unused root=/dev/mmcblk1p2 rw rootwait\0" \
    "append_fpgadev=env set bootargs ${bootargs} fpgadev=${fpgadev}\0" \
    "loadkernel=fatload mmc 1 ${kernel_load_address} ${kernel_image}\0" \
    "loaddtb=fatload mmc 1 ${devicetree_load_address} ${devicetree_image}\0" \
    "loadbitfile=fatload mmc 1 ${bitfile_load_address} download.${fpgadev}.bin && fpga load 0 ${bitfile_load_address} $filesize\0" \
    "sdboot=run append_fpgadev && run loadbitfile && run loadkernel && run loaddtb && booti ${kernel_load_address} - ${devicetree_load_address}\0" \
    "modeboot=sdboot\0"

#include <configs/xilinx_zynqmp.h>


#endif /* PLATFORM_TOP_H */
