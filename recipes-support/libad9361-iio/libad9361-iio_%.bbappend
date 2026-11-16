# meta-adi-xilinx builds the libad9361-iio-v0 branch, which only supports libiio v0.
# RWT uses libiio v1.0, so build the main branch (v0.4), which supports libiio v1.
BRANCH = "main"

# Pinned for reproducible builds (tip of main, 2026-11-13).
SRCREV = "7d8e7cadd07636cafb7a87d6bcdcc4dd4fcca9b3"
PV = "0.4"
