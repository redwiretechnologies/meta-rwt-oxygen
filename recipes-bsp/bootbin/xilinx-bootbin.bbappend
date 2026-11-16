include machine-xilinx-zynqmp-oxygen.inc

# Upstream hardcodes 'device-tree' here, but this machine uses device-tree-oxygen
# (PREFERRED_PROVIDER_virtual/dtb), so depend on the virtual instead.
MANIFEST_AGGREGATE_DEPENDS:zynqmp = "virtual/dtb virtual/bootloader fsbl pmufw virtual/arm-trusted-firmware"
